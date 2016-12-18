require 'active_support'
require 'computed_attribute/model'
require 'computed_attribute/log'

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

    def recompute(*attributes)
      options = attributes.last.is_a?(Hash) ? attributes.pop : {}

      Log.log("#{self.class.name}: recompute: #{attributes}")

      computed_attributes = self.class.computed_attributes
      attributes_to_compute =
        if attributes == [:all]
          computed_attributes
        else
          attributes.map do |attr|
            self.class.computed_attributes.find { |computed| computed.attribute == attr }
          end
        end

      # TODO: using `compact` here b/c there's a situation with polymorphic associations
      # hooking onto someone else's association. Should diagnose/fix the real problem
      # instead of this hack.
      attributes_to_compute = attributes_to_compute.compact
      if options[:uses].present?
        attributes_to_compute = attributes_to_compute.select { |attribute| attribute.uses?(options[:uses]) }
      end
      attributes_to_compute.compact.each { |attribute| attribute.recompute_on(self) }
    end
  end
end
