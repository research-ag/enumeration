/// Tests for the experimental array-based enumerations in `experiment/`:
/// the same indices and lookups as `BlobEnumeration`, and valid red-black
/// invariants while growing.

import A "../experiment/ArrayEnum";
import L "../experiment/ArrayEnumLLRB";
import { BlobEnumeration } "../src";
import RNG "RNG";
import Array "mo:core/Array";
import Blob "mo:core/Blob";

let r = RNG.RNG();
let keys = Array.tabulate<Blob>(3000, func(_) = r.blob());
let more = Array.tabulate<Blob>(200, func(_) = r.blob());
let a = A.empty();
let l = L.empty();
let b = BlobEnumeration.empty();
var i = 0;
while (i < 6000) {
  let k = keys[(i * 7919) % 3000];
  let ib = b.add(k);
  assert A.add(a, k) == ib;
  assert L.add(l, k) == ib;
  if (i % 50 == 0) { ignore A.validate(a); ignore L.validate(l) };
  i += 1;
};
assert A.size(a) == b.size() and L.size(l) == b.size();
for (k in keys.values()) {
  assert A.lookup(a, k) == b.lookup(k);
  assert L.lookup(l, k) == b.lookup(k);
};
for (k in more.values()) {
  assert A.lookup(a, k) == null and L.lookup(l, k) == null;
};
