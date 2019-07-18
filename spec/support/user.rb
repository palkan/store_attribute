# frozen_string_literal: true

class RawUser < ActiveRecord::Base
  self.table_name = "users"
end

class User < ActiveRecord::Base
  DEFAULT_LOCALE = "en-US"
  DEFAULT_DATE = ::Date.new(2019, 7, 17)

  store_accessor :jparams, :version, active: :boolean, salary: :integer
  store_attribute :jparams, :birthday, :date
  store_attribute :jparams, :safe_date, :date, default: DEFAULT_DATE
  store_attribute :jparams, :safe_locale, :string, default: DEFAULT_LOCALE
  store_attribute :jparams, :inner_json, :json

  store :custom, accessors: [price: :money_type]

  store_accessor :hdata, visible: :boolean

  store_attribute :hdata, :ratio, :integer, limit: 1
  store_attribute :hdata, :login_at, :datetime
end
