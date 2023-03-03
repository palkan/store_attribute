# frozen_string_literal: true

require "spec_helper"

describe StoreAttribute::Configuration do
  subject(:configuration) { described_class.new }

  describe "#initialize" do
    it "sets defaults" do
      expect(configuration.read_unset_returns_default).to be false
    end
  end

  it "allows setting" do
    configuration.read_unset_returns_default = true
    expect(configuration.read_unset_returns_default).to be true
  end
end
