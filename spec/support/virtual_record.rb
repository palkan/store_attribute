# frozen_string_literal: true

class VirtualRecord
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Dirty

  define_attribute_methods :content

  attr_reader :content

  def content=(value)
    @content = value
    content_will_change!
  end

  def reset_dirty_tracking
    changes_applied
  end
end

class AttributedVirtualRecord
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Dirty
  include ActiveModel::Attributes

  attribute :content
end
