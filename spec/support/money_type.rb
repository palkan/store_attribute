class MoneyType < ActiveRecord::Type::Integer
  def type_cast_from_user(value)
    if !value.is_a?(Numeric) && value.include?('$')
      price_in_dollars = value.delete('$').to_f
      super(price_in_dollars * 100)
    else
      super
    end
  end
end

ActiveRecord::Base.connection.type_map.register_type('money_type', MoneyType.new)
