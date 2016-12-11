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
        p 'set_up'

        klass = self

        parent_associations = reflect_on_all_associations.sort_by(&:name)
        parent_name = name.demodulize.underscore

        p 'add parent create callback'
        klass.after_create do |parent|
          p "parent: #{parent_name} created"
          parent.recompute(:all)
        end

        computed_attributes.each do |attribute, options|
          computed_method_name = "computed_#{attribute}"
          unless klass.instance_methods.include?(computed_method_name.to_sym)
            raise NoMethodError, "Assigned computed attribute #{attribute}, but no method called `#{computed_method_name}` found"
          end

          dependencies = *options[:depends]
          if dependencies.present?
            dependencies.each do |dep|
              p 'dep'
              dep_association = parent_associations.find { |assoc| assoc.name == dep }
              raise "Association #{dep} not found" if dep_association.nil?

              p "add child callbacks: #{dep_association.klass.name}"

              dep_association.klass.after_save do
                p "child #{self.class} saved (parent: #{parent_name})"
                parent = send(parent_name)
                if parent.present?
                  parent.reload.recompute(attribute)
                end
              end

              dep_association.klass.after_destroy do
                p "child #{self.class} destroyed (parent: #{parent_name})"
                parent = send(parent_name)
                if parent.present?
                  parent.recompute(attribute)
                end
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
          updated = update_columns(update_options)
          p "updated #{attribute}: #{value}"
        end
      else
        attributes.each { |attribute| recompute(attribute) }
      end
    end
  end
end
