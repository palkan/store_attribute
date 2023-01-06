# frozen_string_literal: true

class MoneyType < ActiveRecord::Type::Integer
  def cast(value)
    if !value.is_a?(Numeric) && value&.include?("$")
      price_in_dollars = value.delete("$").to_f
      super(price_in_dollars * 100)
    else
      super
    end
  end
end

ActiveRecord::Type.register(:money_type, MoneyType)
