class User < ActiveRecord::Base
  store_accessor :jparams, :version, active: :boolean

  store :custom, accessors: [price: :money]

  store_attribute :hdata, :ratio, :integer, limit: 1
  store_attribute :hdata, :login_at, :datetime
end
