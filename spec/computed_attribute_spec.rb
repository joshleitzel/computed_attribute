require 'spec_helper'

describe ComputedAttribute do
  it 'has a version number' do
    expect(ComputedAttribute::VERSION).not_to be nil
  end

  describe 'has_many' do
    it 'does not make duplicate recompute calls' do
      galaxy = Galaxy.create
      expect(galaxy).to receive(:recompute).exactly(1).with(:solar_system_count)
      galaxy.solar_systems.create
    end

    it 'updates when a child item is saved' do
      galaxy = Galaxy.create
      expect(galaxy.solar_system_count).to eq(0)
      galaxy.solar_systems.create
      expect(galaxy.solar_system_count).to eq(1)
    end

    it 'updates when a child item is created' do
      galaxy = Galaxy.create
      expect(galaxy.solar_system_count).to eq(0)
      galaxy.solar_systems.create
      expect(galaxy.solar_system_count).to eq(1)
    end

    it 'updates when parent created' do
      galaxy = Galaxy.create(solar_systems: [SolarSystem.new, SolarSystem.new])
      expect(galaxy.solar_system_count).to eq(2)
    end

    it 'updates when a child item is destroyed' do
      system = SolarSystem.create
      galaxy = Galaxy.create(solar_systems: [system])
      expect(galaxy.solar_system_count).to eq(1)
      system.destroy
      expect(galaxy.reload.solar_system_count).to eq(0)
    end

    it 'updates with custom association name' do
      black_hole = BlackHole.create
      galaxy = Galaxy.create(holes: [black_hole])
      expect(galaxy.black_hole_count).to eq(1)
      black_hole.destroy
      expect(galaxy.black_hole_count).to eq(0)
    end

    it 'updates with inverse_of' do
      planet = Planet.create
      star = Star.create(rocks: [planet])
      planet.update(classification: 'gas_giant')
      expect(star.reload.gas_giant_count).to eq(1)
    end
  end

  describe 'belongs_to' do
    it 'does not make duplicate recompute calls' do
      galaxy = Galaxy.create
      expect(galaxy).to receive(:recompute).exactly(1).with(:solar_system_count)
      galaxy.solar_systems.create
    end

    it 'updates when parent saved' do
      galaxy = Galaxy.create
      system = SolarSystem.create(galaxy: galaxy)
      expect(system.galaxy_name).to be_nil
      galaxy.update(name: 'Milky Way')
      expect(system.reload.galaxy_name).to eq('Milky Way')
    end

    it 'updates when parent destroyed' do
      galaxy = Galaxy.create(name: 'Milky Way')
      system = SolarSystem.create(galaxy: galaxy)
      expect(system.galaxy_name).to eq('Milky Way')
      galaxy.destroy
      expect(system.reload.galaxy_name).to be_nil
    end

    it 'updates with custom association name' do
      star = Star.create
      SolarSystem.create(sector: '001', star: star)
      expect(star.reload.system_sector).to eq('001')
    end

    it 'updates with inverse_of' do
      star = Star.create
      planet = Planet.create(gas_ball: star)
      star.update(classification: 'red_dwarf')
      expect(planet.reload.star_classification).to eq('red_dwarf')
    end
  end
end
