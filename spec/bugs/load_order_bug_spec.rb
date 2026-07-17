# frozen_string_literal: true

require "spec_helper"
require "open3"
require "rbconfig"

RSpec.describe "load order" do
  # Guard against store_attribute loading Active Record's JSON type before apps
  # have configured their JSON encoder.
  it "does not eagerly load active_record/type/json.rb" do
    # Use a subprocess because spec_helper has already required store_attribute.
    # This lets us observe which files are loaded by requiring the gem.
    script = <<~'RUBY'
      require "active_record"

      json_type_features_before = $LOADED_FEATURES.grep(%r{/active_record/type/json\.rb\z})

      require "store_attribute"

      json_type_features_after = $LOADED_FEATURES.grep(%r{/active_record/type/json\.rb\z})
      loaded_by_store_attribute = json_type_features_after - json_type_features_before

      abort loaded_by_store_attribute.join("\n") if loaded_by_store_attribute.any?
    RUBY

    _stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-e", script)

    expect(status).to be_success, stderr
  end
end
