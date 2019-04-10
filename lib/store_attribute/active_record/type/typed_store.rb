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
        @store_accessor = subtype.accessor
        super(subtype)
      end

      def add_typed_key(key, type, **options)
        type = ActiveRecord::Type.lookup(type, options) if type.is_a?(Symbol)
        @accessor_types[key.to_s] = type
      end

      def deserialize(value)
        hash = super
        if hash
          accessor_types.each do |key, type|
            hash[key] = type.deserialize(hash[key]) if hash.key?(key)
          end
        end
        hash
      end

      def serialize(value)
        if value.is_a?(Hash)
          typed_casted = {}
          accessor_types.each do |key, type|
            k = key_to_cast(value, key)
            typed_casted[k] = type.serialize(value[k]) unless k.nil?
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
            hash[key] = type.cast(hash[key]) if hash.key?(key)
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

      attr_reader :accessor_types, :store_accessor
    end
  end
end
