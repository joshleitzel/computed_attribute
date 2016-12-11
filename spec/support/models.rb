class Model < ActiveRecord::Base
  self.abstract_class = true
end

class Galaxy < Model
  include ComputedAttribute::Core
  has_many :solar_systems
  has_many :stars, through: :solar_systems

  computed_attribute :star_count, depends: :stars
  computed_attribute :system_count, depends: :solar_systems

  def computed_star_count
    stars.count
  end

  def computed_system_count
    solar_systems.count
  end
end

class SolarSystem < Model
  belongs_to :galaxy
  has_one :star # I know there are multi-star systems, just need to test a has_one :(
end

class Star < Model
  belongs_to :solar_system
  has_many :planets
end

class Planet < Model
  belongs_to :star
  has_and_belongs_to_many :neighbors
end

class Neighbor < Model; end

class Moon < Model
  belongs_to :planet
end
