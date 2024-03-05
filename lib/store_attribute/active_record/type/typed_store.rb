# frozen_string_literal: true

require "active_record/type"

module ActiveRecord
  module Type # :nodoc:
    class TypedStore < DelegateClass(ActiveRecord::Type::Value) # :nodoc:
      class Defaultik
        attr_accessor :type

        def proc
          @proc ||= Kernel.proc do
            raise ArgumentError, "Has no type attached" unless type

            type.build_defaults
          end
        end
      end

      # Creates +TypedStore+ type instance and specifies type caster
      # for key.
      def self.create_from_type(basetype, **options)
        return basetype.dup if basetype.is_a?(self)

        new(basetype)
      end

      attr_writer :owner

      def initialize(subtype)
        @accessor_types = {}
        @defaults = {}
        @subtype = subtype
        super(subtype)
      end

      UNDEFINED = Object.new

      def add_typed_key(key, type, default: UNDEFINED, **options)
        type = ActiveModel::Type::Value.new(**options) if type == :value
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
          elsif fallback_to_default?(key)
            hash[key] = built_defaults[key]
          end
        end
        hash
      end

      def changed_in_place?(raw_old_value, new_value)
        deserialize(raw_old_value) != new_value
      end

      def serialize(value)
        return super(value) unless value.is_a?(Hash)
        typed_casted = {}
        accessor_types.each do |str_key, type|
          key = key_to_cast(value, str_key)
          next unless key
          if value.key?(key)
            typed_casted[key] = type.serialize(value[key])
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

      def build_defaults
        defaults.transform_values do |val|
          val.is_a?(Proc) ? val.call : val
        end.with_indifferent_access
      end

      def dup
        self.class.new(__getobj__).tap do |dtype|
          dtype.accessor_types.merge!(accessor_types)
          dtype.defaults.merge!(defaults)
        end
      end

      protected

      def built_defaults
        @built_defaults ||= build_defaults
      end

      # We cannot rely on string keys 'cause user input can contain symbol keys
      def key_to_cast(val, key)
        return key if val.key?(key)
        return key.to_sym if val.key?(key.to_sym)
        key if defaults.key?(key)
      end

      def typed?(key)
        accessor_types.key?(key.to_s)
      end

      def type_for(key)
        accessor_types.fetch(key.to_s)
      end

      def fallback_to_default?(key)
        owner&.store_attribute_unset_values_fallback_to_default && defaults.key?(key)
      end

      def store_accessor
        subtype.accessor
      end

      attr_reader :accessor_types, :defaults, :subtype, :owner
    end
  end
end
