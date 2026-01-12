# frozen_string_literal: true

require "spec_helper"

# https://github.com/palkan/store_attribute/issues/47
class Car < ActiveRecord::Base
  self.table_name = "users"

  store_attribute :extra, :colored, :boolean

  # this line is key. without this line, everything works fine
  # I happen to have some metaprogramming that requires inspecting the existing columns
  # and store_attributes are created based on the columns
  columns

  store_attribute :extra, :electric, :boolean
end

describe "reload schema bug" do
  specify do
    car = Car.create(electric: false, colored: true)
    car.update(electric: "1", colored: "0")

    expect(car).to have_attributes(
      electric: true,
      colored: false
    )
  end
end
