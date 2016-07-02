$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "store_attribute/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "store_attribute"
  s.version     = StoreAttribute::VERSION
  s.authors     = ["palkan"]
  s.email       = ["dementiev.vm@gmail.com"]
  s.homepage    = "http://github.com/palkan/store_attribute"
  s.summary     = "ActiveRecord extension which adds typecasting to store accessors"
  s.description = "ActiveRecord extension which adds typecasting to store accessors"
  s.license     = "MIT"

  s.files         = `git ls-files`.split($/)
  s.require_paths = ["lib"]

  s.add_runtime_dependency "activerecord", "~>5.0.0"

  s.add_development_dependency "pg", "~>0.18"
  s.add_development_dependency "rake", "~> 10.1"
  s.add_development_dependency "simplecov", ">= 0.3.8"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "rspec", "~> 3.5.0"
end
