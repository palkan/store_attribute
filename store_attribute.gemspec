# frozen_string_literal: true

require_relative "lib/store_attribute/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "store_attribute"
  s.version = StoreAttribute::VERSION
  s.authors = ["palkan"]
  s.email = ["dementiev.vm@gmail.com"]
  s.homepage = "http://github.com/palkan/store_attribute"
  s.summary = "ActiveRecord extension which adds typecasting to store accessors"
  s.description = "ActiveRecord extension which adds typecasting to store accessors"
  s.license = "MIT"

  s.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 3.0.0"

  s.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/store_attribute/issues",
    "changelog_uri" => "https://github.com/palkan/store_attribute/blob/master/CHANGELOG.md",
    "documentation_uri" => "http://github.com/palkan/store_attribute",
    "homepage_uri" => "http://github.com/palkan/store_attribute",
    "source_code_uri" => "http://github.com/palkan/store_attribute"
  }

  s.add_runtime_dependency "activerecord", ">= 6.1"

  s.add_development_dependency "pg", ">= 1.0"
  s.add_development_dependency "rake", ">= 13.0"
  s.add_development_dependency "rspec", ">= 3.5.0"
end
