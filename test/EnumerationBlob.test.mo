/// Tests for the optimized `EnumerationBlob` module.
///
/// Copyright: 2023 - 2026 MR Research AG
///
/// Main author: Andrii Stepanov (AStepanov25)
///
/// Contributors: Timo Hanke (timohanke), Yurii Pytomets (Pitometsu)

import { EnumerationBlob } "../src";
import RNG "RNG";
import Array "mo:core/Array";
import Blob "mo:core/Blob";
import Iter "mo:core/Iter";
import { test; suite } "mo:test";

let n = 100;
let r = RNG.RNG();
let blobs = Array.tabulate<Blob>(n, func(i) = r.blob());

var i = 0;

suite(
  "EnumerationBlob",
  func() {
    test(
      "Blob",
      func() {
        let b = EnumerationBlob.empty();
        assert (b.size() == 0);
        i := 0;
        while (i < n) {
          assert (b.add(blobs[i]) == i);
          assert (b.size() == i + 1);
          i += 1;
        };

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
      },
    );

    test(
      "insert / containsKey / isEmpty",
      func() {
        let e = EnumerationBlob.empty();
        assert (e.isEmpty());
        assert (e.insert("abc") == (true, 0));
        assert (not e.isEmpty());
        assert (e.insert("aaa") == (true, 1));
        assert (e.insert("abc") == (false, 0));
        assert (e.size() == 2);
        assert (e.containsKey("abc"));
        assert (e.containsKey("aaa"));
        assert (not e.containsKey("zzz"));
      },
    );

    test(
      "range / sliceToArray",
      func() {
        let e = EnumerationBlob.empty();
        ignore e.add("abc");
        ignore e.add("aaa");
        ignore e.add("bbb");
        assert (e.sliceToArray(0, 3) == ([("abc" : Blob), ("aaa" : Blob), ("bbb" : Blob)]));
        assert (e.sliceToArray(2, 2) == ([] : [Blob]));
        assert (Iter.toArray(e.range(0, 2)) == ([("abc" : Blob), ("aaa" : Blob)]));
        assert (Iter.toArray(e.range(3, 3)) == ([] : [Blob]));
      },
    );
  },
);
