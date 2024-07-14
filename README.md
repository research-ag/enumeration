# Enumeration for Motoko

## Overview

`Enumeration<K>` implements an add-only set of elements of type K where the
elements are numbered in the order in which they are added to the set.
The elements are called *keys* and a key's number in the order is called *index*.
Lookups are possible in both ways, from key to index and from 
index to key.
Memory space is `O(n)`.
Time complexities are:

* add a key: `O(log n)` average, `O(n)` worst-case
* lookup a key: `O(log n)`
* lookup an index: `O(1)`

The data structure is optimized primarily for memory efficiency
and secondarily for instruction efficiency (time).
Furthermore, instruction efficiency is optimized for lookup speed over addition speed.
The `O(n)` worst-case for adding a key is a tradeoff accepted for a constant gain in lookup speed.

### Links

The package is published on [MOPS](https://mops.one/enumeration) and [GitHub](https://github.com/research-ag/enumeration).
Please refer to the README on GitHub where it renders properly with formulas and tables.

The API documentation can be found [here](https://mops.one/enumeration/docs/lib) on Mops.

For updates, help, questions, feedback and other requests related to this package join us on:

* [OpenChat group](https://oc.app/2zyqk-iqaaa-aaaar-anmra-cai)
* [Twitter](https://twitter.com/mr_research_ag)
* [Dfinity forum](https://forum.dfinity.org/)

### Motivation

Canister services often track their users by principal.
Per-user data is then stored in a tree or hashmap where the key is the principal and the value is the user data.

The motivation of this data structure is to enumerate the users in the order that they were registered.
This result in a permanent user number for each user.
Instead of a tree, the user data can then be stored in a linear structure such as Buffer or [Vector](https://mops.one/vector) which has `O(1)` access.

To this end, the present data structure provides an "enumerated set" of keys where the key type `K` is a type parameter (e.g. `Principal`). 
The set elements (keys) are consecutively numbered 0,1,2,.. in the order in which they are added.
Keys cannot be deleted.

The lookup from a key to its number is tree based and the time complexity is `O(log n)`. 
However, the advantage of taking this approach is that this one lookup in `Enumeration` can be the _only_ lookup in the entire canister that has complexity `O(log n)`.
All subsequent accesses to data structures, by being based on the key's number instead of the key, can be `O(1)`.

## Usage

### Install with mops

You need `mops` installed. In your project directory run:
```
mops add enumeration
```

In the Motoko source file import the package as:
```
import Enumeration "mo:enumeration";
```

### Example

```
let e = Enumeration.Enumeration<Blob>(Blob.compare, "");
e.add("abc"); // -> 0
e.add("aaa"); // -> 1
e.add("abc"); // -> 0
e.lookup("aaa"); // -> ?1
e.get(0); // -> "abc"
e.get(1); // -> "aaa"
```
### Build & test

Run:
```
git clone git@github.com:research-ag/enumeration.git
mops install
mops test
```

## Benchmarks

Benchmarking code can be found here: [canister-profiling](https://github.com/research-ag/canister-profiling)

We compare `Enumeration<K>` against various other maps of type `K -> Nat`. The functionality of these other maps is not exactly the same but sufficiently overlaps with Enumeration that a comparison is possible. It should be noted that the other maps do not have the inverse map `Nat -> K` like Enumeration does. On the other hand, they offer deletion which Enumeration does not. However, the map `K -> Nat` is tree-based in all cases hence we can compare insertion and lookup operations both in terms of instructions and memory used.

The results below have been obtained with `moc 0.9.2`.

### Memory

For the memory benchmark we insert N random entries of a given type `K` into Enumeration.
We compare that against an array of length N with the same entries and take the difference.
This tells us the memory overhead that the data structure has over an array and eliminates the effect of boxing, which depend on type and value.
We finally divide by N to get the memory overhead per entry.

The results are as follows (N = 4,096), unit is bytes per entry: 

|btree|enumeration|rb_tree|map v7|map v8|
|---|---|---|---|---|
|20.9|24|48|36*|52|

For example, if `K` is one of `Nat32, Nat64, Nat` and the values are not boxed (e.g. < 2^30) then we know that in an array each such entry is responsible for 4 bytes on the heap. 
Hence, by the table, each such entry in an `Enumeration<K>` is responsible for `4 + 24 = 28` bytes on the heap.
As another example, we know that a 32-byte `Blob` as an array entry is responsible for `32 + 12 = 44` bytes.
Hence, adding a 32-byte entry to an `Enumeration<Blob>` will allocate `44 + 24 = 68` bytes on the heap.

_* Note: map v7 has shown an unexpected type dependency which we have not investigated further.
The given result is for type `Blob`.
The data structure may be more efficient for type `Nat32`.

### Time

For the time benchmark we use 32 byte `Blob`s as keys.
We insert N random blobs into the map.
Then we look up several of the keys and take the average.
In one run the keys are actually in the map already ("hits"),
in the other run the keys are not in the map ("misses").  

The results are as follows (N = 4,096), unit is instructions per lookup: 

||btree|enumeration|rb_tree|map v7|map v8|
|---|---|---|---|---|---|
|hits|4972|2519|2483|2060|1934|
|misses|4972|2026|1983|2060|1934|

Notes:

* Hits are more expensive in the rb-tree based data structures because the final comparison, if it is a match, has to compare the full 32 bytes.
* For misses, the rb-tree based data structures are as fast as the hashmaps (v7, v8).
* For enumeration the optimized class `EnumerationBlob` was used in the benchmark, not the generic class `Enumeration<Blob>`.

## Design

The underlying data structure for the map `Nat -> K` is an array that holds reserve space and is grown with an algorithm similar to Buffer.
The underlying data structure for the map `K -> Nat` is a red-black tree.
The two data structures are combined into one for memory efficiency. 
In particular, each key is stored only once, not twice.
This is particularly important if the keys are long (e.g. `Principal`s).

## Implementation notes

The red-black tree is in fact a tree from `Nat -> Nat` 
and the comparison operation first looks up the keys in the array and then compares those.
This makes lookups by key slightly slower than in the RBTree from motoko-base
(as seen in the benchmark)
but is a necessary trade-off to achieve memory efficiency.

Shrinking of the array and key deletion in the red-black tree are not implemented because Enumeration does not allow key removal. 

## Copyright

MR Research AG, 2023-2024
## Authors

Main author: Andrii Stepanov (AStepanov25)\
Contributors: Timo Hanke (timohanke), Yurii Pytomets (Pitometsu)
## License 

Apache-2.0

