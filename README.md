[![Gem Version](https://badge.fury.io/rb/store_attribute.svg)](https://rubygems.org/gems/store_attribute) [![Build Status](https://travis-ci.org/palkan/store_attribute.svg?branch=master)](https://travis-ci.org/palkan/store_attribute)

## Store Attribute

ActiveRecord extension which adds typecasting to store accessors.

Compatible with Rails 4.2 and Rails 5+.

Extracted from not merged PR to Rails: [rails/rails#18942](https://github.com/rails/rails/pull/18942).

### Install

In your Gemfile:

```ruby
# for Rails 5+ (6 is supported)
gem "store_attribute", "~> 0.5.0"

# for Rails 4.2
gem "store_attribute", "~> 0.4.0"
```

### Usage

You can use `store_attribute` method to add additional accessors with a type to an existing store on a model.

```ruby
store_attribute(store_name, name, type, options)
```

Where:
- `store_name` The name of the store.
- `name` The name of the accessor to the store.
- `type` A symbol such as `:string` or `:integer`, or a type object to be used for the accessor.
- `options` (optional) A hash of cast type options such as `precision`, `limit`, `scale`, `default`.

Type casting occurs every time you write data through accessor or update store itself
and when object is loaded from database.

Note that if you update store explicitly then value isn't  type casted.

Examples:

```ruby
class MegaUser < User
  store_attribute :settings, :ratio, :integer, limit: 1
  store_attribute :settings, :login_at, :datetime
  store_attribute :settings, :active, :boolean
  store_attribute :settings, :color, :string, default: "red"
end

u = MegaUser.new(active: false, login_at: "2015-01-01 00:01", ratio: "63.4608")

u.login_at.is_a?(DateTime) # => true
u.login_at = DateTime.new(2015, 1, 1, 11, 0, 0)
u.ratio # => 63
u.active # => false
# Default value is set
u.color # => red
# And we also have a predicate method
u.active? # => false
u.reload

# After loading record from db store contains casted data
u.settings["login_at"] == DateTime.new(2015, 1, 1, 11, 0, 0) # => true

# If you update store explicitly then the value returned
# by accessor isn't type casted
u.settings["ratio"] = "3.141592653"
u.ratio # => "3.141592653"

# On the other hand, writing through accessor set correct data within store
u.ratio = "3.141592653"
u.ratio # => 3
u.settings["ratio"] # => 3
```

You can also specify type using usual `store_accessor` method:

```ruby
class SuperUser < User
  store_accessor :settings, :privileges, login_at: :datetime
end
```

Or through `store`:

```ruby
class User < ActiveRecord::Base
  store :settings, accessors: [:color, :homepage, login_at: :datetime], coder: JSON
end
```
