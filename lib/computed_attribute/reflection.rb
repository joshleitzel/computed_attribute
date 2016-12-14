module ComputedAttribute
  class Reflection
    attr_reader :association, :opposite_association, :host, :attribute

    delegate :name, to: :association

    def initialize(options)
      @association  = options[:association]
      @host         = options[:host]
      @attribute    = options[:attribute]

      @opposite_association =
        if polymorphic?
          nil
        elsif polymorphic_id.present?
          opposite_class.reflect_on_all_associations.find do |association|
            association.name == polymorphic_id
          end
        else
          opposite_class.reflect_on_all_associations.find do |association|
            association.klass == host
          end
        end
    end

    def opposite_class
      association.klass
    end

    def opposite_name
      opposite_association.name
    end

    def polymorphic_id
      association.options[:as]
    end

    def polymorphic?
      association.options[:polymorphic]
    end
  end
end
