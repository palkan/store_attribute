# frozen_string_literal: true

require "active_record/store"
require "store_attribute/active_record/type/typed_store"

module ActiveRecord
  module Store
    module ClassMethods # :nodoc:
      alias _orig_store store
      # Defines store on this model.
      #
      # +store_name+ The name of the store.
      #
      # ==== Options
      # The following options are accepted:
      #
      # +coder+ The coder of the store.
      #
      # +accessors+ An array of the accessors to the store.
      #
      # Examples:
      #
      #   class User < ActiveRecord::Base
      #     store :settings, accessors: [:color, :homepage, login_at: :datetime], coder: JSON
      #   end
      def store(store_name, options = {})
        accessors = options.delete(:accessors)
        typed_accessors =
          if accessors && accessors.last.is_a?(Hash)
            accessors.pop
          else
            {}
          end

        _orig_store(store_name, options)
        store_accessor(store_name, *accessors, **typed_accessors) if accessors
      end

      # Adds additional accessors to an existing store on this model.
      #
      # +store_name+ The name of the store.
      #
      # +keys+ The array of the accessors to the store.
      #
      # +typed_keys+ The key-to-type hash of the accesors with type to the store.
      #
      # +prefix+ Accessor method name prefix
      #
      # +suffix+ Accessor method name suffix
      #
      # Examples:
      #
      #   class SuperUser < User
      #     store_accessor :settings, :privileges, login_at: :datetime
      #   end
      def store_accessor(store_name, *keys, prefix: nil, suffix: nil, **typed_keys)
        keys = keys.flatten
        typed_keys = typed_keys.except(keys)

        accessor_prefix, accessor_suffix = _normalize_prefix_suffix(store_name, prefix, suffix)

        _define_accessors_methods(store_name, *keys, prefix: accessor_prefix, suffix: accessor_suffix)

        _define_dirty_tracking_methods(store_name, keys + typed_keys.keys, prefix: accessor_prefix, suffix: accessor_suffix)

        _prepare_local_stored_attributes(store_name, *keys)

        typed_keys.each do |key, type|
          store_attribute(store_name, key, type, prefix: prefix, suffix: suffix)
        end
      end

      # Adds additional accessors with a type to an existing store on this model.
      # Type casting occurs every time you write data through accessor or update store itself
      # and when object is loaded from database.
      #
      # Note that if you update store explicitly then value isn't  type casted.
      #
      # +store_name+ The name of the store.
      #
      # +name+ The name of the accessor to the store.
      #
      # +type+ A symbol such as +:string+ or +:integer+, or a type object
      # to be used for the accessor.
      #
      # +prefix+ Accessor method name prefix
      #
      # +suffix+ Accessor method name suffix
      #
      # +options+ A hash of cast type options such as +precision+, +limit+, +scale+.
      #
      # Examples:
      #
      #   class MegaUser < User
      #     store_attribute :settings, :ratio, :integer, limit: 1
      #     store_attribute :settings, :login_at, :datetime
      #
      #     store_attribute :extra, :version, :integer, prefix: :meta
      #   end
      #
      #   u = MegaUser.new(active: false, login_at: '2015-01-01 00:01', ratio: "63.4608", meta_version: "1")
      #
      #   u.login_at.is_a?(DateTime) # => true
      #   u.login_at = DateTime.new(2015,1,1,11,0,0)
      #   u.ratio # => 63
      #   u.meta_version #=> 1
      #   u.reload
      #
      #   # After loading record from db store contains casted data
      #   u.settings['login_at'] == DateTime.new(2015,1,1,11,0,0) # => true
      #
      #   # If you update store explicitly then the value returned
      #   # by accessor isn't type casted
      #   u.settings['ration'] = "3.141592653"
      #   u.ratio # => "3.141592653"
      #
      #   # On the other hand, writing through accessor set correct data within store
      #   u.ratio = "3.14.1592653"
      #   u.ratio # => 3
      #   u.settings['ratio'] # => 3
      #
      # For more examples on using types, see documentation for ActiveRecord::Attributes.
      def store_attribute(store_name, name, type, prefix: nil, suffix: nil, **options)
        prefix, suffix = _normalize_prefix_suffix(store_name, prefix, suffix)

        _define_accessors_methods(store_name, name, prefix: prefix, suffix: suffix)

        _define_predicate_method(name, prefix: prefix, suffix: suffix) if type == :boolean

        # Rails >6.0
        if !respond_to?(:decorate_attribute_type) || method(:decorate_attribute_type).parameters.count { |type, _| type == :req } == 1
          attr_name = store_name.to_s
          was_type = attributes_to_define_after_schema_loads[attr_name]&.first
          attribute(attr_name) do |subtype|
            Type::TypedStore.create_from_type(_lookup_cast_type(attr_name, was_type, {}), name, type, **options)
          end
        else
          decorate_attribute_type(store_name, "typed_accessor_for_#{name}") do |subtype|
            Type::TypedStore.create_from_type(subtype, name, type, **options)
          end
        end

        _define_dirty_tracking_methods(store_name, [name], prefix: prefix, suffix: suffix)

        _prepare_local_stored_attributes(store_name, name)
      end

      def _prepare_local_stored_attributes(store_name, *keys) # :nodoc:
        # assign new store attribute and create new hash to ensure that each class in the hierarchy
        # has its own hash of stored attributes.
        self.local_stored_attributes ||= {}
        self.local_stored_attributes[store_name] ||= []
        self.local_stored_attributes[store_name] |= keys
      end

      def _define_accessors_methods(store_name, *keys, prefix: nil, suffix: nil) # :nodoc:
        _store_accessors_module.module_eval do
          keys.each do |key|
            accessor_key = "#{prefix}#{key}#{suffix}"

            define_method("#{accessor_key}=") do |value|
              write_store_attribute(store_name, key, value)
            end

            define_method(accessor_key) do
              read_store_attribute(store_name, key)
            end
          end
        end
      end

      def _define_predicate_method(name, prefix: nil, suffix: nil)
        _store_accessors_module.module_eval do
          name = "#{prefix}#{name}#{suffix}"

          define_method("#{name}?") do
            send(name) == true
          end
        end
      end

      def _define_dirty_tracking_methods(store_attribute, keys, prefix: nil, suffix: nil)
        _store_accessors_module.module_eval do
          keys.flatten.each do |key|
            key = key.to_s
            accessor_key = "#{prefix}#{key}#{suffix}"

            define_method("#{accessor_key}_changed?") do
              return false unless attribute_changed?(store_attribute)
              prev_store, new_store = changes[store_attribute]
              prev_store&.dig(key) != new_store&.dig(key)
            end

            define_method("#{accessor_key}_change") do
              return unless attribute_changed?(store_attribute)
              prev_store, new_store = changes[store_attribute]
              [prev_store&.dig(key), new_store&.dig(key)]
            end

            define_method("#{accessor_key}_was") do
              return unless attribute_changed?(store_attribute)
              prev_store, _new_store = changes[store_attribute]
              prev_store&.dig(key)
            end

            define_method("saved_change_to_#{accessor_key}?") do
              return false unless saved_change_to_attribute?(store_attribute)
              prev_store, new_store = saved_change_to_attribute(store_attribute)
              prev_store&.dig(key) != new_store&.dig(key)
            end

            define_method("saved_change_to_#{accessor_key}") do
              return unless saved_change_to_attribute?(store_attribute)
              prev_store, new_store = saved_change_to_attribute(store_attribute)
              [prev_store&.dig(key), new_store&.dig(key)]
            end

            define_method("#{accessor_key}_before_last_save") do
              return unless saved_change_to_attribute?(store_attribute)
              prev_store, _new_store = saved_change_to_attribute(store_attribute)
              prev_store&.dig(key)
            end
          end
        end
      end

      def _normalize_prefix_suffix(store_name, prefix, suffix)
        prefix =
          case prefix
          when String, Symbol
            "#{prefix}_"
          when TrueClass
            "#{store_name}_"
          end

        suffix =
          case suffix
          when String, Symbol
            "_#{suffix}"
          when TrueClass
            "_#{store_name}"
          end

        [prefix, suffix]
      end
    end
  end
end
