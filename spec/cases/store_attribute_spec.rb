# frozen_string_literal: true

require "spec_helper"

describe StoreAttribute do
  before do
    @connection = ActiveRecord::Base.connection

    @connection.transaction do
      @connection.create_table("users") do |t|
        t.jsonb :jparams, default: {}, null: false
        t.text :custom
        t.hstore :hdata, default: {}, null: false
      end
    end

    User.reset_column_information
  end

  after do
    @connection.drop_table "users", if_exists: true
  end

  let(:time) { DateTime.new(2015, 2, 14, 17, 0, 0) }
  let(:time_str) { "2015-02-14 17:00" }
  let(:time_str_utc) { "2015-02-14 17:00:00 UTC" }

  context "hstore" do
    it "typecasts on build" do
      user = User.new(visible: "t", login_at: time_str)
      expect(user.visible).to eq true
      expect(user).to be_visible
      expect(user.login_at).to eq time
    end

    it "typecasts on reload" do
      user = User.new(visible: "t", login_at: time_str)
      user.save!
      user = User.find(user.id)

      expect(user.visible).to eq true
      expect(user).to be_visible
      expect(user.login_at).to eq time
    end

    it "works with accessors" do
      user = User.new
      user.visible = false
      user.login_at = time_str
      user.save!

      user = User.find(user.id)

      expect(user.visible).to be false
      expect(user).not_to be_visible
      expect(user.login_at).to eq time

      ron = RawUser.find(user.id)
      expect(ron.hdata["visible"]).to eq "false"
      expect(ron.hdata["login_at"]).to eq time_str_utc
    end

    it "handles options" do
      expect { User.create!(ratio: 1024) }.to raise_error(RangeError)
    end

    it "YAML roundtrip" do
      user = User.create!(visible: "0", login_at: time_str)
      dumped = YAML.load(YAML.dump(user)) # rubocop:disable Security/YAMLLoad

      expect(dumped.visible).to be false
      expect(dumped.login_at).to eq time
    end
  end

  context "jsonb" do
    it "typecasts on build" do
      jamie = User.new(
        active: "true",
        salary: 3.1999,
        birthday: "2000-01-01"
      )
      expect(jamie).to be_active
      expect(jamie.salary).to eq 3
      expect(jamie.birthday).to eq Date.new(2000, 1, 1)
      expect(jamie.jparams["birthday"]).to eq Date.new(2000, 1, 1)
      expect(jamie.jparams["active"]).to eq true
    end

    it "typecasts on reload" do
      jamie = User.create!(jparams: {"active" => "1", "birthday" => "01/01/2000", "salary" => "3.14"})
      jamie = User.find(jamie.id)

      expect(jamie).to be_active
      expect(jamie.salary).to eq 3
      expect(jamie.birthday).to eq Date.new(2000, 1, 1)
      expect(jamie.jparams["birthday"]).to eq Date.new(2000, 1, 1)
      expect(jamie.jparams["active"]).to eq true
    end

    it "works with accessors" do
      john = User.new
      john.active = 1

      expect(john).to be_active
      expect(john.jparams["active"]).to eq true

      john.jparams = {active: "true", salary: "123.123", birthday: "01/01/2012"}
      expect(john).to be_active
      expect(john.birthday).to eq Date.new(2012, 1, 1)
      expect(john.salary).to eq 123

      john.save!

      ron = RawUser.find(john.id)
      expect(ron.jparams["active"]).to eq true
      expect(ron.jparams["birthday"]).to eq "2012-01-01"
      expect(ron.jparams["salary"]).to eq 123
    end

    it "re-typecast old data" do
      jamie = User.create!
      User.update_all('jparams = \'{"active":"1", "salary":"12.02"}\'::jsonb')

      jamie = User.find(jamie.id)
      expect(jamie).to be_active
      expect(jamie.salary).to eq 12

      jamie.save!

      ron = RawUser.find(jamie.id)
      expect(ron.jparams["active"]).to eq true
      expect(ron.jparams["salary"]).to eq 12
    end
  end

  context "custom types" do
    it "typecasts on build" do
      user = User.new(price: "$1")
      expect(user.price).to eq 100
    end

    it "typecasts on reload" do
      jamie = User.create!(custom: {price: "$12"})
      expect(jamie.reload.price).to eq 1200

      jamie = User.find(jamie.id)

      expect(jamie.price).to eq 1200
    end
  end

  context "store subtype" do
    it "typecasts on build" do
      user = User.new(inner_json: {x: 1})
      expect(user.inner_json).to eq("x" => 1)
    end

    it "typecasts on update" do
      user = User.new
      user.update!(inner_json: {x: 1})
      expect(user.inner_json).to eq("x" => 1)

      expect(user.reload.inner_json).to eq("x" => 1)
    end

    it "typecasts on reload" do
      jamie = User.create!(inner_json: {x: 1})
      jamie = User.find(jamie.id)
      expect(jamie.inner_json).to eq("x" => 1)
    end
  end
end
