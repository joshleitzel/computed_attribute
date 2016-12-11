require 'spec_helper'

describe ComputedAttribute do
  it 'has a version number' do
    expect(ComputedAttribute::VERSION).not_to be nil
  end

  describe 'has_many' do
    it 'does not make duplicate recompute calls' do
      galaxy = Galaxy.create
      expect(galaxy).to receive(:recompute).exactly(1).with(:system_count)
      system = galaxy.solar_systems.create
    end

    it 'updates when a child item is saved' do
      galaxy = Galaxy.create
      expect(galaxy.system_count).to eq(0)
      system = galaxy.solar_systems.create
      expect(galaxy.system_count).to eq(1)
    end

    it 'updates when a child item is created' do
      galaxy = Galaxy.create
      expect(galaxy.system_count).to eq(0)
      system = galaxy.solar_systems.create
      expect(galaxy.system_count).to eq(1)
    end

    it 'updates when parent created' do
      galaxy = Galaxy.create(solar_systems: [SolarSystem.new, SolarSystem.new])
      expect(galaxy.system_count).to eq(2)
    end

    it 'updates when a child item is destroyed' do
      system = SolarSystem.create
      galaxy = Galaxy.create(solar_systems: [system])
      expect(galaxy.system_count).to eq(1)
      system.destroy
      expect(galaxy.system_count).to eq(0)
    end
  end

  describe 'belongs_to' do

  end
end
