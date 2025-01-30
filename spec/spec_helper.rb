# frozen_string_literal: true

require "logger"
require "debug" unless ENV["CI"]

begin
  gem "psych", "< 4"
  require "psych"
rescue Gem::LoadError
end

require "active_record"
require "openssl"
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

if ActiveRecord.respond_to?(:use_yaml_unsafe_load)
  ActiveRecord.use_yaml_unsafe_load = false
  ActiveRecord.yaml_column_permitted_classes << Date
elsif ActiveRecord::Base.respond_to?(:yaml_column_permitted_classes)
  ActiveRecord::Base.yaml_column_permitted_classes << Date
end

ActiveRecord::Base.establish_connection(
  {
    "adapter" => "postgresql",
    "database" => "store_attribute_test"
  }.merge(connection_params)
)

ActiveRecord::Base.logger = Logger.new($stdout) if ENV["LOG"]

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

  config.order = :random
  Kernel.srand config.seed
end
