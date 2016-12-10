ActiveRecord::Base.class_eval do
  class << self
    def computed_attribute(attribute, options)
      parent_associations = reflect_on_all_associations.sort_by(&:name)
      parent_name = name.demodulize.underscore

      #raise "Assigned computed attribute #{attribute}, but no method called `#{attribute}` found" unless respond_to?(attribute)

      self.class_eval do
        alias_method "_compute_cache_#{attribute}".to_sym, attribute

        define_method(attribute) do
          self[attribute]
        end
      end

      dependencies = *options[:depends]
      if dependencies.present?
        dependencies.each do |dep|
          dep_association = parent_associations.find { |assoc| assoc.name == dep }
          raise "Association #{dep} not found" if dep_association.nil?

          dep_association.klass.class_eval do
            after_save do
              parent = send(parent_name)
              if parent.present?
                parent.recompute(attribute)
              end
            end
          end
        end
      end
    end

    #alias_method :computed_attribute, :computed_attributes
  end

  def recompute(attribute)
    update_options = {}
    update_options[attribute] = send("_compute_cache_#{attribute}")
    updated = update_columns(update_options)
    byebug
  end
end
