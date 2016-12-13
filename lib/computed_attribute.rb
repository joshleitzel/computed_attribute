Dir[File.dirname(__FILE__) + '/computed_attribute/*.rb'].sort.each { |file| require file }

module ComputedAttribute; end
