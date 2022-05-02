# frozen_string_literal: true

require "spec_helper"

describe StoreAttribute do
  after do
    User.delete_all
  end

  let(:date) { Date.new(2019, 7, 17) }
  let(:default_date) { User::DEFAULT_DATE }
  let(:dynamic_date) { User::TODAY_DATE }
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
      User.update_all(
        "jparams = '{"\
          '"active":"1",'\
          '"salary":"12.02"'\
        "}'::jsonb"
      )

      jamie = User.find(jamie.id)
      expect(jamie).to be_active
      expect(jamie.salary).to eq 12

      jamie.salary = 13

      jamie.save!

      ron = RawUser.find(jamie.id)
      expect(ron.jparams["active"]).to eq true
      expect(ron.jparams["salary"]).to eq 13
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

  context "default option" do
    it "should init the field after an object is created" do
      jamie = User.new
      expect(jamie.static_date).to eq(default_date)
    end

    it "should not affect explicit initialization" do
      jamie = User.new(static_date: date)
      expect(jamie.static_date).to eq(date)
    end

    it "should not affect explicit nil initialization" do
      jamie = User.new(static_date: nil)
      expect(jamie.static_date).to be_nil
    end

    it "should handle a static value" do
      jamie = User.create!
      jamie = User.find(jamie.id)
      expect(jamie.static_date).to eq(default_date)
    end

    it "should handle a lambda" do
      jamie = User.create!
      jamie = User.find(jamie.id)
      expect(jamie.dynamic_date).to eq(dynamic_date)
    end

    it "should handle nil" do
      jamie = User.create!
      jamie = User.find(jamie.id)
      expect(jamie.empty_date).to be_nil
    end

    it "should not mark as dirty" do
      jamie = User.create!
      jamie.static_date
      expect(jamie.changes).to eq({})
    end

    it "should only include changed accessors" do
      jamie = User.create!
      jamie.static_date
      jamie.visible = true
      jamie.active = true
      expect(jamie.changes).to eq({"hdata" => [{}, {"visible" => true}], "jparams" => [{}, {"active" => true}]})
    end
  end

  context "prefix/suffix" do
    it "should accept prefix and suffix options for stores" do
      jamie = User.create!(json_active_value: "t", json_birthday_value: "2019-06-26")
      jamie = User.find(jamie.id)

      expect(jamie.json_active_value).to eql(true)
      expect(jamie.json_active_value?).to eql(true)
      expect(jamie.json_birthday_value).to eq(Time.local(2019, 6, 26).to_date)

      jamie.json_active_value = false

      expect(jamie.json_active_value_changed?).to eql(true)

      jamie.save!

      expect(jamie.saved_change_to_json_active_value).to eq([true, false])
    end
  end

  context "dirty tracking" do
    let(:user) { User.create! }
    let(:now) { Time.now }

    before do
      user.price = "$ 123"
      user.visible = false
      user.login_at = now.to_s(:db)
    end

    it "should report changes" do
      expect(user.price_changed?).to be true
      expect(user.price_change).to eq [nil, 12300]
      expect(user.price_was).to eq nil

      expect(user.visible_changed?).to be true
      expect(user.visible_change).to eq [nil, false]
      expect(user.visible_was).to eq nil

      expect(user.login_at_changed?).to be true
      expect(user.login_at_change[0]).to be_nil
      expect(user.login_at_change[1].to_i).to eq now.to_i
      expect(user.login_at_was).to eq nil

      expect(user.changes["hdata"]).to eq [{}, {"login_at" => now.to_s(:db), "visible" => false}]
    end

    it "should report saved changes" do
      user.save!

      expect(user.saved_change_to_price?).to be true
      expect(user.saved_change_to_price).to eq [nil, 12300]
      expect(user.price_before_last_save).to eq nil

      expect(user.saved_change_to_visible?).to be true
      expect(user.saved_change_to_visible).to eq [nil, false]
      expect(user.visible_before_last_save).to eq nil
    end

    it "should only report on changed accessors" do
      user.active = true
      expect(user.changes["jparams"]).to eq([{}, {"active" => true}])
      expect(user.static_date_changed?).to be false
    end

    it "works with reload" do
      user.active = true
      expect(user.changes["jparams"]).to eq([{}, {"active" => true}])
      user.save!

      user.reload
      user.static_date = Date.today + 2.days

      expect(user.static_date_changed?).to be true
      expect(user.active_changed?).to be false
    end

    it "should not modify stores" do
      user.price = 99.0
      expect(user.changes["custom"]).to eq([{}, {"price" => 99}])
      user.save!

      user.reload
      user.custom_date = Date.today + 2.days

      expect(user.custom_date_changed?).to be true
      expect(user.price_changed?).to be false
      user.save!

      expect(user.reload.price).to be 99
    end

    it "should not include empty changes" do
      reloaded_user = User.take
      reloaded_user.inspect

      expect(reloaded_user.changes).to eq({})
      expect(reloaded_user.changed_attributes).to eq({})
      expect(reloaded_user.changed?).to be false
    end

    # https://github.com/palkan/store_attribute/issues/19
    it "without defaults" do
      user = UserWithoutDefaults.new
      user.birthday = "2019-06-26"

      expect(user.birthday_changed?).to eq true
    end
  end

  context "original store implementation" do
    it "doesn't break original store when no accessors passed" do
      dummy_class = Class.new(ActiveRecord::Base) do
        self.table_name = "users"

        store :custom, coder: JSON
      end

      dummy = dummy_class.new(custom: {key: "text"})

      expect(dummy.custom).to eq({"key" => "text"})
    end
  end

  context "with concerns" do
    let(:concern) do
      # https://github.com/palkan/store_attribute/pull/24#issuecomment-999833947
      Module.new do
        extend ActiveSupport::Concern

        included do
          store_accessor :extra, beginning_of_week: :integer

          include(Module.new do
            def beginning_of_week
              super || 6
            end
          end)
        end
      end
    end

    let(:raw_klass) do
      Class.new(RawUser).tap do |kl|
        kl.include concern

        kl.store_attribute :jparams, :some_flag, :boolean, default: true
      end
    end

    let(:klass) do
      Class.new(User).tap do |kl|
        kl.store_attribute :jparams, :some_flag, :boolean, default: true
        # Use this attribute to compare the behaviour of store vs regular attributes default values
        kl.attribute :name, :string, default: "john"

        kl.include concern
      end
    end

    specify do
      user = klass.new
      expect(user.beginning_of_week).to eq 6
      expect(user.some_flag).to eq(true)
      user.save!

      user = klass.find(user.id)
      expect(user).to have_attributes(
        beginning_of_week: 6,
        some_flag: true
      )

      ruser = raw_klass.new(beginning_of_week: "4")

      expect(ruser.beginning_of_week).to eq 4
      expect(ruser.some_flag).to eq(true)
      ruser.save!

      ruser = raw_klass.find(ruser.id)
      expect(ruser).to have_attributes(
        beginning_of_week: 4,
        some_flag: true
      )
    end

    specify "defaults persistence" do
      user = klass.new
      expect(user.some_flag).to eq(true)
      expect(user.name).to eq("john")
      user.save!

      user = RawUser.find(user.id)
      # Defaults persist
      expect(user).to have_attributes(
        name: "john",
        jparams: a_hash_including("some_flag" => true)
      )
    end

    specify "defaults inheritance vs persistence" do
      user = User.create!
      expect(user.jparams).not_to be_empty

      user = klass.find(user.id)
      user.name

      # Default values are only populated for new records
      expect(user).to have_attributes(
        name: nil,
        some_flag: nil
      )
    end

    specify "defaults vs user input" do
      user = klass.create!(jparams: {some_flag: false})
      user = RawUser.find(user.id)

      # When store is set explicitly by user,
      # no defaults are populated
      expect(user.jparams).to eq(
        "some_flag" => false
      )

      user = klass.create!(some_flag: false)
      user = RawUser.find(user.id)

      expect(user.jparams.keys).to include("some_flag", "static_date", "dynamic_date")
    end

    specify "double encoding" do
      user = klass.create!(inner_json: %w[kis kis])

      user = klass.find(user.id)
      expect(user).to have_attributes(
        inner_json: %w[kis kis]
      )

      # Parent class should also be able to decode the attribute
      pre_user = User.find(user.id)
      expect(pre_user).to have_attributes(
        inner_json: %w[kis kis]
      )
    end
  end
end
