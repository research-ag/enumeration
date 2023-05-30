# Enumeration for Motoko

## Overview

`Enumeration<K>` implements an add-only set of elements of type K where the
elements are numbered in the order in which they are added to the set.
The elements are called *keys* and a key's number is called *index*.
Lookups are possible in both ways, from key to index and from 
index to key.
Running times are:

* adding a key: `O(log n)`
* lookup a key: `O(log n)`
* lookup an index: `O(1)`

The data structure is optimized primarily for memory efficiency
and secondarily for instruction efficiency.

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

For the benchmark we insert 4,096 entries type Blob of size 29 bytes to represent a Principal. The results are as follows:

|method|heap size|gc size|collector instructions|mutator instructions|
|---|---|---|---|---|
|enumeration|278,768|171,629,676|4,349,893|3,472,737,984|
|map v7|327,772|170,031,220|4,832,131|3,456,238,067|
|map v8|393,324|169,653,956|7,224,268|3,454,631,268|
|rb_tree|377,172|172,176,312|7,690,532|3,471,603,610|

If we divide the heap size by 4,096 and subtract 40 bytes for the actual data of the stored Blob then we get the per-item memory overhead of the respective data structure. The results are:

|enumeration|map v7|map v8|rb_tree|
|---|---|---|---|
|28|40|56|52|

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
