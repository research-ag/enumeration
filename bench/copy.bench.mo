// Retained memory via copies: each structure is built in `init` (with its
// build garbage); a cell makes a structural copy that shares the keys and
// keeps it. The copy allocates exactly the structure's own object graph, so
// the Heap column (allocation) is the structure's retained memory.
import Bench "mo:bench-helper";
import Data "Data";
import Enum "../src";
import Map "mo:core/Map";
import PureMap "mo:core/pure/Map";
import HashMap "mo:map/Map";
import Prim "mo:prim";
import VarArray "mo:core/VarArray";
import Types "mo:core/Types";

module {
  func copyTree(t : Enum.Tree) : Enum.Tree = switch t {
    case null null;
    case (?(l, w, r)) ?(copyTree(l), w, copyTree(r));
  };

  // Garbage-free deep copy of a core Map (B-tree): new nodes, new arrays and
  // new (key, value) tuples, keys shared; loops instead of closures.
  type BNode = Types.Map.Node<Blob, Nat>;
  type BData = Types.Map.Data<Blob, Nat>;
  func copyKvs(a : [var ?(Blob, Nat)]) : [var ?(Blob, Nat)] {
    let b = Prim.Array_init<?(Blob, Nat)>(a.size(), null);
    var i = 0;
    while (i < a.size()) {
      b[i] := switch (a[i]) { case null null; case (?(k, v)) ?(k, v) };
      i += 1;
    };
    b;
  };
  func copyData(d : BData) : BData = {
    kvs = copyKvs(d.kvs);
    var count = d.count;
  };
  func copyNode(n : BNode) : BNode = switch n {
    case (#leaf l) #leaf({ data = copyData(l.data) });
    case (#internal x) {
      let c = Prim.Array_init<?BNode>(x.children.size(), null);
      var i = 0;
      while (i < c.size()) {
        c[i] := switch (x.children[i]) {
          case null null;
          case (?ch) ?copyNode(ch);
        };
        i += 1;
      };
      #internal({ data = copyData(x.data); children = c });
    };
  };
  func copyBtree(m : Map.Map<Blob, Nat>) : Map.Map<Blob, Nat> = {
    var root = copyNode(m.root);
    var size = m.size;
  };

  public func init() : Bench.V1 {
    let rows = ["array of keys", "BlobEnumeration", "core Map (B-tree)", "core pure/Map (red-black tree)", "zhus (hash map)"];
    let schema : Bench.Schema = {
      name = "Memory";
      description = "Memory of a structure with N = 4096 random 32-byte keys, measured as the allocation of a structural copy (keys shared). Subtract the array of keys for the overhead per entry.";
      rows;
      cols = ["N = 4096"];
    };
    let keys = Data.keys(0x5eed, Data.N);
    let be = Data.buildBlobEnum(keys);
    let bt = Data.buildBtree(keys);
    let rb = Data.buildRbtree(keys);
    let hm = Data.buildHashmap(keys);
    let held = Prim.Array_init<Any>(rows.size(), ());
    Bench.V1(
      schema,
      func(ri : Nat, _ : Nat) {
        held[ri] := switch (ri) {
          case 0 Prim.Array_tabulate<Blob>(Data.N, func(i) = keys[i]);
          case 1 {
            {
              var array = be.array.clone();
              var size_ = be.size_;
              var tree = copyTree(be.tree);
            } : Enum.BlobEnumeration.BlobEnumeration;
          };
          case 2 copyBtree(bt);
          case 3 rb.map<Blob, Nat, Nat>(func(_, v) = v);
          case _ HashMap.clone(hm);
        };
      },
    );
  };
};
