# frozen_string_literal: true

require "debug" unless ENV["CI"]
require "active_record"
require "pg"
require "store_attribute"

connection_params =
  if ENV.key?("DATABASE_URL")
    {"url" => ENV["DATABASE_URL"]}
  else
    {
      "host" => ENV["DB_HOST"],
      "username" => ENV["DB_USER"]
    }
  end

ActiveRecord::Base.establish_connection(
  {
    "adapter" => "postgresql",
    "database" => "store_attribute_test"
  }.merge(connection_params)
)

connection = ActiveRecord::Base.connection

unless connection.extension_enabled?("hstore")
  connection.enable_extension "hstore"
  connection.commit_db_transaction
end

connection.reconnect!

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec

  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end
end
