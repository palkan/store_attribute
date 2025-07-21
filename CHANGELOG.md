# Change log

## master

- **Require Ruby 3.2+ and Rails 7.2+.**

- Fix type lookup issue when registering store_attributes as attributes. ([@n-ivan][])

## 2.0.1 (2025-05-09) 🎇

- Register store_attributes as attributes. ([@rickcsong](https://github.com/rickcsong))

```ruby
class User < ActiveRecord::Base
  self.store_attribute_register_attributes = true

  store_attribute :extra, :color, :string, default: "grey"
end

User.attribute_types.keys.include?("color") #=> true
```

## 2.0.0 (2024-12-12)

- **Breaking:** The `store_attribute_unset_values_fallback_to_default` option is now true by default, meaning that the default value will be returned when the attribute key is not present in the serialized value.

For v1.x behavior, set the option to `false` globally as follows:

```ruby
StoreAttribute.store_attribute_unset_values_fallback_to_default = false
```

- Ruby >= 3.0 is required.

## 1.3.1 (2024-09-19)

- Populate missing defaults on user input when `store_attribute_unset_values_fallback_to_default` is true. ([@palkan][])

## 1.3.0 (2024-09-03) 🗓️

- Fix using defaults when store attributes are inherited from a parent model. ([@palkan][])

- Allow specifying only default values w/o types. ([@palkan][])

```ruby
store_attribute :store, :tags, default: []
```

- **Ruby >= 2.7 and Rails >= 6.1 are required**. ([@palkan][])

## 1.2.0 (2023-11-29)

- Support Rails >7.1. ([@palkan][])

- Fix handling of store attributes for not-yet-defined columns. ([@palkan][])

## 1.1.1 (2023-06-27)

- Lookup store attribute types only after schema load.

## 1.1.0 (2023-03-08) 🌷

- Add configuration option to return default values when attribute key is not present in the serialized value ([@markedmondson][], [@palkan][]).

Add to the class (preferrable `ApplicationRecord` or some other base class):

```ruby
class ApplicationRecord < ActiveRecord::Base
  self.store_attribute_unset_values_fallback_to_default = true

  store_attribute :extra, :color, :string, default: "grey"
end

user = User.create!(extra: {})
# without the fallback
user.color #=> nil
# with fallback
user.color #=> "grey"
```

## 1.0.2 (2022-07-29)

- Fix possible conflicts with Active Model objects. ([@palkan][])

- Fix passing suffix/prefix to `store_accessor` without types. ([@palkan][])

## 1.0.1 (2022-05-05)

- Fixed suffix/prefix for predicates. ([@Alan-Marx](https://github.com/Alan-Marx))

## 1.0.0 (2022-03-17)

- **Ruby 2.6+ and Rails 6+** is required.

- Refactored internal implementation to use Rails Store implementation as much as possible. ([@palkan][])

Use existing Attributes API and Store API instead of duplicating and monkey-patching. Dirty-tracking, accessors and prefixes/suffixes are now handled by Rails. We only provide type coercions for stores.

## 0.9.3 (2021-11-17)

- Fix keeping empty store hashes in the changes. ([@markedmondson][])

See [PR#22](https://github.com/palkan/store_attribute/pull/22).

## 0.9.2 (2021-10-13)

- Fix bug with store mutation during changes calculation. ([@palkan][])

## 0.9.1

- Fix bug with dirty nullable stores. ([@palkan][])

## 0.9.0 (2021-08-17) 📉

- Default values no longer marked as dirty. ([@markedmondson][])

## 0.8.1 (2020-12-03)

- Fix adding dirty tracking methods for `store_attribute`. ([@palkan][])

## 0.8.0

- Add Rails 6.1 compatibility. ([@palkan][])

- Add support for `prefix` and `suffix` options. ([@palkan][])

## 0.7.1

- Fixed bug with `store` called without accessors. ([@ioki-klaus][])

  See [#10](https://github.com/palkan/store_attribute/pull/10).

## 0.7.0 (2020-03-23)

- Added dirty tracking methods. ([@glaszig][])

  [PR #8](https://github.com/palkan/store_attribute/pull/8).

## 0.6.0 (2019-07-24)

- Added default values support. ([@dreikanter][], [@SumLare][])

  See [PR #7](https://github.com/palkan/store_attribute/pull/7).

- Start keeping changelog. ([@palkan][])

[@palkan]: https://github.com/palkan
[@dreikanter]: https://github.com/dreikanter
[@SumLare]: https://github.com/SumLare
[@glaszig]: https://github.com/glaszig
[@ioki-klaus]: https://github.com/ioki-klaus
[@markedmondson]: https://github.com/markedmondson
[@n-ivan]: https://github.com/n-ivan
