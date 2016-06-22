begin
  require 'bundler/inline'
rescue LoadError => e
  $stderr.puts 'Bundler version 1.10 or later is required. Please update your Bundler'
  raise e
end

gemfile(true) do
  source 'https://rubygems.org'
  gem 'activerecord', '~>4.2'
  gem 'pg'
  gem 'activerecord-typedstore', require: false
  gem 'pry-byebug'
  gem 'benchmark-ips'
  gem 'memory_profiler'
end

DB_NAME = ENV['DB_NAME'] || 'sa_bench'

begin
  system("createdb #{DB_NAME}")
rescue
  $stdout.puts "DB already exists"
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'active_record'
require 'logger'
require 'store_attribute'
require 'activerecord-typedstore'

ActiveRecord::Base.establish_connection(adapter: 'postgresql', database: DB_NAME)

at_exit do
  ActiveRecord::Base.connection.disconnect!
end

module Bench
  module_function
  def setup_db
    ActiveRecord::Schema.define do
      create_table :users, force: true do |t|
        t.jsonb :data
      end

      create_table :loosers, force: true do |t|
        t.jsonb :data
      end
    end
  end
end

class User < ActiveRecord::Base
  store_accessor :data, public: :boolean, published_at: :datetime, age: :integer
end

class Looser < ActiveRecord::Base
  typed_store :data, coder: JSON do |s|
    s.boolean :public
    s.datetime :published_at
    s.integer :age
  end
end

# Run migration only if neccessary
Bench.setup_db if ENV['FORCE'].present? || !ActiveRecord::Base.connection.tables.include?('users')
