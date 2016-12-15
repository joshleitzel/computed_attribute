module ComputedAttribute
  class Model
    attr_reader :klass, :attributes, :associations

    def initialize(klass, attributes)
      @klass = klass
      @attributes = attributes
    end

    def associations
      @associations ||= klass.reflect_on_all_associations.sort_by(&:name)
    end

    def attribute_names
      klass.column_names.map(&:to_sym)
    end

    def set_up
      model_name = klass.name.demodulize.underscore

      Log.log("#{klass}: set up #{model_name}")

      cb = proc do |klass|
        proc do |host|
          Log.log("#{klass}: host #{model_name} created")
          host.recompute(:all)
        end
      end
      klass.after_create(cb.call(klass))

      attributes.each(&:set_up)
    end
  end
end
