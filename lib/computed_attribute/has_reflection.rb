require 'computed_attribute/reflection'

module ComputedAttribute
  class HasReflection < Reflection
    def set_up
      Log.log("#{host} (has): add child callbacks: #{opposite_class.name}")

      cb = proc do |klass, host_name, attribute|
        proc do
          Log.log("#{klass}: child #{self.class} saved (host: #{host_name}, attribute: #{attribute})")
          host = send(host_name)
          host.reload.recompute(attribute) if host.present?
        end
      end

      opposite_class.after_save(cb.call(host, opposite_name, attribute))
      opposite_class.after_destroy(cb.call(host, opposite_name, attribute))

      if polymorphic_id.present?
        cb = proc do |_host, association_name, polymorphic_id, _attribute|
          proc do
            ass = send(association_name)
            if ass.present?
              Array(ass).each { |a| a.recompute(:all, uses: polymorphic_id) }
            end
          end
        end
        host.after_save(cb.call(host, association.name, polymorphic_id, attribute))
        host.after_destroy(cb.call(host, association.name, polymorphic_id, attribute))
      end

      self
    end
  end
end
