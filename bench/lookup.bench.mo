// Instructions for 64 lookups of 32-byte keys in a structure with N = 4096
// keys: "hits" are keys in the structure, "misses" are not. Divide by 64 for
// the cost per lookup.
import Bench "mo:bench-helper";
import Data "Data";
import { Enumeration; BlobEnumeration } "../src";
import Map "mo:core/Map";
import PureMap "mo:core/pure/Map";
import HashMap "mo:map/Map";
import Blob "mo:core/Blob";

module {
  public func init() : Bench.V1 {
    let schema : Bench.Schema = {
      name = "Lookup";
      description = "Instructions for 64 lookups in a structure with N = 4096 random 32-byte keys.";
      rows = ["BlobEnumeration", "Enumeration<Blob>", "core Map (B-tree)", "core pure/Map (red-black tree)", "zhus (hash map)"];
      cols = ["hits", "misses"];
    };
    let keys = Data.keys(0x5eed, Data.N);
    let others = Data.keys(0xbeef, 64);
    let hits = Data.keys(0x5eed, 64); // the first 64 keys again, as fresh Blobs
    let be = Data.buildBlobEnum(keys);
    let ge = Data.buildGenEnum(keys);
    let bt = Data.buildBtree(keys);
    let rb = Data.buildRbtree(keys);
    let hm = Data.buildHashmap(keys);
    Bench.V1(
      schema,
      func(ri : Nat, ci : Nat) {
        let q = if (ci == 0) hits else others;
        var i = 0;
        while (i < 64) {
          let k = q[i];
          switch (ri) {
            case 0 ignore BlobEnumeration.lookup(be, k);
            case 1 ignore Enumeration.lookup(ge, Blob.compare, k);
            case 2 ignore bt.get(k);
            case 3 ignore rb.get(k);
            case _ ignore HashMap.get(hm, HashMap.bhash, k);
          };
          i += 1;
        };
      },
    );
  };
};
