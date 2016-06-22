require 'active_record/type'

module ActiveRecord
  module Type # :nodoc:
    BASE_TYPES = {
      boolean: ::ActiveRecord::Type::Boolean,
      integer: ::ActiveRecord::Type::Integer,
      string: ::ActiveRecord::Type::String,
      float: ::ActiveRecord::Type::Float,
      date: ::ActiveRecord::Type::Date,
      datetime: ::ActiveRecord::Type::DateTime,
      decimal: ::ActiveRecord::Type::Decimal
    }.freeze

    def self.lookup_type(type, options)
      BASE_TYPES[type.to_sym].try(:new, options) ||
        ActiveRecord::Base.connection.type_map.lookup(type.to_s, options)
    end

    class TypedStore < DelegateClass(ActiveRecord::Type::Value) # :nodoc:
      # Creates +TypedStore+ type instance and specifies type caster
      # for key.
      def self.create_from_type(basetype, key, type, **options)
        typed_store = new(basetype)
        typed_store.add_typed_key(key, type, **options)
        typed_store
      end

      def initialize(subtype)
        @accessor_types = {}
        @store_accessor = subtype.accessor
        super(subtype)
      end

      def add_typed_key(key, type, **options)
        type = Type.lookup_type(type, options) if type.is_a?(Symbol)
        @accessor_types[key.to_s] = type
      end

      def type_cast_from_database(value)
        hash = super
        type_cast_from_user(hash)
      end

      def type_cast_for_database(value)
        if value
          accessor_types.each do |key, type|
            k = key_to_cast(value, key)
            value[k] = type.type_cast_for_database(value[k]) unless k.nil?
          end
        end
        super(value)
      end

      def type_cast_from_user(value)
        hash = super
        if hash
          accessor_types.each do |key, type|
            hash[key] = type.type_cast_from_user(hash[key]) if hash.key?(key)
          end
        end
        hash
      end

      def accessor
        self
      end

      def write(object, attribute, key, value)
        value = type_for(key).type_cast_from_user(value) if typed?(key)
        store_accessor.write(object, attribute, key, value)
      end

      delegate :read, :prepare, to: :store_accessor

      protected

      # We cannot rely on string keys 'cause user input can contain symbol keys
      def key_to_cast(val, key)
        return key if val.key?(key)
        return key.to_sym if val.key?(key.to_sym)
      end

      def typed?(key)
        accessor_types.key?(key.to_s)
      end

      def type_for(key)
        accessor_types.fetch(key.to_s)
      end

      attr_reader :accessor_types, :store_accessor
    end
  end
end
