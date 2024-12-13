# frozen_string_literal: true

require "active_record/store"
require "store_attribute/active_record/type/typed_store"
require "store_attribute/active_record/mutation_tracker"

module ActiveRecord
  module Store
    module ClassMethods # :nodoc:
      alias_method :_orig_store_without_types, :store
      alias_method :_orig_store_accessor_without_types, :store_accessor

      attr_writer :store_attribute_unset_values_fallback_to_default

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
        accessor_related_options = options.slice(:prefix, :suffix)
        typed_accessors =
          if accessors && accessors.last.is_a?(Hash)
            accessors.pop
          else
            {}
          end

        _orig_store_without_types(store_name, options)
        store_accessor(store_name, *accessors, **accessor_related_options, **typed_accessors) if accessors
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

        _orig_store_accessor_without_types(store_name, *(keys - typed_keys.keys), prefix: prefix, suffix: suffix)

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
      #   u.ratio = "3.141592653"
      #   u.ratio # => 3
      #   u.settings['ratio'] # => 3
      #
      # For more examples on using types, see documentation for ActiveRecord::Attributes.
      def store_attribute(store_name, name, type = :value, prefix: nil, suffix: nil, **options)
        _orig_store_accessor_without_types(store_name, name.to_s, prefix: prefix, suffix: suffix)
        _define_predicate_method(name, prefix: prefix, suffix: suffix) if type == :boolean

        _define_store_attribute(store_name) if !_local_typed_stored_attributes? ||
          _local_typed_stored_attributes[store_name][:types].empty? ||
          # Defaults owner has changed, we must decorate the attribute to correctly propagate the defaults
          (
            options.key?(:default) && _local_typed_stored_attributes[store_name][:owner] != self
          )

        _local_typed_stored_attributes[store_name][:owner] = self if options.key?(:default) || !_local_typed_stored_attributes?
        _local_typed_stored_attributes[store_name][:types][name] = [type, options]
      end

      def store_attribute_unset_values_fallback_to_default
        return @store_attribute_unset_values_fallback_to_default if instance_variable_defined?(:@store_attribute_unset_values_fallback_to_default)

        @store_attribute_unset_values_fallback_to_default =
          if superclass.respond_to?(:store_attribute_unset_values_fallback_to_default)
            superclass.store_attribute_unset_values_fallback_to_default
          else
            StoreAttribute.store_attribute_unset_values_fallback_to_default
          end
      end

      def _local_typed_stored_attributes?
        instance_variable_defined?(:@local_typed_stored_attributes)
      end

      def _local_typed_stored_attributes
        return @local_typed_stored_attributes if _local_typed_stored_attributes?

        @local_typed_stored_attributes =
          if superclass.respond_to?(:_local_typed_stored_attributes)
            superclass._local_typed_stored_attributes.dup.tap do |h|
              h.transform_values! { |v| {owner: v[:owner], types: v[:types].dup} }
            end
          else
            Hash.new { |h, k| h[k] = {types: {}.with_indifferent_access} }.with_indifferent_access
          end
      end

      def _define_store_attribute(store_name)
        attr_name = store_name.to_s

        defaultik = Type::TypedStore::Defaultik.new

        owner = self

        # Rails >7.1
        if respond_to?(:decorate_attributes)
          decorate_attributes([attr_name]) do |_, subtype|
            subtypes = _local_typed_stored_attributes[attr_name][:types]
            type = Type::TypedStore.create_from_type(subtype)
            type.owner = owner
            defaultik.type = type
            subtypes.each do |name, (cast_type, options)|
              type.add_typed_key(name, cast_type, **options.symbolize_keys)
            end

            type
          end

          attribute(attr_name, default: defaultik.proc)
        # Rails >=6.1, <=7.1
        else
          was_type = attributes_to_define_after_schema_loads[attr_name]&.first

          attribute(attr_name, default: defaultik.proc) do |subtype|
            subtypes = _local_typed_stored_attributes[attr_name][:types]
            subtype = _lookup_cast_type(attr_name, was_type, {}) if defined?(_lookup_cast_type)

            type = Type::TypedStore.create_from_type(subtype)
            type.owner = owner
            defaultik.type = type
            subtypes.each do |name, (cast_type, options)|
              type.add_typed_key(name, cast_type, **options.symbolize_keys)
            end

            # Make sure default attribute uses the correct type, so #changed? works as expected
            # This is dirty hack that makes Rails <7.2 works similar to Rails >=7.2. Please, upgrade :)
            if type.defaults.any? && _default_attributes[attr_name] && !_default_attributes[attr_name].type.is_a?(Type::TypedStore)
              _default_attributes[attr_name] =
                ActiveModel::Attribute.from_database(attr_name, _default_attributes[attr_name].value.deep_dup, type)
            end

            type
          end
        end
      end

      def _define_predicate_method(name, prefix: nil, suffix: nil)
        accessor_prefix =
          case prefix
          when String, Symbol
            "#{prefix}_"
          when TrueClass
            "#{name}_"
          else
            ""
          end
        accessor_suffix =
          case suffix
          when String, Symbol
            "_#{suffix}"
          when TrueClass
            "_#{name}"
          else
            ""
          end

        _store_accessors_module.module_eval do
          name = "#{accessor_prefix}#{name}#{accessor_suffix}"

          define_method("#{name}?") do
            send(name) == true
          end
        end
      end
    end
  end
end
