// Experiment: BlobEnumeration with a left-leaning red-black tree stored in
// arrays (Sedgewick). Superseded by ArrayEnum.mo (classic red-black tree),
// which builds faster and has a shallower tree; kept for comparison.
// Node i is key i. A node reference is index + 1 (0 = none).
//   left[i]  = (reference to the left child) << 1 | (1 if node i is red)
//   right[i] = reference to the right child
// Left-leaning red-black tree (Sedgewick), rotations in place. Insertion is
// iterative: one descent records the path, then the fixups run bottom-up.
import Prim "mo:prim";
import VarArray "mo:core/VarArray";

module {
  public type ArrayEnum = {
    var array : [var Blob];
    var left : [var Nat32];
    var right : [var Nat32];
    var size_ : Nat;
    var root : Nat32;
    path : [var Nat32]; // scratch for insertion: (reference << 1 | went right)
  };

  public func empty() : ArrayEnum = {
    var array = [var];
    var left = [var];
    var right = [var];
    var size_ = 0;
    var root = 0;
    path = Prim.Array_init<Nat32>(64, 0);
  };

  func ix(r : Nat32) : Nat = Prim.nat32ToNat(r -% 1);
  func isRed(L : [var Nat32], r : Nat32) : Bool = r != 0 and L[ix(r)] & 1 == 1;

  func rotateLeft(L : [var Nat32], R : [var Nat32], h : Nat32) : Nat32 {
    let hi = ix(h);
    let x = R[hi];
    let xi = ix(x);
    R[hi] := L[xi] >> 1; // h.right := x.left
    L[xi] := (h << 1) | (L[hi] & 1); // x.left := h, x.color := h.color
    L[hi] := L[hi] | 1; // h red
    x;
  };

  func rotateRight(L : [var Nat32], R : [var Nat32], h : Nat32) : Nat32 {
    let hi = ix(h);
    let x = L[hi] >> 1;
    let xi = ix(x);
    L[hi] := (R[xi] << 1) | 1; // h.left := x.right, h red
    R[xi] := h; // x.right := h
    L[xi] := (L[xi] & 0xffff_fffe) | (L[hi] & 0); // x.color := h.color (set below)
    x;
  };

  func fix(L : [var Nat32], R : [var Nat32], h : Nat32) : Nat32 {
    var t = h;
    var ti = ix(t);
    if (isRed(L, R[ti]) and not isRed(L, L[ti] >> 1)) {
      t := rotateLeft(L, R, t);
      ti := ix(t);
    };
    let l = L[ti] >> 1;
    if (isRed(L, l) and isRed(L, L[ix(l)] >> 1)) {
      let color = L[ti] & 1;
      t := rotateRight(L, R, t);
      ti := ix(t);
      L[ti] := (L[ti] & 0xffff_fffe) | color;
    };
    let l2 = L[ti] >> 1;
    let r2 = R[ti];
    if (isRed(L, l2) and isRed(L, r2)) {
      L[ti] := L[ti] | 1;
      L[ix(l2)] := L[ix(l2)] & 0xffff_fffe;
      L[ix(r2)] := L[ix(r2)] & 0xffff_fffe;
    };
    t;
  };

  public func lookup(self : ArrayEnum, key : Blob) : ?Nat {
    let A = self.array;
    let L = self.left;
    let R = self.right;
    var r = self.root;
    while (r != 0) {
      let i = ix(r);
      let c = Prim.blobCompare(key, A[i]);
      if (c < 0) r := L[i] >> 1 else if (c > 0) r := R[i] else return ?i;
    };
    null;
  };

  // Same capacity sequence as Enumeration (factor about sqrt(2)).
  func nextSize(n : Nat) : Nat {
    if (n == 0) return 1;
    if (n == 1) return 2;
    let m = Prim.natToNat32(n);
    let s = 30 - Prim.clzNat32(m);
    Prim.nat32ToNat(((m >> s) +% 1) << s);
  };

  public func add(self : ArrayEnum, key : Blob) : Nat {
    let path = self.path;
    var A = self.array;
    var L = self.left;
    var R = self.right;
    // Descend, recording the path; an existing key returns its index.
    var r = self.root;
    var d = 0;
    while (r != 0) {
      let i = ix(r);
      let c = Prim.blobCompare(key, A[i]);
      if (c == 0) return i;
      if (c < 0) { path[d] := r << 1; r := L[i] >> 1 } else {
        path[d] := (r << 1) | 1;
        r := R[i];
      };
      d += 1;
    };
    // Append the new node, red, without children.
    let size = self.size_;
    if (size == A.size()) {
      let cap = nextSize(size);
      let (a, l, rr) = (A, L, R);
      A := VarArray.tabulate<Blob>(cap, func(i) = if (i < size) a[i] else key);
      L := VarArray.tabulate<Nat32>(cap, func(i) = if (i < size) l[i] else 0);
      R := VarArray.tabulate<Nat32>(cap, func(i) = if (i < size) rr[i] else 0);
      self.array := A;
      self.left := L;
      self.right := R;
    };
    A[size] := key;
    L[size] := 1;
    R[size] := 0;
    self.size_ := size + 1;
    // Link it in and fix up bottom-up.
    // A level whose subtree root stays the same, keeps its color and is
    // black changes nothing above it (the parent's checks look at most at
    // this node's color, and at its left child's color only if it is red),
    // so the fixups stop there.
    var child : Nat32 = Prim.natToNat32(size + 1);
    while (d > 0) {
      d -= 1;
      let e = path[d];
      let h = e >> 1;
      let hi = ix(h);
      if (e & 1 == 0) L[hi] := (child << 1) | (L[hi] & 1) else R[hi] := child;
      let red = L[hi] & 1;
      child := fix(L, R, h);
      if (child == h and L[hi] & 1 == red and red == 0) {
        L[ix(self.root)] := L[ix(self.root)] & 0xffff_fffe; // root is black
        return size;
      };
    };
    L[ix(child)] := L[ix(child)] & 0xffff_fffe; // root is black
    self.root := child;
    size;
  };

  public func size(self : ArrayEnum) : Nat = self.size_;

  // Test helper: checks the left-leaning red-black invariants and the order;
  // returns the black height.
  public func validate(self : ArrayEnum) : Nat {
    let L = self.left;
    let R = self.right;
    func go(r : Nat32, lo : ?Blob, hi : ?Blob) : Nat {
      if (r == 0) return 0;
      let i = ix(r);
      let k = self.array[i];
      switch lo { case (?l) assert Prim.blobCompare(l, k) < 0; case null {} };
      switch hi { case (?h) assert Prim.blobCompare(k, h) < 0; case null {} };
      assert not isRed(L, R[i]); // left-leaning
      if (isRed(L, r)) assert not isRed(L, L[i] >> 1);
      let bl = go(L[i] >> 1, lo, ?k);
      let br = go(R[i], ?k, hi);
      assert bl == br;
      bl + (if (isRed(L, r)) 0 else 1);
    };
    assert not isRed(L, self.root);
    go(self.root, null, null);
  };
};
