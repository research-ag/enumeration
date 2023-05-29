# Enumeration for Motoko

## Overview

Motoko general purpose libraries

See documentation here: https://research-ag.github.io/enumeration/

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
This gives each user a user number.
The user data can then be stored in a Buffer or Vector instead of a tree where lookup by user number is fast.

To this end, this data structure provides a bi-directional map from the parametrized key type `K` (e.g. `Principal`) to `Nat` (e.g. user number).
The `Nat`s are consecutively numbered and assigned to the keys in the order that the keys are entered into the map ("enumerated").
Keys can never be deleted from the map.

Advantages of this approach are:

* all tree-based lookups happening in the canister can be reduced to this one optimized data structure
* all subsequent lookups can be made fast if based on user number

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

### Build & test

You need `moc` and `wasmtime` installed.
Then run:
```
git clone git@github.com:research-ag/enumeration.git
mops install
mops test
```

## Benchmarks

Benchmarking code can be found here: [canister-profiling](https://github.com/research-ag/canister-profiling)

## Design

The underlying data structure for the map `Nat -> K` is an array that holds reserve space and is grown with an algorithm similar to Buffer.
The underlying data structure for the map `K -> Nat` is a red-black tree.
The two data structures are combined into one for memory efficiency. 
In particular, each key is stored only once, not twice.

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
