require 'computed_attribute/reflection'

module ComputedAttribute
  class HasReflection < Reflection
    def set_up
      p "#{host} (has_many): add child callbacks: #{opposite_class.name}"

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
