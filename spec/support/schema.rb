ActiveRecord::Schema.define do
  self.verbose = false

  create_table :galaxies, :force => true do |t|
    t.integer :system_count, default: 0
    t.integer :star_count, default: 0
    t.timestamps
  end

  create_table :solar_systems, :force => true do |t|
    t.integer :galaxy_id
    t.timestamps
  end

  create_table :stars, :force => true do |t|
    t.integer :solar_system_id
    t.timestamps
  end

  create_table :planets, :force => true do |t|
    t.integer :star_id
    t.timestamps
  end

  create_table :moons, :force => true do |t|
    t.integer :planet_id
    t.timestamps
  end
end
