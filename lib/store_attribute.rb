# frozen_string_literal: true

require "store_attribute/version"
require "store_attribute/active_record"
require "store_attribute/configuration"

module StoreAttribute
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
