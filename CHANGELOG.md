# Enumeration changelog

## 0.3.0

- **Breaking (stable type):** a tree node stores its index and its color in one `Nat32` field (`index << 1 | red`) instead of a separate color field: `Tree` is now `?(Tree, Nat32, Tree)`. A node takes 48 instead of 56 bytes on the 64-bit heap and 20 instead of 24 bytes on the 32-bit heap (−14% to −17% memory). A canister that keeps an enumeration in a stable variable needs a migration function to upgrade; see "Upgrading from 0.2.x" in the README.
- Inserting takes about 20% fewer instructions on the 64-bit heap (2% on the 32-bit heap) and allocates about 30% less, because every new node is one word smaller.
- Lookups take about 5–8% more instructions on the 64-bit heap and 12–20% more on the 32-bit heap, for decoding the field.
- New benchmark `bench/build.bench.mo` (insertions).
- An enumeration now holds at most `2 ** 31` keys (was `3 * 2 ** 30`); `insert` and `add` trap beyond that.

## 0.2.2

- `lookup` and `containsKey` are iterative instead of recursive: they no longer allocate a closure per call and take about 4–9% fewer instructions.

## 0.2.1

- Bumped `core` dependency from `2.5.0` to `2.6.2`.
- Replaced deprecated `Nat32.fromNat` with `Nat.toNat32`.
- Migrated `examples/` to moc 2.0.0.
- Updated the README and the doc comments.

## 0.2.0

- Re-write of the collections as static records instead of classes that can be declared stable directly.
- Re-write of the API closely following `core/List` and `core/Map`.
- Removed requirement to provide a sentinel value to the constructor.
- Made `compare` function argument implicit.
- Added new functions `insert`, `containsKey`, `isEmpty`, `range`, and `sliceToArray`.
- Renamed the `EnumerationBlob` module to `BlobEnumeration`.
- Added `examples/` project
- Bumped `core` dependency to `2.5.0`.
- Set `moc` requirement to `1.0.0`.

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
