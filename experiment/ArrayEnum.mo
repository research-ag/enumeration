// Experiment: BlobEnumeration with a classic red-black tree stored in
// arrays (CLRS insertion, bottom-up fixup along the recorded path).
// Node i is key i. A node reference is index + 1 (0 = none).
//   left[i]  = (reference to the left child) << 1 | (1 if node i is red)
//   right[i] = reference to the right child
import Prim "mo:prim";
import VarArray "mo:core/VarArray";

module {
  public type ArrayEnum = {
    var array : [var Blob];
    var left : [var Nat32];
    var right : [var Nat32];
    var size_ : Nat;
    var root : Nat32;
    path : [var Nat32]; // scratch for insertion: the ancestors of the new node
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
  func leftOf(L : [var Nat32], r : Nat32) : Nat32 = L[ix(r)] >> 1;
  func setLeft(L : [var Nat32], r : Nat32, c : Nat32) {
    let i = ix(r);
    L[i] := (c << 1) | (L[i] & 1);
  };
  func setRed(L : [var Nat32], r : Nat32) { let i = ix(r); L[i] := L[i] | 1 };
  func setBlack(L : [var Nat32], r : Nat32) {
    let i = ix(r);
    L[i] := L[i] & 0xffff_fffe;
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

  func nextSize(n : Nat) : Nat {
    if (n == 0) return 1;
    if (n == 1) return 2;
    let m = Prim.natToNat32(n);
    let s = 30 - Prim.clzNat32(m);
    Prim.nat32ToNat(((m >> s) +% 1) << s);
  };

  // Replace the child `old` of the node at path[k] (or the root if k < 0) by `new`.
  func relink(self : ArrayEnum, L : [var Nat32], R : [var Nat32], k : Int, old : Nat32, new : Nat32) {
    if (k < 0) { self.root := new; return };
    let gg = self.path[Prim.abs(k)];
    if (leftOf(L, gg) == old) setLeft(L, gg, new) else R[ix(gg)] := new;
  };

  public func add(self : ArrayEnum, key : Blob) : Nat {
    let path = self.path;
    var A = self.array;
    var L = self.left;
    var R = self.right;
    var r = self.root;
    var d = 0;
    var c : Int8 = 0;
    while (r != 0) {
      let i = ix(r);
      c := Prim.blobCompare(key, A[i]);
      if (c == 0) return i;
      path[d] := r;
      d += 1;
      r := if (c < 0) L[i] >> 1 else R[i];
    };
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
    L[size] := 1; // red, no children
    R[size] := 0;
    self.size_ := size + 1;
    let n = Prim.natToNat32(size + 1);
    if (d == 0) {
      self.root := n;
      setBlack(L, n);
      return size;
    };
    let parent = path[d - 1];
    if (c < 0) setLeft(L, parent, n) else R[ix(parent)] := n;
    // Fixup. z is at path position k (path[k] = z for k < d; z = n for k = d).
    var z = n;
    var k = d;
    label fix while (k >= 1 and isRed(L, path[k - 1])) {
      let p = path[k - 1];
      let g = path[k - 2]; // p is red, so it is not the root
      if (p == leftOf(L, g)) {
        let u = R[ix(g)];
        if (isRed(L, u)) {
          setBlack(L, p);
          setBlack(L, u);
          setRed(L, g);
          z := g;
          k -= 2;
        } else {
          var top = p;
          if (z == R[ix(p)]) {
            // rotate left at p
            R[ix(p)] := leftOf(L, z);
            setLeft(L, z, p);
            setLeft(L, g, z);
            top := z;
          };
          // rotate right at g
          setLeft(L, g, R[ix(top)]);
          R[ix(top)] := g;
          setBlack(L, top);
          setRed(L, g);
          relink(self, L, R, k - 3, g, top);
          break fix;
        };
      } else {
        let u = leftOf(L, g);
        if (isRed(L, u)) {
          setBlack(L, p);
          setBlack(L, u);
          setRed(L, g);
          z := g;
          k -= 2;
        } else {
          var top = p;
          if (z == leftOf(L, p)) {
            // rotate right at p
            setLeft(L, p, R[ix(z)]);
            R[ix(z)] := p;
            R[ix(g)] := z;
            top := z;
          };
          // rotate left at g
          R[ix(g)] := leftOf(L, top);
          setLeft(L, top, g);
          setBlack(L, top);
          setRed(L, g);
          relink(self, L, R, k - 3, g, top);
          break fix;
        };
      };
    };
    setBlack(L, self.root);
    size;
  };

  public func size(self : ArrayEnum) : Nat = self.size_;

  // Test helper: red-black invariants and order; returns the black height.
  public func validate(self : ArrayEnum) : Nat {
    let L = self.left;
    let R = self.right;
    func go(r : Nat32, lo : ?Blob, hi : ?Blob) : Nat {
      if (r == 0) return 0;
      let i = ix(r);
      let k = self.array[i];
      switch lo { case (?l) assert Prim.blobCompare(l, k) < 0; case null {} };
      switch hi { case (?h) assert Prim.blobCompare(k, h) < 0; case null {} };
      if (isRed(L, r)) assert not isRed(L, L[i] >> 1) and not isRed(L, R[i]);
      let bl = go(L[i] >> 1, lo, ?k);
      assert bl == go(R[i], ?k, hi);
      bl + (if (isRed(L, r)) 0 else 1);
    };
    assert not isRed(L, self.root);
    go(self.root, null, null);
  };
};
