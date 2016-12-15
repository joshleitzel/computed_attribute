module ComputedAttribute
  class AttributeDependency
    attr_reader :dependent_attribute, :host, :attribute

    def initialize(options)
      @dependent_attribute  = options[:dependent_attribute]
      @host                 = options[:host]
      @attribute            = options[:attribute]
    end

    def set_up
      p "#{host}: (attribute) add host callbacks: #{dependent_attribute}"

      callback = proc do |attribute, dependent_attribute|
        proc do
          recompute(attribute) if send("#{dependent_attribute}_changed?")
        end
      end
      host.after_save(callback.call(attribute, dependent_attribute))

      self
    end
  end
end
