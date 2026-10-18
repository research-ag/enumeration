// Experimental array-based enumerations (experiment/) vs BlobEnumeration,
// N = 4096 random 32-byte keys: build (N adds from empty), 64 lookups (hits,
// misses), and memory as the allocation of a structural copy, kept alive.
import Bench "mo:bench-helper";
import Data "Data";
import A "../experiment/ArrayEnum";
import L "../experiment/ArrayEnumLLRB";
import Enum "../src";
import Prim "mo:prim";
import VarArray "mo:core/VarArray";

module {
  func copyTree(t : Enum.Tree) : Enum.Tree = switch t {
    case null null;
    case (?(l, w, r)) ?(copyTree(l), w, copyTree(r));
  };

  public func init() : Bench.V1 {
    let rows = ["array of keys", "BlobEnumeration (node objects)", "ArrayEnum (classic red-black tree in arrays)", "ArrayEnumLLRB (left-leaning, in arrays)"];
    let schema : Bench.Schema = {
      name = "Array tree (experiment)";
      description = "N = 4096 random 32-byte keys. build: N adds from empty; hits/misses: 64 lookups; copy: memory of the structure (subtract the array of keys).";
      rows;
      cols = ["build", "hits", "misses", "copy"];
    };
    let keys = Data.keys(0x5eed, Data.N);
    let hits = Data.keys(0x5eed, 64);
    let misses = Data.keys(0xbeef, 64);
    let be = Data.buildBlobEnum(keys);
    let ae = A.empty();
    for (k in keys.values()) ignore A.add(ae, k);
    let le = L.empty();
    for (k in keys.values()) ignore L.add(le, k);
    let held = Prim.Array_init<Any>(rows.size() * 4, ());
    Bench.V1(
      schema,
      func(ri : Nat, ci : Nat) {
        let slot = ri * 4 + ci;
        if (ci == 0) {
          held[slot] := switch ri {
            case 1 Data.buildBlobEnum(keys);
            case 2 {
              let e = A.empty();
              for (k in keys.values()) ignore A.add(e, k);
              e;
            };
            case 3 {
              let e = L.empty();
              for (k in keys.values()) ignore L.add(e, k);
              e;
            };
            case _ ();
          };
          return;
        };
        if (ci == 3) {
          held[slot] := switch ri {
            case 0 Prim.Array_tabulate<Blob>(Data.N, func(i) = keys[i]);
            case 1 {
              {
                var array = be.array.clone();
                var size_ = be.size_;
                var tree = copyTree(be.tree);
              } : Enum.BlobEnumeration.BlobEnumeration;
            };
            case 2 {
              {
                var array = ae.array.clone();
                var left = ae.left.clone();
                var right = ae.right.clone();
                var size_ = ae.size_;
                var root = ae.root;
                path = ae.path.clone();
              } : A.ArrayEnum;
            };
            case 3 {
              {
                var array = le.array.clone();
                var left = le.left.clone();
                var right = le.right.clone();
                var size_ = le.size_;
                var root = le.root;
                path = le.path.clone();
              } : L.ArrayEnum;
            };
            case _ ();
          };
          return;
        };
        let q = if (ci == 1) hits else misses;
        var i = 0;
        while (i < 64) {
          switch ri {
            case 1 ignore Enum.BlobEnumeration.lookup(be, q[i]);
            case 2 ignore A.lookup(ae, q[i]);
            case 3 ignore L.lookup(le, q[i]);
            case _ {};
          };
          i += 1;
        };
      },
    );
  };
};
