# frozen_string_literal: true

module StoreAttribute
  module ActiveRecord
    module Store
      # Module to handle syncing between registered attributes and store values
      # when store_attribute_register_attributes is enabled
      module AttributesSync
        extend ActiveSupport::Concern

        included do
          # Define callbacks for syncing attributes from store
          after_find :_sync_store_attributes_from_database
          after_initialize :_sync_store_attributes_after_initialize
        end

        # Override attributes to include store values when registered
        def attributes
          return super unless self.class.store_attribute_register_attributes

          attrs = super
          self.class._local_typed_stored_attributes.each do |store_name, store_data|
            store_hash = public_send(store_name) || {}
            store_data[:types].each_key do |key|
              if self.class.attribute_names.include?(key.to_s) && store_hash.key?(key.to_s)
                attrs[key.to_s] = store_hash[key.to_s]
              end
            end
          end
          attrs
        end

        private

        def _sync_store_attributes_from_database
          return unless self.class.store_attribute_register_attributes

          self.class._local_typed_stored_attributes.each do |store_name, store_data|
            store_hash = public_send(store_name) || {}
            store_data[:types].each_key do |key|
              if self.class.attribute_names.include?(key.to_s) && store_hash.key?(key.to_s)
                # Update the registered attribute with the value from the store
                @attributes.write_from_database(key.to_s, store_hash[key.to_s])
              end
            end
          end
        end

        def _sync_store_attributes_after_initialize
          return unless self.class.store_attribute_register_attributes

          self.class._local_typed_stored_attributes.each do |store_name, store_data|
            store_hash = public_send(store_name) || {}
            store_data[:types].each_key do |key|
              if self.class.attribute_names.include?(key.to_s) && store_hash.key?(key.to_s)
                # Update the registered attribute with the value from the store
                if persisted?
                  @attributes.write_from_database(key.to_s, store_hash[key.to_s])
                else
                  @attributes.write_from_user(key.to_s, store_hash[key.to_s])
                end
              end
            end
          end
        end
      end
    end
  end
end
