module ComputedAttribute
  class Attribute
    attr_reader :attribute, :deps, :options, :reflection

    def initialize(attribute, options = {})
      if attribute == :all
        raise Errors::InvalidAttributeError, ':all is a reserved word and cannot be used as an attribute name'
      end

      @attribute = attribute
      @options = options
    end

    def model_klass
      model.klass
    end

    def model_associations
      model.associations
    end

    def model_attributes
      model.attribute_names
    end

    def model
      options[:model]
    end

    def dependencies
      Array(options[:depends])
    end

    def set_up
      p "Wiring up attribute #{attribute}..."
      computed_method_name = "computed_#{attribute}"
      unless model_klass.instance_methods.include?(computed_method_name.to_sym)
        raise NoMethodError, "Assigned computed attribute `#{attribute}`, "\
          "but no method called `#{computed_method_name}` found"
      end

      if options[:save]
        after_save = proc do |attribute|
          proc { recompute(attribute) }
        end
        model_klass.after_save(after_save.call(attribute))
      end

      @deps = dependencies.map do |dep|
        dependency = model_associations.find { |assoc| assoc.name == dep } || model_attributes.find { |attribute| attribute == dep }
        raise "Association or attribute #{dep} not found" if dependency.nil?
        klass = model_klass
        p "#{klass}: wiring up dependency #{dep}: #{dependency}"

        case dependency
        when ActiveRecord::Reflection::BelongsToReflection
          BelongsToReflection.new(attribute: attribute, host: klass, association: dependency).set_up
        when ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::HasOneReflection
          HasReflection.new(attribute: attribute, host: klass, association: dependency).set_up
        when ActiveRecord::Reflection::ThroughReflection
          ThroughReflection.new(attribute: attribute, host: klass, association: dependency).set_up
        when ActiveRecord::Reflection::HasAndBelongsToManyReflection
          HasAndBelongsToManyReflection.new(attribute: attribute, host: klass, association: dependency).set_up
        when Symbol
          AttributeDependency.new(attribute: attribute, host: klass, dependent_attribute: dependency).set_up
        else
          raise NotImplementedError, "Don't know what to do with #{dependency.class}"
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
