# frozen_string_literal: true

connection = ActiveRecord::Base.connection

connection.drop_table "pages", if_exists: true

connection.transaction do
  connection.create_table("pages") do |t|
    t.string :title
    t.jsonb :content
    t.string :type
  end
end

class RawPage < ActiveRecord::Base
  self.table_name = "pages"
end

class Page < ActiveRecord::Base
end

class BannerPage < Page
  store_attribute :content, :heading_level, :string, default: "2"
end

class MediaBannerPage < BannerPage
  store_attribute :content, :media_type, :string, default: "image"
end
