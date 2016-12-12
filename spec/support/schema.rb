ActiveRecord::Schema.define do
  self.verbose = false

  create_table :galaxies, force: true do |t|
    t.integer :solar_system_count, default: 0
    t.integer :star_count, default: 0
    t.integer :red_dwarf_count, default: 0
    t.integer :black_hole_count, default: 0
    t.integer :horizon_count, default: 0
    t.string :name
    t.timestamps
  end

  create_table :solar_systems, force: true do |t|
    t.integer :galaxy_id
    t.string :galaxy_name
    t.string :sector
    t.string :star_classification
    t.timestamps
  end

  create_table :stars, force: true do |t|
    t.integer :solar_system_id
    t.string :system_sector
    t.string :classification
    t.integer :gas_giant_count
    t.timestamps
  end

  create_table :planets, force: true do |t|
    t.integer :star_id
    t.integer :gas_ball_id
    t.string :star_classification
    t.string :classification
    t.integer :stratosphere_height
    t.timestamps
  end

  create_table :moons, force: true do |t|
    t.integer :planet_id
    t.timestamps
  end

  create_table :black_holes, force: true do |t|
    t.integer :galaxy_id
    t.timestamps
  end

  create_table :event_horizons, force: true do |t|
    t.integer :black_hole_id
    t.timestamps
  end

  create_table :atmospheres, force: true do |t|
    t.integer :planet_id
    t.timestamps
  end

  create_table :stratospheres, force: true do |t|
    t.integer :atmosphere_id
    t.integer :height
    t.timestamps
  end
end
