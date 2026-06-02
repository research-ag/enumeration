# Enumeration changelog

## 0.2.0

### Changed

- Updated `core` from `2.0.0` to `2.5.0`.
- Converted API from class-based to static module (record type). `Enumeration` and `EnumerationBlob` are now directly stable.
- The implicit `compare` argument now comes second (right after `self`) in `Enumeration.add` and `Enumeration.lookup`, for consistency with `mo:core/Map` and `mo:core/List`.
- `Enumeration.empty` no longer takes a sentinel argument; it is now `empty<K>()`, matching `mo:core/List.empty`.

### Added

- `insert` (returns `(isNew, index)`), `containsKey`, `isEmpty`, `range`, and `sliceToArray` to both `Enumeration` and `EnumerationBlob`.
- An `examples/` project (own `mops.toml`) demonstrating canister usage with `Principal` keys, built and type-checked in CI. The test suite no longer depends on `mo:core/Principal`.

## 0.1.3

- Bump test dependency to 2.1.2 using core

## 0.1.2

- Switch from base to core 2.0.0

## 0.1.1

- Bump dependencies, use moc/base 0.11.2

## 0.1.0

- Bump dependencies

## 0.0.2

## 0.0.1
