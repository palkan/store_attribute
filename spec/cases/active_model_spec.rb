# frozen_string_literal: true

require "spec_helper"

# Regression test for: https://github.com/palkan/store_attribute/issues/26
describe ActiveModel do
  let(:record) { VirtualRecord.new }

  specify do
    record.content = nil
    record.content = "Zeit"

    expect(record.changes).to eq({"content" => [nil, "Zeit"]})
  end

  context "with active model attributes" do
    let(:record) { AttributedVirtualRecord.new }

    specify do
      record.content = "Zeit"

      expect(record.changes).to eq({"content" => [nil, "Zeit"]})
    end
  end
end
