# frozen_string_literal: true

require "store_attribute/version"
require "store_attribute/active_record"

module StoreAttribute
  class << self
    # Global default value for `store_attribute_unset_values_fallback_to_default` option.
    # Must be set before any model is loaded
    attr_accessor :store_attribute_unset_values_fallback_to_default
    attr_accessor :store_attribute_register_attributes
  end

  self.store_attribute_unset_values_fallback_to_default = true
  self.store_attribute_register_attributes = false
end
