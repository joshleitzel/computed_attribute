require 'spec_helper'

describe ComputedAttribute::Attribute do
  describe '.new' do
    it 'does not allow an attribute named :all' do
      expect do
        described_class.new(:all)
      end.to raise_error(
        ComputedAttribute::Errors::InvalidAttributeError,
        ':all is a reserved word and cannot be used as an attribute name'
      )
    end
  end
end
