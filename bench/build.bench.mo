// Building each structure from empty with N = 4096 random 32-byte keys
// (N adds). Instructions are the cost of the inserts; Heap is everything the
// build allocates, garbage included (persistent trees allocate a new path per
// insert), not the memory of the result (see copy.bench.mo).
import Bench "mo:bench-helper";
import Data "Data";
import Prim "mo:prim";

module {
  public func init() : Bench.V1 {
    let rows = ["BlobEnumeration", "Enumeration<Blob>", "core Map (B-tree)", "core pure/Map (red-black tree)", "zhus (hash map)"];
    let schema : Bench.Schema = {
      name = "Build";
      description = "N = 4096 adds of random 32-byte keys, starting from an empty structure. Heap is the total allocation of the build, garbage included.";
      rows;
      cols = ["build"];
    };
    let keys = Data.keys(0x5eed, Data.N);
    let held = Prim.Array_init<Any>(rows.size(), ());
    Bench.V1(
      schema,
      func(ri : Nat, _ : Nat) {
        held[ri] := switch (ri) {
          case 0 Data.buildBlobEnum(keys);
          case 1 Data.buildGenEnum(keys);
          case 2 Data.buildBtree(keys);
          case 3 Data.buildRbtree(keys);
          case _ Data.buildHashmap(keys);
        };
      },
    );
  };
};
