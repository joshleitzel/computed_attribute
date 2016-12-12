require 'active_support'

module ComputedAttribute
  module Core
    extend ActiveSupport::Concern

    included do
      self.computed_attributes = []
      self.processed = false

      TracePoint.trace(:end) { set_up }
    end

    module ClassMethods
      attr_accessor :computed_attributes, :processed

      def computed_attribute(*options)
        (computed_attributes << options).uniq!
      end

      private

      def set_up
        return if computed_attributes.empty? || processed

        klass = self
        host_associations = reflect_on_all_associations.sort_by(&:name)
        model_name = name.demodulize.underscore

        p "#{klass}: set up #{model_name}"

        p host_associations.map(&:type)
        klass.after_create do |host|
          p "#{klass}: host #{model_name} created"
          host.recompute(:all)
        end

        computed_attributes.each do |attribute, options|
          computed_method_name = "computed_#{attribute}"
          unless klass.instance_methods.include?(computed_method_name.to_sym)
            raise NoMethodError, "Assigned computed attribute #{attribute}, "\
              "but no method called `#{computed_method_name}` found"
          end

          dependencies = *options[:depends]
          next unless dependencies.present?
          dependencies.each do |dep|
            dep_association = host_associations.find { |assoc| assoc.name == dep }
            raise "Association #{dep} not found" if dep_association.nil?
            p "#{klass}: wiring up association #{dep}: #{dep_association}"

            if dep_association.belongs_to?
              parent_class = dep_association.klass
              p "#{klass}: add host callbacks: #{parent_class.name}"

              parent_class.after_save do
                # p dep_association
                p "#{klass}: first try host is #{model_name}"
                host_name = if dep_association.inverse_of.present?
                              p 'inverse!'
                              plural = dep_association.inverse_of.plural_name
                              respond_to?(plural) ? plural : plural.singularize
                            else
                              respond_to?(model_name) ? model_name : model_name.pluralize
                            end
                host_name = respond_to?(host_name) ? host_name : host_name.pluralize
                p "#{klass}: parent #{self.class} saved (host: #{model_name})"
                if respond_to?(host_name)
                  host = Array(reload.send(host_name))
                  Array(host).each do |record|
                    record.reload.recompute(attribute)
                  end
                end
              end

              parent_class.after_destroy do
                host_name = respond_to?(model_name) ? model_name : model_name.pluralize
                p "#{klass}: parent #{self.class} destroyed (host: #{model_name})"
                host = Array(send(host_name))
                Array(host).each do |record|
                  record.reload.recompute(attribute)
                end
              end
            else
              child_class = dep_association.klass
              p "#{klass}: add child callbacks: #{child_class.name}"

              child_class.after_save do
                host_name = if dep_association.inverse_of.present?
                              dep_association.inverse_of.plural_name
                            else
                              respond_to?(model_name) ? model_name : model_name.pluralize
                            end
                host_name = host_name.singularize unless respond_to?(host_name)
                p "#{klass}: child #{self.class} saved (host: #{host_name})"

                if respond_to?(host_name)
                  host = send(host_name)
                  host.reload.recompute(attribute) if host.present?
                end
              end

              child_class.after_destroy do
                p "#{klass}: child #{self.class} destroyed (host: #{model_name})"
                host = send(model_name)
                host.recompute(attribute) if host.present?
              end
            end
          end
        end

        self.processed = true
      end
    end

    def recompute(*attributes)
      p "recompute: #{attributes}"
      if attributes.count == 1
        attribute = attributes.first
        if attribute == :all
          recompute(*self.class.computed_attributes.map(&:first))
        else
          update_options = {}
          value = send("computed_#{attribute}")
          update_options[attribute] = value
          update_columns(update_options)
          p "updated #{attribute}: #{value}"
        end
      else
        attributes.each { |attr| recompute(attr) }
      end
    end
  end
end
