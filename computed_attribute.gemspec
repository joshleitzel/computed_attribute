# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'computed_attribute/version'

Gem::Specification.new do |spec|
  spec.name          = 'computed_attribute'
  spec.version       = ComputedAttribute::VERSION
  spec.authors       = ['Josh Leitzel']
  spec.email         = ['joshleitzel@gmail.com']

  spec.summary       = 'Computed attributes for ActiveRecord'
  spec.description   = '
    Store and auto-update computed attributes on ActiveRecord models
  '
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'activerecord', '~> 4.2'
  spec.add_development_dependency 'sqlite3', '~> 1.3'
  spec.add_development_dependency 'byebug', '~> 9.0'
  spec.add_development_dependency 'rubocop', '~> 0.42'
end
