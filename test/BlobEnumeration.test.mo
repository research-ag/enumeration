/// Tests for the optimized `BlobEnumeration` module.
///
/// Plain test file: assertions run at the top level and trap on failure.
///
/// Copyright: 2023 - 2026 MR Research AG
///
/// Main author: Andrii Stepanov (AStepanov25)
///
/// Contributors: Timo Hanke (timohanke), Yurii Pytomets (Pitometsu)

import { BlobEnumeration } "../src";
import RNG "RNG";
import Array "mo:core/Array";
import Blob "mo:core/Blob";
import Iter "mo:core/Iter";

let n = 100;
let r = RNG.RNG();
let blobs = Array.tabulate<Blob>(n, func(i) = r.blob());

// add / lookup / at over many keys
do {
  let b = BlobEnumeration.empty();
  assert (b.size() == 0);

  var i = 0;
  while (i < n) {
    assert (b.add(blobs[i]) == i);
    assert (b.size() == i + 1);
    i += 1;
  };

  // re-adding returns the existing index and does not grow the enumeration
  i := 0;
  while (i < n) {
    assert (b.add(blobs[i]) == i);
    assert (b.size() == n);
    i += 1;
  };

  i := 0;
  while (i < n) {
    assert (b.lookup(blobs[i]) == ?i);
    i += 1;
  };

  // fresh keys are absent
  i := 0;
  while (i < n) {
    assert (b.lookup(r.blob()) == null);
    i += 1;
  };

  i := 0;
  while (i < n) {
    assert (b.at(i) == blobs[i]);
    i += 1;
  };
};

// insert / containsKey / isEmpty
do {
  let e = BlobEnumeration.empty();
  assert (e.isEmpty());
  assert (e.insert("abc") == (true, 0));
  assert (not e.isEmpty());
  assert (e.insert("aaa") == (true, 1));
  assert (e.insert("abc") == (false, 0));
  assert (e.size() == 2);
  assert (e.containsKey("abc"));
  assert (e.containsKey("aaa"));
  assert (not e.containsKey("zzz"));
};

// range / sliceToArray
do {
  let e = BlobEnumeration.empty();
  ignore e.add("abc");
  ignore e.add("aaa");
  ignore e.add("bbb");
  assert (e.sliceToArray(0, 3) == ([("abc" : Blob), ("aaa" : Blob), ("bbb" : Blob)]));
  assert (e.sliceToArray(2, 2) == ([] : [Blob]));
  assert (Iter.toArray(e.range(0, 2)) == ([("abc" : Blob), ("aaa" : Blob)]));
  assert (Iter.toArray(e.range(3, 3)) == ([] : [Blob]));
};
