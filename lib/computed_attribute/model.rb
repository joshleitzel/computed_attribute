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
end
