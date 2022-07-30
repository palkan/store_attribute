# frozen_string_literal: true

module StoreAttribute
  # Upgrade mutation tracker to return partial changes for typed stores
  module MutationTracker
    def change_to_attribute(attr_name)
      return super unless attributes.is_a?(ActiveModel::AttributeSet)
      return super unless attributes[attr_name].type.is_a?(ActiveRecord::Type::TypedStore)

      orig_changes = super

      return unless orig_changes

      prev_store, new_store = orig_changes.map(&:dup)

      prev_store&.each do |key, value|
        if new_store[key] == value
          prev_store.except!(key)
          new_store&.except!(key)
        end
      end

      [prev_store, new_store]
    end
  end
end

require "active_model/attribute_mutation_tracker"
ActiveModel::AttributeMutationTracker.prepend(StoreAttribute::MutationTracker)
