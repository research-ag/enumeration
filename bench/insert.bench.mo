// Inserting into an enumeration: N = 4096 new keys into an empty one
// (building it), and the same N keys again into the full one (all present).
import Bench "mo:bench-helper";
import Data "Data";
import Prim "mo:prim";
import { Enumeration; BlobEnumeration } "../src";
import Blob "mo:core/Blob";

module {
  public func init() : Bench.V1 {
    let rows = ["BlobEnumeration", "Enumeration<Blob>"];
    let schema : Bench.Schema = {
      name = "Insert";
      description = "N = 4096 random 32-byte keys. `new keys` adds them to an empty enumeration, `existing keys` adds them again to the full one.";
      rows;
      cols = ["new keys", "existing keys"];
    };
    let keys = Data.keys(0x5eed, Data.N);
    let blobEnum = Data.buildBlobEnum(keys);
    let genEnum = Data.buildGenEnum(keys);
    let held = Prim.Array_init<Any>(rows.size(), ());
    Bench.V1(
      schema,
      func(ri : Nat, ci : Nat) {
        switch (ri, ci) {
          case (0, 0) held[ri] := Data.buildBlobEnum(keys);
          case (1, 0) held[ri] := Data.buildGenEnum(keys);
          case (0, _) for (k in keys.values()) ignore BlobEnumeration.add(blobEnum, k);
          case (_, _) for (k in keys.values()) ignore Enumeration.add(genEnum, Blob.compare, k);
        };
      },
    );
  };
};
