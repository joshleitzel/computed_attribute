class Model < ActiveRecord::Base
  self.abstract_class = true
end

class Galaxy < Model
  include ComputedAttribute::Core
  has_many :solar_systems
  has_many :stars, through: :solar_systems
  has_many :holes, class_name: 'BlackHole'

  computed_attribute :star_count, depends: :stars
  computed_attribute :solar_system_count, depends: :solar_systems
  computed_attribute :black_hole_count, depends: :holes

  def computed_star_count
    stars.count
  end

  def computed_solar_system_count
    solar_systems.count
  end

  def computed_black_hole_count
    holes.count
  end
end

class BlackHole < Model
  belongs_to :galaxy
end

class SolarSystem < Model
  include ComputedAttribute::Core
  belongs_to :galaxy
  has_one :star # I know there are multi-star systems, just need to test a has_one :(

  computed_attribute :galaxy_name, depends: :galaxy

  def computed_galaxy_name
    galaxy.try(:name)
  end
end

class Star < Model
  include ComputedAttribute::Core
  belongs_to :system, class_name: 'SolarSystem', foreign_key: 'solar_system_id'
  has_many :rocks, class_name: 'Planet', foreign_key: 'gas_ball_id', inverse_of: :gas_ball

  computed_attribute :system_sector, depends: :system
  computed_attribute :gas_giant_count, depends: :rocks

  def computed_system_sector
    system.try(:sector)
  end

  def computed_gas_giant_count
    rocks.where(classification: 'gas_giant').count
  end
end

class Planet < Model
  include ComputedAttribute::Core
  belongs_to :gas_ball, class_name: 'Star', inverse_of: :rocks
  has_and_belongs_to_many :neighbors

  computed_attribute :star_classification, depends: :gas_ball

  def computed_star_classification
    gas_ball.try(:classification)
  end
end

class Neighbor < Model; end

class Moon < Model
  belongs_to :planet
end
