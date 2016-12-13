module ComputedAttribute
  class Attribute
    attr_reader :attribute, :dependencies, :model, :reflection

    def initialize(attribute, options = {})
      if attribute == :all
        raise Errors::InvalidAttributeError, ':all is a reserved word and cannot be used as an attribute name'
      end

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
        raise NoMethodError, "Assigned computed attribute `#{attribute}`, "\
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
end
