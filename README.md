# Enumeration for Motoko

## Overview

`Enumeration<K>` implements an add-only set of elements of type K where the
elements are numbered in the order in which they are added to the set.
The elements are called *keys* and a key's number is called *index*.
Lookups are possible in both ways, from key to index and from 
index to key.
Memory space is `O(n)`.
Time complexities are:

* adding a key: `O(log n)` average, `O(n)` worst-case
* lookup a key: `O(log n)`
* lookup an index: `O(1)`

The data structure is optimized primarily for memory efficiency
and secondarily for instruction efficiency.
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
Per-user data is then stored in a tree or hashmap where key is the principal and the value is the user data.

The motivation of this data structure is to enumerate the users in the order that they were registered.
This result in a permanent user number for each user.
Instead of a tree, the user data can then be stored in a linear structure such as Buffer or [Vector](https://mops.one/vector) which has `O(1)` access.

To this end, the present data structure provides an "enumerated set" of keys where the key type `K` is a type parameter (e.g. `Principal`). 
The set elements (keys) are consecutively numbered 0,1,2,.. in the order in which they are added.
Keys cannot be deleted.

The lookup from a key to its number is tree based. 
However, the advantage of taking this approach is that it can be the only `O(log n)` lookup required in a canister.
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

You should have `node >= 18.16`, `moc >= 0.9.0` and `dfx` installed.
And the `DFX_MOC_PATH` variable should be set to the current `moc` location.

Then run:
```
git clone git@github.com:research-ag/enumeration.git
mops install
DFX_MOC_PATH=<path-to-moc> mops test
```

## Benchmarks

Benchmarking code can be found here: [canister-profiling](https://github.com/research-ag/canister-profiling)

We compare `Enumeration<Blob>` against various other maps of type `Blob -> Nat`. The functionality of these other maps is not exactly the same but sufficiently overlaps with Enumeration that a comparison is possible. It should be noted that the other maps don't the inverse map `Nat -> Blob` like Enumeration does. On the other hand, they offer deletion which Enumeration does not. However, the map `Blob -> Nat` is tree-based in all cases hence we can compare insertion and lookup operations both in terms of instructions and memory used.

For the memory benchmark we insert N random entries of a given type T into Enumeration.
We compare that against an array of length N with the same entries and take the difference.
This tells us the memory overhead that the data structure has over an array and eliminates the effect of boxing, which depend on type and value.
We finally divide by N to get the memory overhead per entry.

The results are as follows: 

|btree|enumeration|rb_tree|map v7|map v8|
|---|---|---|---|---|
|20.9|24|48|24*|36*|

()* Note: For reasons internal to the hashmap data structures (map v7 and v8) there is, unexpected to us, a dependency on the type. The above was measured with `Blob`. With `Nat32` the values increase to 28, 52 for v7, v8, respectively. 
And with `Nat64/Nat` they increase to 36, 52.

## Design

The underlying data structure for the map `Nat -> K` is an array that holds reserve space and is grown with an algorithm similar to Buffer.
The underlying data structure for the map `K -> Nat` is a red-black tree.
The two data structures are combined into one for memory efficiency. 
In particular, each key is stored only once, not twice.
This is particularly important if the keys are long (e.g. Principals).

## Implementation notes

The red-black tree is in fact a tree from `Nat -> Nat` 
and the comparison operation first looks up the keys from the array and then compares those.
This makes lookups by key slightly slower than in the RBTree from motoko-base (see benchmark)
but is a necessary trade-off to achieve memory efficiency.

Shrinking of the array and key deletion in the red-black tree are not implemented because Enumeration does not allow key removal. 

## Copyright

MR Research AG, 2023
## Authors

Main author: Andrii Stepanov (AStepanov25)\
Contributors: Timo Hanke (timohanke), Yurii Pytomets (Pitometsu)
## License 

Apache-2.0
