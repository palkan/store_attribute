# Change log

## master

## 1.0.0-dev

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
