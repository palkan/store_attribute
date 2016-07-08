class RawUser < ActiveRecord::Base
  self.table_name = 'users'
end

class User < ActiveRecord::Base
  store_accessor :jparams, :version, active: :boolean, salary: :integer
  store_attribute :jparams, :birthday, :date

  store_attribute :jparams, :inner_json, :json

  store :custom, accessors: [price: :money_type]

  store_accessor :hdata, visible: :boolean

  store_attribute :hdata, :ratio, :integer, limit: 1
  store_attribute :hdata, :login_at, :datetime
end
