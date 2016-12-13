module ComputedAttribute
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
end
