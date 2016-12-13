require 'computed_attribute/reflection'

module ComputedAttribute
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
end
