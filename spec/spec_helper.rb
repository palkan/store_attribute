$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

if ENV['COVER']
  require 'simplecov'
  SimpleCov.root File.join(File.dirname(__FILE__), '..')
  SimpleCov.start
end

require 'rspec'
require 'pry-byebug'
require 'active_record'
require 'pg'
require 'store_attribute'

RAILS_5_1 = ActiveRecord.version.release >= Gem::Version.new("5.1.0")

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  database: 'store_attribute_test'
)
connection = ActiveRecord::Base.connection

unless connection.extension_enabled?('hstore')
  connection.enable_extension 'hstore'
  connection.commit_db_transaction
end

connection.reconnect!

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec

  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end
end
