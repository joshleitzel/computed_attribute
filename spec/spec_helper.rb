$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

autoload :Star, File::expand_path('spec/support/models.rb')
autoload :SolarSystem, File::expand_path('spec/support/models.rb')

require 'byebug'
require 'active_record'
require 'computed_attribute'

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
load File::expand_path('spec/support/schema.rb')
load File::expand_path('spec/support/models.rb')
