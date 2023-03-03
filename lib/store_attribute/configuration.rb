# frozen_string_literal: true

module StoreAttribute
  class Configuration
    attr_accessor :read_unset_returns_default

    def initialize
      @read_unset_returns_default = false
    end
  end
end
