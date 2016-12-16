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
      Log.log("#{host} (through): add child callbacks: #{child_class} -> #{grandchild_class}")

      cb = proc do |klass, host_name, attribute|
        proc do
          Log.log("#{klass}: child #{self.class} saved (host: #{host_name})")
          host = send(host_name)
          host.reload.recompute(attribute) if host.present?
        end
      end

      opposite_class.after_save(cb.call(host, opposite_name, attribute))
      opposite_class.after_destroy(cb.call(host, opposite_name, attribute))

      inverse = association.through_reflection.inverse_of
      inverse_name = inverse.name

      grandchild_cb = proc do |attribute|
        proc do
          reload unless destroyed?

          reflection = self.class.reflect_on_all_associations.find do |assoc|
            assoc.belongs_to? && assoc.klass == child_class
          end

          reflection_obj = send(reflection.name)
          if reflection_obj.present?
            reflection_obj.reload.send(inverse_name).try(:recompute, attribute)
          end
        end
      end

      grandchild_class.after_save(grandchild_cb.call(attribute))
      grandchild_class.after_destroy(grandchild_cb.call(attribute))

      self
    end
  end
end
