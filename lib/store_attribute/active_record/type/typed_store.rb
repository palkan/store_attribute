# frozen_string_literal: true

require "active_record/type"

module ActiveRecord
  module Type # :nodoc:
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
        @defaults = {}
        @store_accessor = subtype.accessor
        super(subtype)
      end

      UNDEFINED = Object.new
      private_constant :UNDEFINED

      def add_typed_key(key, type, default: UNDEFINED, **options)
        type = ActiveRecord::Type.lookup(type, **options) if type.is_a?(Symbol)
        safe_key = key.to_s
        @accessor_types[safe_key] = type
        @defaults[safe_key] = default unless default == UNDEFINED
      end

      def deserialize(value)
        hash = super
        return hash unless hash
        accessor_types.each do |key, type|
          if hash.key?(key)
            hash[key] = type.deserialize(hash[key])
          elsif defaults.key?(key)
            hash[key] = get_default(key)
          end
        end
        hash
      end

      def serialize(value)
        return super(value) unless value.is_a?(Hash)
        typed_casted = {}
        accessor_types.each do |str_key, type|
          key = key_to_cast(value, str_key)
          next unless key
          if value.key?(key)
            typed_casted[key] = type.serialize(value[key])
          elsif defaults.key?(str_key)
            typed_casted[key] = type.serialize(get_default(str_key))
          end
        end
        super(value.merge(typed_casted))
      end

      def cast(value)
        hash = super
        return hash unless hash
        accessor_types.each do |key, type|
          if hash.key?(key)
            hash[key] = type.cast(hash[key])
          elsif defaults.key?(key)
            hash[key] = get_default(key)
          end
        end
        hash
      end

      def accessor
        self
      end

      def write(object, attribute, key, value)
        value = type_for(key).cast(value) if typed?(key)
        store_accessor.write(object, attribute, key, value)
      end

      delegate :read, :prepare, to: :store_accessor

      protected

      # We cannot rely on string keys 'cause user input can contain symbol keys
      def key_to_cast(val, key)
        return key if val.key?(key)
        return key.to_sym if val.key?(key.to_sym)
        return key if defaults.key?(key)
      end

      def typed?(key)
        accessor_types.key?(key.to_s)
      end

      def type_for(key)
        accessor_types.fetch(key.to_s)
      end

      def get_default(key)
        value = defaults.fetch(key)
        value.is_a?(Proc) ? value.call : value
      end

      attr_reader :accessor_types, :defaults, :store_accessor
    end
  end
end
