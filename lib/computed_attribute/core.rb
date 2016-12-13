require 'active_support'

module ComputedAttribute
  module Core
    extend ActiveSupport::Concern

    included do
      self.processed = false
      self.model = Model.new(self, computed_attributes)
      TracePoint.trace(:end) { set_up }
    end

    module ClassMethods
      attr_accessor :computed_attributes, :processed, :model

      def computed_attribute(attribute, options = {})
        options[:model] = model
        return if computed_attributes.map(&:attribute).include?(attribute)
        (computed_attributes << Attribute.new(attribute, options)).uniq!
      end

      def computed_attributes
        @computed_attributes ||= []
      end

      private

      def set_up
        return if computed_attributes.empty? || processed

        model.set_up
        self.processed = true
      end
    end

    class Model
      attr_reader :klass, :attributes, :associations

      def initialize(klass, attributes)
        @klass = klass
        @attributes = attributes
      end

      def associations
        @associations ||= klass.reflect_on_all_associations.sort_by(&:name)
      end

      def set_up
        model_name = klass.name.demodulize.underscore

        klass = @klass
        p "#{klass}: set up #{model_name}"

        klass.after_create do |host|
          p "#{klass}: host #{model_name} created"
          host.recompute(:all)
        end

        attributes.each(&:set_up)
      end
    end

    class Attribute
      attr_reader :attribute, :dependencies, :model, :reflection

      def initialize(attribute, options = {})
        @attribute = attribute
        @dependencies = options[:depends]
        @model = options[:model]
      end

      def model_klass
        model.klass
      end

      def model_associations
        model.associations
      end

      def set_up
        computed_method_name = "computed_#{attribute}"
        unless model_klass.instance_methods.include?(computed_method_name.to_sym)
          raise NoMethodError, "Assigned computed attribute #{attribute}, "\
            "but no method called `#{computed_method_name}` found"
        end

        return unless dependencies.present?
        Array(dependencies).each do |dep|
          association = model_associations.find { |assoc| assoc.name == dep }
          raise "Association #{dep} not found" if association.nil?
          klass = model_klass
          p "#{klass}: wiring up association #{dep}: #{association}"

          @reflection =
            case association
            when ActiveRecord::Reflection::BelongsToReflection
              BelongsToReflection.new(attribute: attribute, host: klass, association: association).set_up
            when ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::HasOneReflection
              HasReflection.new(attribute: attribute, host: klass, association: association).set_up
            when ActiveRecord::Reflection::ThroughReflection
              ThroughReflection.new(attribute: attribute, host: klass, association: association).set_up
            end
        end
      end

      def recompute_on(record)
        update_options = {}
        value = record.send("computed_#{attribute}")
        update_options[attribute] = value
        record.update_columns(update_options)
        p "#{self.class.name}: updated #{attribute}: #{value}"
      end
    end

    class Reflection
      attr_reader :association, :host, :attribute

      def initialize(options)
        @association  = options[:association]
        @host         = options[:host]
        @attribute    = options[:attribute]
      end

      def opposite_class
        association.klass
      end

      def opposite_association
        opposite_class.reflect_on_all_associations.find do |association|
          association.klass == host
        end
      end

      def opposite_name
        opposite_association.name
      end
    end

    class ThroughReflection < Reflection
      def through_association
        association.through_reflection
      end

      def opposite_class
        through_association.klass
      end

      def set_up
        grandchild_class = association.klass
        child_class = association.through_reflection.klass
        p "#{host} (through): add child callbacks: #{child_class} -> #{grandchild_class}"

        cb = proc do |klass, host_name, attribute|
          proc do
            p "#{klass}: child #{self.class} saved (host: #{host_name})"
            host = send(host_name)
            host.reload.recompute(attribute) if host.present?
          end
        end

        opposite_class.after_save(cb.call(host, opposite_name, attribute))
        opposite_class.after_destroy(cb.call(host, opposite_name, attribute))
      end
    end

    class HasReflection < Reflection
      def set_up
        p "#{host} (has_many): add child callbacks: #{opposite_class.name}"

        cb = proc do |klass, host_name, attribute|
          proc do
            p "#{klass}: child #{self.class} saved (host: #{host_name})"
            host = send(host_name)
            host.reload.recompute(attribute) if host.present?
          end
        end

        opposite_class.after_save(cb.call(host, opposite_name, attribute))
        opposite_class.after_destroy(cb.call(host, opposite_name, attribute))
      end
    end

    class BelongsToReflection < Reflection
      def set_up
        parent_class = association.klass
        p "#{host}: (belongs_to) add host callbacks: #{parent_class.name}"

        cb = proc do |klass, host_name, attribute|
          proc do
            p "#{klass}: parent #{self.class} saved (host: #{host_name})"
            host = Array((destroyed? ? self : reload).send(host_name))
            Array(host).each do |record|
              record.reload.recompute(attribute)
            end
          end
        end
        opposite_class.after_save(cb.call(host, opposite_name, attribute))
        opposite_class.after_destroy(cb.call(host, opposite_name, attribute))
      end
    end

    def recompute(*attributes)
      p "#{self.class.name}: recompute: #{attributes}"
      computed_attributes = self.class.computed_attributes
      attributes_to_compute =
        if attributes == [:all]
          computed_attributes
        else
          attributes.map do |attr|
            self.class.computed_attributes.find { |computed| computed.attribute == attr }
          end
        end
      attributes_to_compute.each { |attribute| attribute.recompute_on(self) }
    end
  end
end
