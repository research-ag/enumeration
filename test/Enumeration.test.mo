/// Tests for the generic `Enumeration` module.
///
/// Plain test file: assertions run at the top level and trap on failure.
///
/// Copyright: 2023 - 2026 MR Research AG
///
/// Main author: Andrii Stepanov (AStepanov25)
///
/// Contributors: Timo Hanke (timohanke), Yurii Pytomets (Pitometsu)

import { Enumeration } "../src";
import RNG "RNG";
import Tree "Tree";
import Array "mo:core/Array";
import Iter "mo:core/Iter";
import Text "mo:core/Text";

let n = 100;
let r = RNG.RNG();
let texts = Array.tabulate<Text>(n, func(i) = r.text());

// add / lookup / at over many keys
do {
  let t = Enumeration.empty<Text>();
  assert (t.size() == 0);

  var i = 0;
  while (i < n) {
    assert (t.add(texts[i]) == i);
    assert (t.size() == i + 1);
    i += 1;
  };

  // re-adding returns the existing index and does not grow the enumeration
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

  // fresh keys are absent
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
};

// insert / containsKey / isEmpty
do {
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
};

// range / sliceToArray
do {
  let e = Enumeration.empty<Text>();
  ignore e.add("abc");
  ignore e.add("aaa");
  ignore e.add("bbb");
  assert (e.sliceToArray(0, 3) == ["abc", "aaa", "bbb"]);
  assert (e.sliceToArray(1, 3) == ["aaa", "bbb"]);
  assert (e.sliceToArray(2, 2) == []);
  assert (e.range(0, 3).toArray() == ["abc", "aaa", "bbb"]);
  assert (e.range(1, 2).toArray() == ["aaa"]);
  assert (e.range(3, 3).toArray() == []);
};

// red-black invariants while growing, with repeated keys
do {
  let keys = Array.tabulate<Text>(500, func(_) = r.text());
  let e = Enumeration.empty<Text>();
  var i = 0;
  while (i < 2000) {
    ignore e.add(keys[(i * 7) % 500]);
    if (i % 100 == 0) ignore Tree.validate(e.tree, e.size(), func(j) = e.at(j), Text.compare);
    i += 1;
  };
  assert e.size() == 500;
  ignore Tree.validate(e.tree, e.size(), func(j) = e.at(j), Text.compare);
};
