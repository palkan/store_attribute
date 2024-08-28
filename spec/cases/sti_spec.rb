# frozen_string_literal: true

require "spec_helper"

describe "STI" do
  after do
    Page.delete_all
  end

  describe "defaults" do
    it "should inherit defaults" do
      page = MediaBannerPage.new
      expect(page.heading_level).to eq("2")
      expect(page.media_type).to eq("image")

      expect { page.save! }.to change(Page, :count).by(1)
    end
  end
end
