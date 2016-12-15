module ComputedAttribute
  class Attribute
    attr_reader :attribute, :dependencies, :deps, :model, :reflection

    def initialize(attribute, options = {})
      if attribute == :all
        raise Errors::InvalidAttributeError, ':all is a reserved word and cannot be used as an attribute name'
      end

      @attribute = attribute
      @dependencies = Array(options[:depends])
      @model = options[:model]
    end

    def model_klass
      model.klass
    end

    def model_associations
      model.associations
    end

    def set_up
      p "Wiring up attribute #{attribute}..."
      computed_method_name = "computed_#{attribute}"
      unless model_klass.instance_methods.include?(computed_method_name.to_sym)
        raise NoMethodError, "Assigned computed attribute `#{attribute}`, "\
          "but no method called `#{computed_method_name}` found"
      end

      return unless dependencies.present?

      @deps = dependencies.map do |dep|
        association = model_associations.find { |assoc| assoc.name == dep }
        raise "Association #{dep} not found" if association.nil?
        klass = model_klass
        p "#{klass}: wiring up association #{dep}: #{association}"

        case association
        when ActiveRecord::Reflection::BelongsToReflection
          BelongsToReflection.new(attribute: attribute, host: klass, association: association).set_up
        when ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::HasOneReflection
          HasReflection.new(attribute: attribute, host: klass, association: association).set_up
        when ActiveRecord::Reflection::ThroughReflection
          ThroughReflection.new(attribute: attribute, host: klass, association: association).set_up
        when ActiveRecord::Reflection::HasAndBelongsToManyReflection
          HasAndBelongsToManyReflection.new(attribute: attribute, host: klass, association: association).set_up
        else
          raise NotImplementedError, "Don't know what to do with #{association.class}"
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

    def depends?(association_name)
      dependencies.include?(association_name)
    end
  end
end
