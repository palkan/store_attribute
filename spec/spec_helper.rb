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

# pglite 0.1.1 is missing the connection methods that the latest Rails
# calls (close, finished?, status), and it answers nil when Rails asks
# parameter_status for the time zone. Getting no answer, Rails sets the
# session time zone itself, and the wasm build cannot survive that
# statement. It looks like it ships without time zone data, so any time
# zone SET kills the instance for good. Answering "UTC" here means Rails
# never sends it.
#
# The patch is pinned to this exact gem version so it retires itself on
# the next pglite release. It also has to run before the first database
# access. The support files connect at load time further down this file.
if Gem::Version.new(PGlite::VERSION) <= Gem::Version.new("0.1.1")
  # Rails main compares status to PG::CONNECTION_OK, a constant the pglite
  # PG stub does not define. The real libpq value is 0.
  PG.const_set(:CONNECTION_OK, 0) unless defined?(PG::CONNECTION_OK)

  module PGliteRailsMainCompat
    def close = nil

    def finished? = false

    def status = PG::CONNECTION_OK

    def parameter_status(name)
      # We cannot ask the embedded server for its time zone because that
      # query also crashes it. Assume the wasm default of GMT, same as UTC.
      return "UTC" if name.to_s.casecmp?("timezone")

      super
    end
  end

  PGlite::Connection.prepend(PGliteRailsMainCompat)
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
