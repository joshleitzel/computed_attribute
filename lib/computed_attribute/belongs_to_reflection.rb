require 'computed_attribute/reflection'

module ComputedAttribute
  class BelongsToReflection < Reflection
    def set_up
      parent_class = association.klass
      p "#{host}: (belongs_to) add host callbacks: #{parent_class.name}"

      cb = proc do |klass, host_name, attribute|
        proc do
          p "#{klass}: parent #{self.class} saved (host: #{host_name})"
          host = Array((destroyed? ? self : reload).send(host_name))
          Array(host).each do |record|
            record.reload.recompute(attribute)
          end
        end
      end
      opposite_class.after_save(cb.call(host, opposite_name, attribute))
      opposite_class.after_destroy(cb.call(host, opposite_name, attribute))
    end
  end
end
