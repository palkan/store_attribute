# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "pry-byebug", platform: :mri

local_gemfile = "Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
else
  gem "activerecord", "~> 6.0"
end
