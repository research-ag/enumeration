[![mops](https://oknww-riaaa-aaaam-qaf6a-cai.raw.ic0.app/badge/mops/enumeration)](https://mops.one/enumeration)
[![documentation](https://oknww-riaaa-aaaam-qaf6a-cai.raw.ic0.app/badge/documentation/enumeration)](https://mops.one/enumeration/docs)

# Enumeration for Motoko

## Overview

`Enumeration<K>` implements an add-only set of elements of type K where the
elements are numbered in the order in which they are added to the set.
The elements are called _keys_ and a key's number in the order is called _index_.
Lookups are possible in both ways, from key to index and from
index to key.
Memory space is `O(n)`.
Time complexities are:

- add a key: `O(log n)` amortized, `O(n)` worst-case (when the key array grows)
- lookup a key: `O(log n)`
- lookup an index: `O(1)`

The data structure is optimized primarily for memory efficiency
and secondarily for instruction efficiency (time).
Furthermore, instruction efficiency is optimized for lookup speed over addition speed.
The `O(n)` worst-case for adding a key is a tradeoff accepted for a constant gain in lookup speed.

### Links

The package is published on [MOPS](https://mops.one/enumeration) and [GitHub](https://github.com/research-ag/enumeration).

The API documentation can be found [here](https://mops.one/enumeration/docs/lib) on Mops.

For updates, help, questions, feedback and other requests related to this package join us on:

- [OpenChat group](https://oc.app/2zyqk-iqaaa-aaaar-anmra-cai)
- [Twitter](https://twitter.com/mr_research_ag)
- [Dfinity forum](https://forum.dfinity.org/)

### Motivation

Canister services often track their users by principal.
Per-user data is then stored in a tree or hashmap where the key is the principal and the value is the user data.

The motivation of this data structure is to enumerate the users in the order that they were registered.
This results in a permanent user number for each user.
Instead of a tree, the user data can then be stored in a linear structure such as `List` from `mo:core` or [Vector](https://mops.one/vector), which have `O(1)` access.

To this end, the present data structure provides an "enumerated set" of keys where the key type `K` is a type parameter (e.g. `Principal`).
The set elements (keys) are consecutively numbered 0,1,2,.. in the order in which they are added.
Keys cannot be deleted.

The lookup from a key to its number is tree based and the time complexity is `O(log n)`.
However, the advantage of taking this approach is that this one lookup in `Enumeration` can be the _only_ lookup in the entire canister that has complexity `O(log n)`.
All subsequent accesses to data structures, by being based on the key's number instead of the key, can be `O(1)`.

## Usage

### Install with mops

You need `mops` installed. In your project directory run:

```bash
mops add enumeration
```

In the Motoko source file import the module you need. Import either
`Enumeration` (generic) or `BlobEnumeration` (the optimized `Blob` variant),
but not both in the same module — for `Blob` keys their types coincide and the
method names would be ambiguous:

```motoko
import { Enumeration } "mo:enumeration";

```

### Example

The `compare` function is an implicit argument: it is resolved automatically
from the key type as long as that type's module (here `mo:core/Text`) is imported.

```motoko
import { Enumeration } "mo:enumeration";
import Text "mo:core/Text";

let e = Enumeration.empty<Text>();
assert e.add("abc") == 0;
assert e.add("aaa") == 1;
assert e.add("abc") == 0; // already present: same index

assert e.lookup("aaa") == ?1;
assert e.containsKey("aaa");

assert e.get(0) == ?"abc";
assert e.get(1) == ?"aaa";
assert e.get(2) == null;

assert e.at(0) == "abc";
assert e.at(1) == "aaa";
// e.at(2) traps with "Index out of bounds"

assert e.size() == 2;
assert e.sliceToArray(0, 2) == ["abc", "aaa"];

```

For `Blob` keys, prefer the optimized `BlobEnumeration` module.
It is functionally equivalent to `Enumeration.empty<Blob>()` used with
`Blob.compare`, but faster: its red-black tree compares with the primitive
`Prim.blobCompare` directly, without calling a `compare` function and
converting the result to an `Order`.
Its operations also take no `compare` argument:

```motoko
import { BlobEnumeration } "mo:enumeration";

let e = BlobEnumeration.empty();
assert e.add("abc") == 0;
assert e.lookup("abc") == ?0;

```

### Build & test

Run:

```bash
git clone git@github.com:research-ag/enumeration.git
cd enumeration
mops install
mops test
```

### Examples

The [`examples/`](https://github.com/research-ag/enumeration/tree/main/examples) directory is a self-contained mops project (with
its own `mops.toml`) that demonstrates the library in a canister. The canonical
example, [`examples/src/main.mo`](https://github.com/research-ag/enumeration/blob/main/examples/src/main.mo), assigns
permanent user numbers to principals. Type-check and build it with:

```bash
cd examples
mops install
mops check   # type-check
mops build   # compile the canister to Wasm
```

## Formatting

This project uses `prettier` with `prettier-plugin-motoko` for formatting.
To format the code, run:

```bash
npm install --no-save prettier prettier-plugin-motoko
npx prettier --plugin prettier-plugin-motoko --write '**/*.{mo,json,md}'
```

## Benchmarks

We compare `Enumeration<K>` against other maps of type `K -> Nat`:

- `Map` from `mo:core` (a B-tree),
- `pure/Map` from `mo:core` (a red-black tree),
- zhus: the [`map`](https://mops.one/map) package 9.0.1 by ZhenyaUsenko (a hash map).

The functionality of these other maps is not exactly the same but sufficiently overlaps with Enumeration that a comparison is possible. It should be noted that the other maps do not have the inverse map `Nat -> K` like Enumeration does. On the other hand, they offer deletion which Enumeration does not. However, all of them map `K -> Nat`, hence we can compare insertion and lookup operations both in terms of instructions and memory used.

All measurements use N = 4,096 random 32-byte `Blob` keys and were taken with `mops bench` on pocket-ic 15.0.0, on two heaps:

- 32-bit heap: moc 1.16.1 with legacy persistence and the compacting GC,
- 64-bit heap: moc 2.0.0 with enhanced orthogonal persistence and the incremental GC.

### Memory

For the memory benchmark we insert N random keys into the data structure.
We compare that against an array of length N with the same keys and take the difference.
This tells us the memory overhead that the data structure has over an array and eliminates the effect of boxing, which depends on type and value.
We finally divide by N to get the memory overhead per entry.

The results are as follows, unit is bytes per entry:

|             | Enumeration | `Map` (B-tree) | `pure/Map` (red-black tree) | zhus |
| ----------- | ----------- | -------------- | --------------------------- | ---- |
| 32-bit heap | 24          | 21.2           | 32                          | 28   |
| 64-bit heap | 56          |                |                             |      |

The 32-bit numbers are measured: the heap left behind after a full garbage collection.
The incremental GC of moc 2.0.0 offers no such measurement, so the 64-bit number for Enumeration is computed: its overhead per entry is one red-black tree node, which takes 56 bytes on the 64-bit heap (24 bytes on the 32-bit heap, which reproduces the measured 32-bit number).
`Enumeration<Blob>` and `BlobEnumeration` have the same memory layout.

For example, if `K` is one of `Nat32, Nat64, Nat` and the values are not boxed (e.g. < 2^30) then in an array each such entry is responsible for 4 bytes on the 32-bit heap and 8 bytes on the 64-bit heap.
Hence, by the table, each such entry in an `Enumeration<K>` is responsible for `4 + 24 = 28` bytes on the 32-bit heap and `8 + 56 = 64` bytes on the 64-bit heap.
As another example, a 32-byte `Blob` as an array entry is responsible for `32 + 12 = 44` bytes on the 32-bit heap and `32 + 32 = 64` bytes on the 64-bit heap.
Hence, adding a 32-byte entry to an `Enumeration<Blob>` will allocate `44 + 24 = 68` bytes on the 32-bit heap and `64 + 56 = 120` bytes on the 64-bit heap.

### Time

For the time benchmark we insert N random 32-byte `Blob`s into the map.
Then we look up 64 keys and take the average.
In one run the keys are in the map ("hits"),
in the other run the keys are not in the map ("misses").

The results are as follows, unit is instructions per lookup:

|                     | `BlobEnumeration` | `Enumeration<Blob>` | `Map` (B-tree) | `pure/Map` (red-black tree) | zhus |
| ------------------- | ----------------- | ------------------- | -------------- | --------------------------- | ---- |
| hits, 32-bit heap   | 2198              | 2580                | 4395           | 2326                        | 2111 |
| misses, 32-bit heap | 1530              | 1964                | 4059           | 1672                        | 1178 |
| hits, 64-bit heap   | 2876              | 3590                | 5967           | 3392                        | 2557 |
| misses, 64-bit heap | 2075              | 2886                | 5663           | 2699                        | 1401 |

Notes:

- Hits are more expensive than misses in the trees because the final comparison, if it is a match, has to compare the full 32 bytes.
- `BlobEnumeration` is faster than the generic `Enumeration<Blob>` and than `pure/Map`, but slower than the hash map zhus.
- The B-tree is the slowest for lookups, but the most memory-efficient.

## Design

The underlying data structure for the map `Nat -> K` is an array that holds reserve space. When it is full it is replaced by a larger copy, growing by a factor of about √2.
The underlying data structure for the map `K -> Nat` is a red-black tree.
The two data structures are combined into one for memory efficiency.
In particular, each key is stored only once, not twice.
This is particularly important if the keys are long (e.g. `Principal`s).

## Implementation notes

The red-black tree is in fact a tree of indices (`Nat`)
and the comparison operation first looks up the keys in the array and then compares those.
This makes lookups by key with the generic `Enumeration<K>` slower than in a red-black tree that stores the keys itself, such as `pure/Map` from `mo:core`
(as seen in the benchmark)
but is a necessary trade-off to achieve memory efficiency.

Shrinking of the array and key deletion in the red-black tree are not implemented because Enumeration does not allow key removal.

An enumeration holds at most `3 * 2^30` (about 3.2 billion) keys: that is the largest capacity of the key array, and adding a new key beyond it traps.
In practice the heap is full long before; on the 64-bit heap the tree nodes of that many keys alone would take about 180 GB.

The `BlobEnumeration` module is a performance-specialized variant for `Blob` keys.
It is functionally equivalent to `Enumeration<Blob>` used with `Blob.compare`, but its red-black tree comparisons use the primitive `Prim.blobCompare` rather than `Blob.compare`, which makes it faster.
The time benchmark above shows the difference: about 15% (32-bit heap) to 20% (64-bit heap) fewer instructions per hit than the generic `Enumeration<Blob>`.

## Copyright

MR Research AG, 2023 - 2026

## Authors

Main author: Andrii Stepanov (AStepanov25)

Contributors: Timo Hanke (timohanke), Yurii Pytomets (Pitometsu)

## License

Apache-2.0
