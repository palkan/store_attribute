# frozen_string_literal: true

begin
  require "debug" unless ENV["CI"]
rescue LoadError
end

require "active_record"
require "pglite"
require "store_attribute"

if ActiveRecord.respond_to?(:use_yaml_unsafe_load)
  ActiveRecord.use_yaml_unsafe_load = false
  ActiveRecord.yaml_column_permitted_classes << Date
elsif ActiveRecord::Base.respond_to?(:yaml_column_permitted_classes)
  ActiveRecord::Base.yaml_column_permitted_classes << Date
end

PGlite.install!(File.expand_path(File.join(__dir__, "../tmp/pglite")))

ActiveRecord::Base.establish_connection(
  {
    "adapter" => "pglite",
    "database" => "store_attribute_test"
  }
)

ActiveRecord::Base.logger = Logger.new($stdout) if ENV["LOG"]

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
