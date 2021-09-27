# frozen_string_literal: true

class RawUser < ActiveRecord::Base
  self.table_name = "users"
end

class UserWithoutDefaults < ActiveRecord::Base
  self.table_name = "users"

  store_attribute :extra, :birthday, :date
end

class User < ActiveRecord::Base
  DEFAULT_DATE = ::Date.new(2019, 7, 17)
  TODAY_DATE = ::Date.today

  store_accessor :jparams, :version, active: :boolean, salary: :integer
  store_attribute :jparams, :birthday, :date
  store_attribute :jparams, :static_date, :date, default: DEFAULT_DATE
  store_attribute :jparams, :dynamic_date, :date, default: -> { TODAY_DATE }
  store_attribute :jparams, :empty_date, :date, default: nil
  store_attribute :jparams, :inner_json, :json

  store_accessor :jparams, active: :boolean, birthday: :date, prefix: "json", suffix: "value"

  store :custom, accessors: [price: :money_type]

  store_accessor :hdata, visible: :boolean

  store_attribute :hdata, :ratio, :integer, limit: 1
  store_attribute :hdata, :login_at, :datetime
end
