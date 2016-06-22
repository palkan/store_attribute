require 'spec_helper'

describe StoreAttribute do
  before do
    @connection = ActiveRecord::Base.connection

    @connection.transaction do
      @connection.create_table('users') do |t|
        t.jsonb :jparams, default: {}, null: false
        t.text :custom
        t.hstore :hdata, default: {}, null: false
      end
    end

    User.reset_column_information
  end

  after do
    @connection.drop_table 'users', if_exists: true
  end
end
