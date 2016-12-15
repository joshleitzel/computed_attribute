require 'computed_attribute/reflection'

module ComputedAttribute
  class BelongsToReflection < Reflection
    def set_up
      Log.log("#{host}: (belongs_to) add host callbacks: #{association.class_name}")

      cb = proc do |klass, host_name, attribute|
        proc do
          Log.log("#{klass}: parent #{self.class} saved (host: #{host_name})")
          host = Array((destroyed? ? self : reload).send(host_name))
          Array(host).each do |record|
            record.reload.recompute(attribute)
          end
        end
      end

      if polymorphic?
        cb = proc do |attribute|
          proc { reload.recompute(attribute) }
        end
        host.after_save(cb.call(attribute))
      else
        opposite_class.after_save(cb.call(host, opposite_name, attribute))
        opposite_class.after_destroy(cb.call(host, opposite_name, attribute))
      end

      self
    end
  end
end
