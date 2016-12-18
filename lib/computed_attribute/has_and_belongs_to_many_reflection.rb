require 'computed_attribute/reflection'

module ComputedAttribute
  class HasAndBelongsToManyReflection < Reflection
    def set_up
      Log.log("#{host} (habtm): add child callbacks: #{opposite_class.name}")

      cb = proc do |klass, host_name, attribute, type, cache|
        proc do
          Log.log("#{klass}: child #{self.class} #{type} (host: #{host_name}, attribute: #{attribute})")
          hosts = send(host_name)
          hosts = hosts.present? ? Array(hosts) : cache[host_name]
          hosts.each do |host|
            host.reload.recompute(attribute)
          end
        end
      end

      opposite_class.after_commit(cb.call(host, opposite_name, attribute, 'commit', pre_destroy_cache))
      before_destroy = proc do |host_name, cache|
        proc do
          cache[host_name] = send(host_name).to_a
        end
      end
      opposite_class.before_destroy(before_destroy.call(opposite_name, pre_destroy_cache))
      opposite_class.after_destroy(cb.call(host, opposite_name, attribute, 'destroy', pre_destroy_cache))

      if polymorphic_id.present?
        cb = proc do |association_name, polymorphic_id, _attribute|
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

    def pre_destroy_cache
      @pre_destroy_cache ||= {}
    end
  end
end
