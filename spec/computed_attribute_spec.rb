require 'spec_helper'

describe ComputedAttribute do
  # before { ComputedAttribute::Log.log_level = :debug }

  it 'has a version number' do
    expect(ComputedAttribute::VERSION).not_to be nil
  end

  describe 'model itself saved' do
    it 'updates when model created and saved' do
      planet = Planet.create(radius: 3958)
      expect(planet.circumference).to eq(24_868)
      planet.update(radius: 4500)
      expect(planet.reload.circumference).to eq(28_274)
    end
  end

  describe 'model depends on attribute' do
    it 'updates when model created and saved' do
      planet = Planet.create(radius: 3958)
      expect(planet.diameter).to eq(7916)
      planet.update(radius: 4500)
      expect(planet.reload.diameter).to eq(9000)
    end

    it 'does not update if the attribute has not changed' do
      planet = Planet.create(radius: 3958)
      expect(planet).to_not receive(:recompute).with(:diameter)
      planet.save
    end
  end

  describe 'has_many' do
    it 'does not make duplicate recompute calls' do
      galaxy = Galaxy.create
      expect(galaxy).to receive(:computed_solar_system_count).exactly(1)
      expect(galaxy).to receive(:computed_star_count).exactly(1)
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

  describe 'has_many :through' do
    it 'updates when child saved' do
      galaxy = Galaxy.create
      expect(galaxy.star_count).to eq(0)
      galaxy.solar_systems.create(star: Star.new)
      expect(galaxy.reload.star_count).to eq(1)
    end

    it 'updates when child created' do
      galaxy = Galaxy.create
      expect(galaxy.star_count).to eq(0)
      galaxy.solar_systems.create(star: Star.new)
      expect(galaxy.star_count).to eq(1)
    end

    it 'updates when parent created' do
      galaxy = Galaxy.create(solar_systems: [SolarSystem.new(star: Star.new), SolarSystem.new])
      expect(galaxy.star_count).to eq(1)
    end

    it 'updates when child destroyed' do
      system = SolarSystem.create(star: Star.new)
      galaxy = Galaxy.create(solar_systems: [system])
      expect(galaxy.star_count).to eq(1)
      system.destroy
      expect(galaxy.reload.star_count).to eq(0)
    end

    it 'updates with custom association name and :source' do
      galaxy = Galaxy.create
      expect(galaxy.horizon_count).to eq(0)
      galaxy.holes.create(event_horizon: EventHorizon.new)
      expect(galaxy.horizon_count).to eq(1)
    end

    it 'updates when grandchild saved' do
      pending
      star = Star.new
      galaxy = Galaxy.create(solar_systems: [SolarSystem.new(star: star)])
      expect(galaxy.red_dwarf_count).to eq(0)
      star.update(classification: 'red_dwarf')
      expect(galaxy.reload.red_dwarf_count).to eq(1)
    end

    it 'updates when grandchild destroyed' do
      pending
      star = Star.new(classification: 'red_dwarf')
      galaxy = Galaxy.create(solar_systems: [SolarSystem.new(star: star)])
      expect(galaxy.red_dwarf_count).to eq(1)
      star.update(classification: 'red_dwarf')
      star.destroy
      expect(galaxy.reload.red_dwarf_count).to eq(0)
    end
  end

  describe 'has_many polymorphic' do
    it 'updates when parent saved' do
      planet = Planet.create(gravitational_fields: [GravitationalField.new(radius: 5), GravitationalField.new(radius: 10)])
      expect(planet.reload.gravitational_field_radius_sum).to eq(15)
    end

    it 'updates when child created' do
      planet = Planet.create
      expect(planet.gravitational_field_radius_sum).to eq(0)
      planet.gravitational_fields.create(radius: 5)
      expect(planet.reload.gravitational_field_radius_sum).to eq(5)
    end

    it 'updates when child saved' do
      gravitational_field = GravitationalField.create
      planet = Planet.create(gravitational_fields: [gravitational_field])
      expect(planet.gravitational_field_radius_sum).to eq(0)
      gravitational_field.update(radius: 5)
      expect(planet.reload.gravitational_field_radius_sum).to eq(5)
    end

    it 'updates when child destroyed' do
      gravitational_field = GravitationalField.create(radius: 5)
      planet = Planet.create(gravitational_fields: [gravitational_field])
      expect(planet.reload.gravitational_field_radius_sum).to eq(5)
      gravitational_field.destroy
      expect(planet.reload.gravitational_field_radius_sum).to eq(0)
    end
  end

  describe 'has_one' do
    it 'updates when parent created' do
      system = SolarSystem.create(star: Star.new(classification: 'red_giant'))
      expect(system.star_classification).to eq('red_giant')
    end

    it 'updates when child created' do
      system = SolarSystem.create
      expect(system.star_classification).to be_nil
      system.create_star(classification: 'red_giant')
      expect(system.reload.star_classification).to eq('red_giant')
    end

    it 'updates when child saved' do
      star = Star.new
      system = SolarSystem.create(star: star)
      expect(system.star_classification).to be_nil
      star.update(classification: 'red_giant')
      expect(system.reload.star_classification).to eq('red_giant')
    end

    it 'updates when child destroyed' do
      star = Star.new(classification: 'red_giant')
      system = SolarSystem.create(star: star)
      expect(system.star_classification).to eq('red_giant')
      star.destroy
      expect(system.reload.star_classification).to be_nil
    end
  end

  describe 'has_one :through' do
    it 'updates when parent created' do
      planet = Planet.create(atmosphere: Atmosphere.new(stratosphere: Stratosphere.new(height: 10)))
      expect(planet.stratosphere_height).to eq(10)
    end

    it 'updates when child created' do
      planet = Planet.create
      planet.create_atmosphere(stratosphere: Stratosphere.new(height: 10))
      expect(planet.stratosphere_height).to eq(10)
    end

    it 'updates when child saved' do
      atmosphere = Atmosphere.create(stratosphere: Stratosphere.new(height: 10))
      planet = Planet.create(atmosphere: atmosphere)
      expect(planet.stratosphere_height).to eq(10)
      atmosphere.update(stratosphere: Stratosphere.new(height: 11))
      expect(planet.stratosphere_height).to eq(11)
    end

    it 'updates when child destroyed' do
      atmosphere = Atmosphere.create(stratosphere: Stratosphere.new(height: 10))
      planet = Planet.create(atmosphere: atmosphere)
      expect(planet.stratosphere_height).to eq(10)
      atmosphere.destroy
      expect(planet.stratosphere_height).to be_nil
    end

    it 'updates when grandchild saved' do
      pending
      stratosphere = Stratosphere.create(height: 10)
      atmosphere = Atmosphere.create(stratosphere: stratosphere)
      planet = Planet.create(atmosphere: atmosphere)
      expect(planet.stratosphere_height).to eq(10)
      stratosphere.update(height: 11)
      expect(planet.reload.stratosphere_height).to eq(11)
    end

    it 'updates when grandchild destroyed' do
      pending
      stratosphere = Stratosphere.create(height: 10)
      atmosphere = Atmosphere.create(stratosphere: stratosphere)
      planet = Planet.create(atmosphere: atmosphere)
      expect(planet.stratosphere_height).to eq(10)
      stratosphere.destroy
      expect(planet.reload.stratosphere_height).to be_nil
    end
  end

  describe 'has_one polymorphic' do
    it 'updates when parent saved' do
      star = Star.create(gravitational_field: GravitationalField.new(radius: 5))
      expect(star.gravitational_field_radius).to eq(5)
    end

    it 'updates when child created' do
      star = Star.create
      expect(star.gravitational_field_radius).to be_nil
      star.create_gravitational_field(radius: 5)
      expect(star.reload.gravitational_field_radius).to eq(5)
    end

    it 'updates when child saved' do
      gravitational_field = GravitationalField.create
      star = Star.create(gravitational_field: gravitational_field)
      expect(star.gravitational_field_radius).to be_nil
      gravitational_field.update(radius: 5)
      expect(star.reload.gravitational_field_radius).to eq(5)
    end

    it 'updates when child destroyed' do
      gravitational_field = GravitationalField.create(radius: 5)
      star = Star.create(gravitational_field: gravitational_field)
      expect(star.reload.gravitational_field_radius).to eq(5)
      gravitational_field.destroy
      expect(star.reload.gravitational_field_radius).to be_nil
    end
  end

  describe 'belongs_to' do
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

  describe 'belongs to polymorphic' do
    it 'updates when parent created' do
      planet = Planet.create
      gravitational_field = GravitationalField.create(gravitational: planet)
      expect(gravitational_field.emanates_from_planet?).to eq(true)
    end

    it 'updates when self saved' do
      planet = Planet.create
      gravitational_field = GravitationalField.create
      gravitational_field.update(gravitational: planet)
      expect(gravitational_field.reload.emanates_from_planet?).to eq(true)
    end

    it 'updates when parent saved' do
      planet = Planet.create(gas_ball: Star.new)
      gravitational_field = GravitationalField.create(gravitational: planet)
      expect(gravitational_field.has_star?).to eq(true)
      planet.update(gas_ball: nil)
      expect(gravitational_field.reload.has_star?).to eq(false)
    end

    it 'updates when parent destroyed' do
      planet = Planet.create(gas_ball: Star.new)
      gravitational_field = GravitationalField.create(gravitational: planet)
      expect(gravitational_field.has_star?).to eq(true)
      planet.destroy
      expect(gravitational_field.reload.has_star?).to eq(false)
    end
  end

  describe 'has_and_belongs_to_many' do
    it 'updates when parent created' do
      planet = Planet.create(things: [Thing.new(size: 3), Thing.new(size: 4)])
      expect(planet.reload.thing_size).to eq(7)
    end

    it 'updates when parent saved' do
      thing = Thing.new(size: 4)
      thing2 = Thing.new(size: 5)
      planet = Planet.create(things: [thing])
      expect(planet.reload.thing_size).to eq(4)
      planet.things << thing2
      expect(planet.reload.thing_size).to eq(9)
    end

    it 'updates when child saved' do
      thing = Thing.new(size: 4)
      planet = Planet.create(things: [thing])
      expect(planet.reload.thing_size).to eq(4)
      thing.update(size: 5)
      expect(planet.reload.thing_size).to eq(5)
    end

    it 'updates when child destroyed' do
      thing = Thing.new(size: 4)
      planet = Planet.create(things: [thing])
      expect(planet.reload.thing_size).to eq(4)
      thing.destroy
      expect(planet.reload.thing_size).to eq(0)
    end
  end
end
