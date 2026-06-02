/// `Enumeration<K>` is a "set enumeration" of elements of type `K` called "keys".
///
/// A typical application is to assign permanent user numbers to principals.
///
/// The data structure is a map `Nat -> K` with the following properties:
/// * keys are not repeated, i.e. the map is injective
/// * keys are consecutively numbered (no gaps), i.e. if n keys are stored
///   then `[0,n) -> K` is bijective
/// * keys are numbered in the order they are added to the data structure
/// * keys cannot be deleted
/// * efficient inverse lookup `K -> Nat`
/// * doubles as a set implementation (without deletion)
///
/// The data structure is optimized primarily for memory efficiency
/// and secondarily for instruction efficiency.
///
/// Copyright: 2023 - 2026 MR Research AG
/// Main author: Andrii Stepanov (AStepanov25)
/// Contributors: Timo Hanke (timohanke), Yurii Pytomets (Pitometsu)

import Array "mo:core/Array";
import Blob "mo:core/Blob";
import Iter "mo:core/Iter";
import Nat32 "mo:core/Nat32";
import Order "mo:core/Order";
import Prim "mo:⛔";
import Runtime "mo:core/Runtime";
import VarArray "mo:core/VarArray";

module {
  /// A red-black tree node. The `Nat` payload is not a key but an *index* into
  /// the key array; comparisons during tree operations dereference the array.
  /// `null` is the empty tree (also used for leaves).
  public type Tree = ?({ #R; #B }, Tree, Nat, Tree);

  // ── Red-black tree / array-growth helpers shared by both modules ──

  // Rebalances a subtree after an insertion into its left child
  // (standard Okasaki red-black tree balancing).
  func lbalance(left : Tree, y : Nat, right : Tree) : Tree {
    switch (left, right) {
      case (?(#R, ?(#R, l1, y1, r1), y2, r2), r) ?(#R, ?(#B, l1, y1, r1), y2, ?(#B, r2, y, r));
      case (?(#R, l1, y1, ?(#R, l2, y2, r2)), r) ?(#R, ?(#B, l1, y1, l2), y2, ?(#B, r2, y, r));
      case _ ?(#B, left, y, right);
    };
  };

  // Rebalances a subtree after an insertion into its right child (mirror of `lbalance`).
  func rbalance(left : Tree, y : Nat, right : Tree) : Tree {
    switch (left, right) {
      case (l, ?(#R, l1, y1, ?(#R, l2, y2, r2))) ?(#R, ?(#B, l, y, l1), y1, ?(#B, l2, y2, r2));
      case (l, ?(#R, ?(#R, l1, y1, r1), y2, r2)) ?(#R, ?(#B, l, y, l1), y1, ?(#B, r1, y2, r2));
      case _ ?(#B, left, y, right);
    };
  };

  // Returns the next array capacity, growing the current size `n_` by a factor
  // of roughly sqrt(2) and rounding to a multiple of a power of two.
  // Traps if n_ == 0 or n_ >= 3 * 2 ** 30 (see inline assertions below).
  func next_size(n_ : Nat) : Nat {
    if (n_ == 1) return 2;
    let n = Nat32.fromNat(n_); // traps if n >= 2 ** 32
    let s = 30 - Nat32.bitcountLeadingZero(n); // traps if n == 0
    let m = ((n >> s) +% 1) << s;
    assert (m != 0); // traps if n >= 3 * 2 ** 30
    Nat32.toNat(m);
  };

  /// Bidirectional enumeration of keys of type `K` in the order they are added.
  /// The map from `K` to index `Nat` is implemented as a red-black tree;
  /// the map from index `Nat` to `K` is implemented as an array.
  ///
  /// Example:
  /// ```motoko
  /// let e = Enumeration.empty<Text>();
  /// ```
  public module Enumeration {
    /// The enumeration state. It consists only of stable types, so a value can
    /// be stored directly in a `stable` variable. The fields are an
    /// implementation detail; operate on it through the functions below.
    public type Enumeration<K> = {
      var array : [var K];
      var size_ : Nat;
      var tree : Tree;
    };

    /// Creates a new, empty enumeration.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Text>();
    /// ```
    /// Runtime: O(1)
    public func empty<K>() : Enumeration<K> {
      {
        var array = [var] : [var K];
        var size_ = 0;
        var tree = (null : Tree);
      };
    };

    /// Add `key` to the enumeration and return `(isNew, index)`, where `isNew`
    /// is `true` if the key was not present before (and has now been appended
    /// at a new `index`), or `false` if it was already present (and `index` is
    /// its existing index). The key is never stored twice.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Text>();
    /// assert(e.insert("abc") == (true, 0));
    /// assert(e.insert("aaa") == (true, 1));
    /// assert(e.insert("abc") == (false, 0));
    /// ```
    /// Runtime: O(log(n))
    public func insert<K>(self : Enumeration<K>, compare : (implicit : (K, K) -> Order.Order), key : K) : (Bool, Nat) {
      let array = self.array;
      let size = self.size_;

      var index = size;

      func ins(tree : Tree) : Tree {
        switch tree {
          case (?(#B, left, y, right)) {
            switch (compare(key, array[y])) {
              case (#less) lbalance(ins(left), y, right);
              case (#greater) rbalance(left, y, ins(right));
              case (#equal) {
                index := y;
                tree;
              };
            };
          };
          case (?(#R, left, y, right)) {
            switch (compare(key, array[y])) {
              case (#less) ?(#R, ins(left), y, right);
              case (#greater) ?(#R, left, y, ins(right));
              case (#equal) {
                index := y;
                tree;
              };
            };
          };
          case (null) {
            index := size;
            ?(#R, null, size, null);
          };
        };
      };

      self.tree := switch (ins(self.tree)) {
        case (?(#R, left, y, right)) ?(#B, left, y, right);
        case other other;
      };

      if (index == size) {
        if (size == array.size()) {
          // Reserve slots need to hold some valid `K`; they are never read
          // (`at`/`get` are bounds-checked against `size_`). We reuse the first
          // stored key `array[0]`, except on the very first insertion when no
          // element exists yet, where we use `key` itself.
          let filler = if (size == 0) key else array[0];
          self.array := VarArray.tabulate<K>(if (size == 0) 1 else next_size(size), func(i) = if (i < size) { array[i] } else { filler });
        };
        self.array[index] := key;
        self.size_ += 1;
      };

      (index == size, index);
    };

    /// Add `key` to the enumeration and return its index: a new index (equal to
    /// the previous `size`) if the key is new, or its existing index if it was
    /// already present. Use `insert` if you also need to know whether the key was new.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Text>();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.add("abc") == 0);
    /// ```
    /// Runtime: O(log(n))
    public func add<K>(self : Enumeration<K>, compare : (implicit : (K, K) -> Order.Order), key : K) : Nat = insert(self, compare, key).1;

    /// Returns `?index`, where `index` is the position of `key` in the order it was added, or `null` if `key` is not present.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Text>();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.lookup("abc") == ?0);
    /// assert(e.lookup("aaa") == ?1);
    /// assert(e.lookup("bbb") == null);
    /// ```
    /// Runtime: O(log(n))
    public func lookup<K>(self : Enumeration<K>, compare : (implicit : (K, K) -> Order.Order), key : K) : ?Nat {
      let array = self.array;

      func get_in_tree(x : K, t : Tree) : ?Nat {
        switch t {
          case (?(_, l, y, r)) {
            switch (compare(x, array[y])) {
              case (#less) get_in_tree(x, l);
              case (#equal) ?y;
              case (#greater) get_in_tree(x, r);
            };
          };
          case (null) null;
        };
      };

      get_in_tree(key, self.tree);
    };

    /// Returns `true` if `key` is present in the enumeration, `false` otherwise.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Text>();
    /// assert(e.add("abc") == 0);
    /// assert(e.containsKey("abc"));
    /// assert(not e.containsKey("bbb"));
    /// ```
    /// Runtime: O(log(n))
    public func containsKey<K>(self : Enumeration<K>, compare : (implicit : (K, K) -> Order.Order), key : K) : Bool {
      switch (lookup(self, compare, key)) {
        case (?_) true;
        case null false;
      };
    };

    /// Returns the key at index `index`.
    /// Traps if `index >= size`.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Text>();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.at(0) == "abc");
    /// assert(e.at(1) == "aaa");
    /// ```
    /// Runtime: O(1)
    public func at<K>(self : Enumeration<K>, index : Nat) : K {
      if (index < self.size_) { self.array[index] } else {
        Runtime.trap("Index out of bounds");
      };
    };

    /// Returns the key at index `index` as an option, or `null` when `index >= size`.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Text>();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.get(0) == ?"abc");
    /// assert(e.get(1) == ?"aaa");
    /// assert(e.get(2) == null);
    /// ```
    /// Runtime: O(1)
    public func get<K>(self : Enumeration<K>, index : Nat) : ?K {
      if (index < self.size_) { ?self.array[index] } else {
        null;
      };
    };

    /// Returns the number of keys in the enumeration.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Text>();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.size() == 2);
    /// ```
    /// Runtime: O(1)
    public func size<K>(self : Enumeration<K>) : Nat = self.size_;

    /// Returns `true` if the enumeration is empty, `false` otherwise.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Text>();
    /// assert(e.isEmpty());
    /// assert(e.add("abc") == 0);
    /// assert(not e.isEmpty());
    /// ```
    /// Runtime: O(1)
    public func isEmpty<K>(self : Enumeration<K>) : Bool = self.size_ == 0;

    /// Returns the keys in index range `[left, right)` as a lazy iterator,
    /// in the order they were added. Traps if `right > size` or `left > right`.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Text>();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.add("bbb") == 2);
    /// assert(Iter.toArray(e.range(1, 3)) == ["aaa", "bbb"]);
    /// ```
    /// Runtime: O(1) per `next` call.
    public func range<K>(self : Enumeration<K>, left : Nat, right : Nat) : Iter.Iter<K> {
      assert left <= right and right <= self.size_;
      let array = self.array;
      var i = left;
      {
        next = func() : ?K {
          if (i >= right) return null;
          let x = array[i];
          i += 1;
          ?x;
        };
      };
    };

    /// Returns the keys in index range `[left, right)` as an array, in the
    /// order they were added. Traps if `right > size` or `left > right`.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Text>();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.add("bbb") == 2);
    /// assert(e.sliceToArray(0, 2) == ["abc", "aaa"]);
    /// ```
    /// Runtime: O(right - left)
    public func sliceToArray<K>(self : Enumeration<K>, left : Nat, right : Nat) : [K] {
      assert left <= right and right <= self.size_;
      let array = self.array;
      Array.tabulate<K>(right - left, func(i) = array[left + i]);
    };
  };

  /// A performance-optimized version of `Enumeration<Blob>`.
  ///
  /// It is functionally equivalent to `Enumeration.empty<Blob>()` used with
  /// `Blob.compare`, but faster: the red-black tree comparisons use the
  /// primitive `Prim.blobCompare` instead of `Blob.compare`. Prefer this
  /// module whenever the keys are `Blob`s.
  public module BlobEnumeration {
    /// The enumeration state. It consists only of stable types, so a value can
    /// be stored directly in a `stable` variable. The fields are an
    /// implementation detail; operate on it through the functions below.
    public type BlobEnumeration = {
      var array : [var Blob];
      var size_ : Nat;
      var tree : Tree;
    };

    /// Creates a new, empty enumeration.
    ///
    /// Example:
    /// ```motoko
    /// let e = BlobEnumeration.empty();
    /// ```
    /// Runtime: O(1)
    public func empty() : BlobEnumeration {
      {
        var array = [var ""];
        var size_ = 0;
        var tree = (null : Tree);
      };
    };

    /// Add `key` to the enumeration and return `(isNew, index)`, where `isNew`
    /// is `true` if the key was not present before (and has now been appended
    /// at a new `index`), or `false` if it was already present (and `index` is
    /// its existing index). The key is never stored twice.
    ///
    /// Example:
    /// ```motoko
    /// let e = BlobEnumeration.empty();
    /// assert(e.insert("abc") == (true, 0));
    /// assert(e.insert("aaa") == (true, 1));
    /// assert(e.insert("abc") == (false, 0));
    /// ```
    /// Runtime: O(log(n))
    public func insert(self : BlobEnumeration, key : Blob) : (Bool, Nat) {
      let array = self.array;
      let size = self.size_;

      var index = size;

      func ins(tree : Tree) : Tree {
        switch tree {
          case (?(#B, left, y, right)) {
            let res = Prim.blobCompare(key, array[y]);
            if (res < 0) {
              lbalance(ins(left), y, right);
            } else if (res > 0) {
              rbalance(left, y, ins(right));
            } else {
              index := y;
              tree;
            };
          };
          case (?(#R, left, y, right)) {
            let res = Prim.blobCompare(key, array[y]);
            if (res < 0) {
              ?(#R, ins(left), y, right);
            } else if (res > 0) {
              ?(#R, left, y, ins(right));
            } else {
              index := y;
              tree;
            };
          };
          case (null) {
            index := size;
            ?(#R, null, size, null);
          };
        };
      };

      self.tree := switch (ins(self.tree)) {
        case (?(#R, left, y, right)) ?(#B, left, y, right);
        case other other;
      };

      if (index == size) {
        if (size == array.size()) {
          self.array := VarArray.tabulate<Blob>(next_size(size), func(i) = if (i < size) { array[i] } else { "" });
        };
        self.array[index] := key;
        self.size_ += 1;
      };

      (index == size, index);
    };

    /// Add `key` to the enumeration and return its index: a new index (equal to
    /// the previous `size`) if the key is new, or its existing index if it was
    /// already present. Use `insert` if you also need to know whether the key was new.
    ///
    /// Example:
    /// ```motoko
    /// let e = BlobEnumeration.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.add("abc") == 0);
    /// ```
    /// Runtime: O(log(n))
    public func add(self : BlobEnumeration, key : Blob) : Nat = insert(self, key).1;

    /// Returns `?index`, where `index` is the position of `key` in the order it was added, or `null` if `key` is not present.
    ///
    /// Example:
    /// ```motoko
    /// let e = BlobEnumeration.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.lookup("abc") == ?0);
    /// assert(e.lookup("aaa") == ?1);
    /// assert(e.lookup("bbb") == null);
    /// ```
    /// Runtime: O(log(n))
    public func lookup(self : BlobEnumeration, key : Blob) : ?Nat {
      let array = self.array;

      func get_in_tree(x : Blob, t : Tree) : ?Nat {
        switch t {
          case (?(_, l, y, r)) {
            let res = Prim.blobCompare(x, array[y]);
            if (res < 0) {
              get_in_tree(x, l);
            } else if (res > 0) {
              get_in_tree(x, r);
            } else {
              ?y;
            };
          };
          case (null) null;
        };
      };

      get_in_tree(key, self.tree);
    };

    /// Returns `true` if `key` is present in the enumeration, `false` otherwise.
    ///
    /// Example:
    /// ```motoko
    /// let e = BlobEnumeration.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.containsKey("abc"));
    /// assert(not e.containsKey("bbb"));
    /// ```
    /// Runtime: O(log(n))
    public func containsKey(self : BlobEnumeration, key : Blob) : Bool {
      switch (lookup(self, key)) {
        case (?_) true;
        case null false;
      };
    };

    /// Returns the key at index `index`.
    /// Traps if `index >= size`.
    ///
    /// Example:
    /// ```motoko
    /// let e = BlobEnumeration.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.at(0) == "abc");
    /// assert(e.at(1) == "aaa");
    /// ```
    /// Runtime: O(1)
    public func at(self : BlobEnumeration, index : Nat) : Blob {
      if (index < self.size_) { self.array[index] } else {
        Runtime.trap("Index out of bounds");
      };
    };

    /// Returns the key at index `index` as an option, or `null` when `index >= size`.
    ///
    /// Example:
    /// ```motoko
    /// let e = BlobEnumeration.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.get(0) == ?"abc");
    /// assert(e.get(1) == ?"aaa");
    /// assert(e.get(2) == null);
    /// ```
    /// Runtime: O(1)
    public func get(self : BlobEnumeration, index : Nat) : ?Blob {
      if (index < self.size_) { ?self.array[index] } else {
        null;
      };
    };

    /// Returns the number of keys in the enumeration.
    ///
    /// Example:
    /// ```motoko
    /// let e = BlobEnumeration.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.size() == 2);
    /// ```
    /// Runtime: O(1)
    public func size(self : BlobEnumeration) : Nat = self.size_;

    /// Returns `true` if the enumeration is empty, `false` otherwise.
    ///
    /// Example:
    /// ```motoko
    /// let e = BlobEnumeration.empty();
    /// assert(e.isEmpty());
    /// assert(e.add("abc") == 0);
    /// assert(not e.isEmpty());
    /// ```
    /// Runtime: O(1)
    public func isEmpty(self : BlobEnumeration) : Bool = self.size_ == 0;

    /// Returns the keys in index range `[left, right)` as a lazy iterator,
    /// in the order they were added. Traps if `right > size` or `left > right`.
    ///
    /// Example:
    /// ```motoko
    /// let e = BlobEnumeration.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.add("bbb") == 2);
    /// assert(Iter.toArray(e.range(1, 3)) == ["aaa", "bbb"]);
    /// ```
    /// Runtime: O(1) per `next` call.
    public func range(self : BlobEnumeration, left : Nat, right : Nat) : Iter.Iter<Blob> {
      assert left <= right and right <= self.size_;
      let array = self.array;
      var i = left;
      {
        next = func() : ?Blob {
          if (i >= right) return null;
          let x = array[i];
          i += 1;
          ?x;
        };
      };
    };

    /// Returns the keys in index range `[left, right)` as an array, in the
    /// order they were added. Traps if `right > size` or `left > right`.
    ///
    /// Example:
    /// ```motoko
    /// let e = BlobEnumeration.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.add("bbb") == 2);
    /// assert(e.sliceToArray(0, 2) == ["abc", "aaa"]);
    /// ```
    /// Runtime: O(right - left)
    public func sliceToArray(self : BlobEnumeration, left : Nat, right : Nat) : [Blob] {
      assert left <= right and right <= self.size_;
      let array = self.array;
      Array.tabulate<Blob>(right - left, func(i) = array[left + i]);
    };
  };
};
