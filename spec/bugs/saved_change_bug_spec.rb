# frozen_string_literal: true

require "spec_helper"

# https://github.com/palkan/store_attribute/issues/62
class Workspace < ActiveRecord::Base
  self.table_name = "pages"

  store_attribute :content, :timezone, :string, default: "America/Los_Angeles"
end

describe "dirty tracking for typed store keys" do
  let(:workspace) { Workspace.create! }

  it "tracks in-flight changes" do
    workspace.timezone = "Europe/London"

    expect(workspace.timezone_changed?).to eq(true)
    expect(workspace.timezone_was).to eq("America/Los_Angeles")
    expect(workspace.timezone_change).to eq(["America/Los_Angeles", "Europe/London"])
  end

  it "tracks saved changes" do
    workspace.update!(timezone: "Europe/London")

    expect(workspace.saved_change_to_timezone?).to eq(true)
    expect(workspace.saved_change_to_timezone).to eq(["America/Los_Angeles", "Europe/London"])
    expect(workspace.timezone_before_last_save).to eq("America/Los_Angeles")
  end
end
