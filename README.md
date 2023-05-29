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

Enumeration of `K`s in order they are added, i.e. bidirectional map from `K` to number it was added, and inverse.

### Interface

## Usage

### Install with mops

You need `mops` installed. In your project directory run:
```
mops add enumeration
```

In the Motoko source file import the package as one of:
```
import Enumeration "mo:enumeration";
```

### Example

### Build & test

You need `moc` and `wasmtime` installed.
Then run:
```
git clone git@github.com:research-ag/enumeration.git
make -C test
```

## Benchmarks

The benchmarking code can be found here: [canister-profiling](https://github.com/research-ag/canister-profiling)

### Time

### Memory

## Design

## Implementation notes

## Copyright

MR Research AG, 2023
## Authors

## License 

Apache-2.0
