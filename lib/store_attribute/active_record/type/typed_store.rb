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

      def add_typed_key(key, type, default: nil, **options)
        type = ActiveRecord::Type.lookup(type, options) if type.is_a?(Symbol)
        safe_key = key.to_s
        @accessor_types[safe_key] = type
        @defaults[safe_key] = default unless default.nil?
      end

      def deserialize(value)
        hash = super
        if hash
          accessor_types.each do |key, type|
            if hash.key?(key)
              hash[key] = type.deserialize(hash[key])
            elsif defaults.key?(key)
              hash[key] = defaults[key]
            end
          end
        end
        hash
      end

      def serialize(value)
        if value.is_a?(Hash)
          typed_casted = {}
          accessor_types.each do |unsafe_key, type|
            key = key_to_cast(value, unsafe_key)
            next unless key
            if value.key?(key)
              typed_casted[key] = type.serialize(value[key])
            elsif defaults[key]
              typed_casted[key] = type.serialize(defaults[key])
            end
          end
          super(value.merge(typed_casted))
        else
          super(value)
        end
      end

      def cast(value)
        hash = super
        if hash
          accessor_types.each do |key, type|
            if hash.key?(key)
              hash[key] = type.cast(hash[key])
            elsif defaults.key?(key)
              hash[key] = defaults[key]
            end
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
      end

      def typed?(key)
        accessor_types.key?(key.to_s)
      end

      def type_for(key)
        accessor_types.fetch(key.to_s)
      end

      attr_reader :accessor_types, :defaults, :store_accessor
    end
  end
end
