/// Shared test helper: checks the red-black invariants of an enumeration's
/// tree and that every index in it occurs exactly once.
///
/// Copyright: 2023 - 2026 MR Research AG

import { type Tree } "../src";
import Order "mo:core/Order";
import Prim "mo:⛔";

module {
  // Walks the tree with `keyAt` (index -> key) and `compare`; traps if the
  // keys are not in order, a red node has a red child, the black height
  // differs between paths, the root is red, or an index in [0, size) is
  // missing or repeated. Returns the black height.
  public func validate<K>(tree : Tree, size : Nat, keyAt : Nat -> K, compare : (K, K) -> Order.Order) : Nat {
    let seen = Prim.Array_init<Bool>(size, false);
    func isRed(t : Tree) : Bool = switch t {
      case (?(_, w, _)) w & 1 == 1;
      case null false;
    };
    func go(t : Tree, lo : ?K, hi : ?K) : Nat {
      switch t {
        case null 0;
        case (?(l, w, r)) {
          let i = Prim.nat32ToNat(w >> 1);
          assert i < size and not seen[i];
          seen[i] := true;
          let k = keyAt(i);
          switch lo { case (?a) assert compare(a, k) == #less; case null {} };
          switch hi { case (?b) assert compare(k, b) == #less; case null {} };
          if (w & 1 == 1) assert not isRed(l) and not isRed(r);
          let bl = go(l, lo, ?k);
          assert bl == go(r, ?k, hi);
          bl + (if (w & 1 == 1) 0 else 1);
        };
      };
    };
    assert not isRed(tree);
    let h = go(tree, null, null);
    for (s in seen.values()) assert s;
    h;
  };
};
