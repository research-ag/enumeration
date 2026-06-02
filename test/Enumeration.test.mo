/// Tests for the generic `Enumeration` module.
///
/// Copyright: 2023 - 2026 MR Research AG
///
/// Main author: Andrii Stepanov (AStepanov25)
///
/// Contributors: Timo Hanke (timohanke), Yurii Pytomets (Pitometsu)

import { Enumeration } "../src";
import RNG "RNG";
import Array "mo:core/Array";
import Iter "mo:core/Iter";
import Text "mo:core/Text";
import { test; suite } "mo:test";

let n = 100;
let r = RNG.RNG();
let t = Enumeration.empty<Text>();
let texts = Array.tabulate<Text>(n, func(i) = r.text());

var i = 0;

suite(
  "Enumeration",
  func() {
    test(
      "Text",
      func() {
        assert (t.size() == 0);
        i := 0;
        while (i < n) {
          assert (t.add(texts[i]) == i);
          assert (t.size() == i + 1);
          i += 1;
        };

        i := 0;
        while (i < n) {
          assert (t.add(texts[i]) == i);
          assert (t.size() == n);
          i += 1;
        };

        i := 0;
        while (i < n) {
          assert (t.lookup(texts[i]) == ?i);
          i += 1;
        };

        i := 0;
        while (i < n) {
          assert (t.lookup(r.text()) == null);
          i += 1;
        };

        i := 0;
        while (i < n) {
          assert (t.at(i) == texts[i]);
          i += 1;
        };
      },
    );

    test(
      "insert / containsKey / isEmpty",
      func() {
        let e = Enumeration.empty<Text>();
        assert (e.isEmpty());
        assert (e.insert("abc") == (true, 0));
        assert (not e.isEmpty());
        assert (e.insert("aaa") == (true, 1));
        assert (e.insert("abc") == (false, 0));
        assert (e.size() == 2);
        assert (e.containsKey("abc"));
        assert (e.containsKey("aaa"));
        assert (not e.containsKey("bbb"));
      },
    );

    test(
      "range / sliceToArray",
      func() {
        let e = Enumeration.empty<Text>();
        ignore e.add("abc");
        ignore e.add("aaa");
        ignore e.add("bbb");
        assert (e.sliceToArray(0, 3) == ["abc", "aaa", "bbb"]);
        assert (e.sliceToArray(1, 3) == ["aaa", "bbb"]);
        assert (e.sliceToArray(2, 2) == []);
        assert (Iter.toArray(e.range(0, 3)) == ["abc", "aaa", "bbb"]);
        assert (Iter.toArray(e.range(1, 2)) == ["aaa"]);
        assert (Iter.toArray(e.range(3, 3)) == []);
      },
    );
  },
);
