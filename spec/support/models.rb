class Model < ActiveRecord::Base
  self.abstract_class = true
end

class Galaxy < Model
  include ComputedAttribute::Core
  has_many :solar_systems
  has_many :stars, through: :solar_systems
  has_many :holes, class_name: 'BlackHole'
  has_many :points_of_no_return, through: :holes, source: :event_horizon

  computed_attribute :star_count, depends: :stars
  computed_attribute :red_dwarf_count, depends: :stars
  computed_attribute :solar_system_count, depends: :solar_systems
  computed_attribute :black_hole_count, depends: :holes
  computed_attribute :horizon_count, depends: :points_of_no_return

  def computed_star_count
    stars.count
  end

  def computed_solar_system_count
    solar_systems.count
  end

  def computed_black_hole_count
    holes.count
  end

  def computed_horizon_count
    points_of_no_return.count
  end

  def computed_red_dwarf_count
    stars.where(classification: 'red_dwarf').count
  end
end

class BlackHole < Model
  belongs_to :galaxy
  has_one :event_horizon
end

class EventHorizon < Model
  belongs_to :black_hole
end

class SolarSystem < Model
  include ComputedAttribute::Core
  belongs_to :galaxy
  has_one :star, inverse_of: :system

  computed_attribute :galaxy_name, depends: :galaxy
  computed_attribute :star_classification, depends: :star

  def computed_galaxy_name
    galaxy.try(:name)
  end

  def computed_star_classification
    star.try(:classification)
  end
end

class GravitationalField < Model
  include ComputedAttribute::Core
  belongs_to :gravitational, polymorphic: true

  computed_attribute :emanates_from_planet, depends: :gravitational
  computed_attribute :has_star, depends: :gravitational

  def computed_emanates_from_planet
    gravitational.is_a?(Planet)
  end

  def computed_has_star
    gravitational.try(:gas_ball).present?
  end
end

class Star < Model
  include ComputedAttribute::Core
  belongs_to :system, class_name: 'SolarSystem', inverse_of: :star, foreign_key: 'solar_system_id'
  has_many :rocks, class_name: 'Planet', foreign_key: 'gas_ball_id', inverse_of: :gas_ball
  has_one :gravitational_field, as: :gravitational

  computed_attribute :system_sector, depends: :system
  computed_attribute :gas_giant_count, depends: :rocks
  computed_attribute :gravitational_field_radius, depends: :gravitational_field

  def computed_system_sector
    system.try(:sector)
  end

  def computed_gas_giant_count
    rocks.where(classification: 'gas_giant').count
  end

  def computed_gravitational_field_radius
    gravitational_field.try(:radius)
  end
end

class Thing < Model
  has_and_belongs_to_many :planets
end

class Planet < Model
  include ComputedAttribute::Core
  belongs_to :gas_ball, class_name: 'Star', inverse_of: :rocks
  has_many :moons
  has_one :atmosphere
  has_one :stratosphere, through: :atmosphere
  has_many :gravitational_fields, as: :gravitational
  has_and_belongs_to_many :things

  computed_attribute :star_classification, depends: :gas_ball
  computed_attribute :stratosphere_height, depends: :stratosphere
  computed_attribute :gravitational_field_radius_sum, depends: :gravitational_fields
  computed_attribute :thing_size, depends: :things
  computed_attribute :circumference, save: true
  computed_attribute :diameter, depends: :radius

  def computed_star_classification
    gas_ball.try(:classification)
  end

  def computed_stratosphere_height
    stratosphere.try(:height)
  end

  def computed_gravitational_field_radius_sum
    gravitational_fields.sum(:radius)
  end

  def computed_thing_size
    things.sum(:size)
  end

  def computed_circumference
    return 0 if radius.nil?
    ((radius * 2) * Math::PI).to_i
  end

  def computed_diameter
    return 0 if radius.nil?
    radius * 2
  end
end

class Moon < Model
  belongs_to :planet
  has_one :gravitational_field, as: :gravitational
end

class Atmosphere < Model
  belongs_to :planet
  has_one :stratosphere
end

class Stratosphere < Model
  belongs_to :atmosphere
end
