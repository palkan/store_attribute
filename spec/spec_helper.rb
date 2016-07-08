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

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end
end
