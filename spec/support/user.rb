# frozen_string_literal: true

connection = ActiveRecord::Base.connection

connection.drop_table "users", if_exists: true

connection.transaction do
  connection.create_table("users") do |t|
    t.string :name
    t.jsonb :extra
    t.string :dyndate
    t.string :statdate
    t.jsonb :jparams, default: {}, null: false
    t.text :custom
    t.hstore :hdata, default: {}, null: false
  end
end

class RawUser < ActiveRecord::Base
  self.table_name = "users"
end

class UserWithoutDefaults < ActiveRecord::Base
  self.table_name = "users"

  store_attribute :extra, :birthday, :date
end

class UserWithAttributes < ActiveRecord::Base
  self.table_name = "users"
  self.store_attribute_register_attributes = true

  store_accessor :jparams, active: :boolean, birthday: :date, prefix: "json", suffix: "value"
  store_attribute :jparams, :inner_json, :json
  store_attribute :hdata, :salary, :integer
  store_attribute :hdata, :hours, ActiveRecord::Type.lookup(:integer)

  store :custom, accessors: [:custom_date, price: :money_type]
end

class User < ActiveRecord::Base
  DEFAULT_DATE = ::Date.new(2019, 7, 17)
  TODAY_DATE = ::Date.today

  attribute :dyndate, :datetime, default: -> { ::Time.now }
  attribute :statdate, :datetime, default: ::Time.now

  store_accessor :jparams, :version, active: :boolean, salary: :integer
  store_accessor :jparams, :version, prefix: :pre, suffix: :suf
  store_attribute :jparams, :birthday, :date
  store_attribute :jparams, :static_date, :date, default: DEFAULT_DATE
  store_attribute :jparams, :dynamic_date, :date, default: -> { TODAY_DATE }
  store_attribute :jparams, :empty_date, :date, default: nil
  store_attribute :jparams, :inner_json, :json
  store_attribute :jparams, :tags, default: []

  store_accessor :jparams, active: :boolean, birthday: :date, prefix: "json", suffix: "value"

  store :custom, accessors: [:custom_date, price: :money_type]
  after_initialize { self.custom_date = TODAY_DATE }

  store_accessor :hdata, visible: :boolean

  store_attribute :hdata, :ratio, :integer, limit: 1
  store_attribute :hdata, :login_at, :datetime

  store :details, accessors: [:age], prefix: true, suffix: :years
end
