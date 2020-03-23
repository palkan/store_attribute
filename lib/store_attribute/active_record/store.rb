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
          if accessors.last.is_a?(Hash)
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
      # Examples:
      #
      #   class SuperUser < User
      #     store_accessor :settings, :privileges, login_at: :datetime
      #   end
      def store_accessor(store_name, *keys, **typed_keys)
        keys = keys.flatten
        typed_keys = typed_keys.except(keys)

        _define_accessors_methods(store_name, *keys)

        _define_dirty_tracking_methods(store_name, keys)
        _define_dirty_tracking_methods(store_name, typed_keys.keys)

        _prepare_local_stored_attributes(store_name, *keys)

        typed_keys.each do |key, type|
          store_attribute(store_name, key, type)
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
      # +options+ A hash of cast type options such as +precision+, +limit+, +scale+.
      #
      # Examples:
      #
      #   class MegaUser < User
      #     store_attribute :settings, :ratio, :integer, limit: 1
      #     store_attribute :settings, :login_at, :datetime
      #   end
      #
      #   u = MegaUser.new(active: false, login_at: '2015-01-01 00:01', ratio: "63.4608")
      #
      #   u.login_at.is_a?(DateTime) # => true
      #   u.login_at = DateTime.new(2015,1,1,11,0,0)
      #   u.ratio # => 63
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
      def store_attribute(store_name, name, type, **options)
        _define_accessors_methods(store_name, name)

        _define_predicate_method(name) if type == :boolean

        decorate_attribute_type(store_name, "typed_accessor_for_#{name}") do |subtype|
          Type::TypedStore.create_from_type(subtype, name, type, **options)
        end

        _prepare_local_stored_attributes(store_name, name)
      end

      def _prepare_local_stored_attributes(store_name, *keys) # :nodoc:
        # assign new store attribute and create new hash to ensure that each class in the hierarchy
        # has its own hash of stored attributes.
        self.local_stored_attributes ||= {}
        self.local_stored_attributes[store_name] ||= []
        self.local_stored_attributes[store_name] |= keys
      end

      def _define_accessors_methods(store_name, *keys) # :nodoc:
        _store_accessors_module.module_eval do
          keys.each do |key|
            define_method("#{key}=") do |value|
              write_store_attribute(store_name, key, value)
            end

            define_method(key) do
              read_store_attribute(store_name, key)
            end
          end
        end
      end

      def _define_predicate_method(name)
        _store_accessors_module.module_eval do
          define_method("#{name}?") do
            send(name) == true
          end
        end
      end

      def _define_dirty_tracking_methods(store_attribute, keys)
        _store_accessors_module.module_eval do
          keys.flatten.each do |key|
            key = key.to_s

            define_method("#{key}_changed?") do
              return false unless attribute_changed?(store_attribute)
              prev_store, new_store = changes[store_attribute]
              prev_store&.dig(key) != new_store&.dig(key)
            end

            define_method("#{key}_change") do
              return unless attribute_changed?(store_attribute)
              prev_store, new_store = changes[store_attribute]
              [prev_store&.dig(key), new_store&.dig(key)]
            end

            define_method("#{key}_was") do
              return unless attribute_changed?(store_attribute)
              prev_store, _new_store = changes[store_attribute]
              prev_store&.dig(key)
            end

            define_method("saved_change_to_#{key}?") do
              return false unless saved_change_to_attribute?(store_attribute)
              prev_store, new_store = saved_change_to_attribute(store_attribute)
              prev_store&.dig(key) != new_store&.dig(key)
            end

            define_method("saved_change_to_#{key}") do
              return unless saved_change_to_attribute?(store_attribute)
              prev_store, new_store = saved_change_to_attribute(store_attribute)
              [prev_store&.dig(key), new_store&.dig(key)]
            end

            define_method("#{key}_before_last_save") do
              return unless saved_change_to_attribute?(store_attribute)
              prev_store, _new_store = saved_change_to_attribute(store_attribute)
              prev_store&.dig(key)
            end
          end
        end
      end
    end
  end
end
