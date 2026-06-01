/// `Enumeration<K>` is a "set enumeration" of elements of type `K` called "keys".
///
/// A typical application is to assign permanent user numbers to princpals.
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

import Blob "mo:core/Blob";
import Nat32 "mo:core/Nat32";
import Order "mo:core/Order";
import Prim "mo:⛔";
import Runtime "mo:core/Runtime";
import VarArray "mo:core/VarArray";

module {
  /// Red-black tree of key `Nat`.
  public type Tree = ?({ #R; #B }, Tree, Nat, Tree);

  /// Common functions between both classes
  func lbalance(left : Tree, y : Nat, right : Tree) : Tree {
    switch (left, right) {
      case (?(#R, ?(#R, l1, y1, r1), y2, r2), r) ?(#R, ?(#B, l1, y1, r1), y2, ?(#B, r2, y, r));
      case (?(#R, l1, y1, ?(#R, l2, y2, r2)), r) ?(#R, ?(#B, l1, y1, l2), y2, ?(#B, r2, y, r));
      case _ ?(#B, left, y, right);
    };
  };

  func rbalance(left : Tree, y : Nat, right : Tree) : Tree {
    switch (left, right) {
      case (l, ?(#R, l1, y1, ?(#R, l2, y2, r2))) ?(#R, ?(#B, l, y, l1), y1, ?(#B, l2, y2, r2));
      case (l, ?(#R, ?(#R, l1, y1, r1), y2, r2)) ?(#R, ?(#B, l, y, l1), y1, ?(#B, r1, y2, r2));
      case _ ?(#B, left, y, right);
    };
  };

  // approximate growth by sqrt(2) by 2-powers
  // the function will trap if n == 0 or n >= 3 * 2 ** 30
  func next_size(n_ : Nat) : Nat {
    if (n_ == 1) return 2;
    let n = Nat32.fromNat(n_); // traps if n >= 2 ** 32
    let s = 30 - Nat32.bitcountLeadingZero(n); // traps if n == 0
    let m = ((n >> s) +% 1) << s;
    assert (m != 0); // traps if n >= 3 * 2 ** 30
    Nat32.toNat(m);
  };

  /// Bidirectional enumeration of any `K` s in the order they are added.
  /// For a map from `K` to index `Nat` it is implemented as red-black tree,
  /// for a map from index `Nat` to `K` the implementation is an array.
  ///
  /// Example:
  /// ```motoko
  /// let e = Enumeration.empty<Blob>("");
  /// ```
  public module Enumeration {
    public type Enumeration<K> = {
      var array : [var K];
      var size_ : Nat;
      var tree : Tree;
      empty : K;
    };

    public func empty<K>(empty : K) : Enumeration<K> {
      {
        var array = [var empty];
        var size_ = 0;
        var tree = (null : Tree);
        empty;
      };
    };

    /// Add `key` to enumeration. Returns `size` if the key is new to the enumeration and index of key in enumeration otherwise.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Blob>("");
    /// assert(e.add("abc", Blob.compare) == 0);
    /// assert(e.add("aaa", Blob.compare) == 1);
    /// assert(e.add("abc", Blob.compare) == 0);
    /// ```
    /// Runtime: O(log(n))
    public func add<K>(self : Enumeration<K>, key : K, compare : (implicit : (K, K) -> Order.Order)) : Nat {
      var index = self.size_;

      func insert(tree : Tree) : Tree {
        switch tree {
          case (?(#B, left, y, right)) {
            switch (compare(key, self.array[y])) {
              case (#less) lbalance(insert(left), y, right);
              case (#greater) rbalance(left, y, insert(right));
              case (#equal) {
                index := y;
                tree;
              };
            };
          };
          case (?(#R, left, y, right)) {
            switch (compare(key, self.array[y])) {
              case (#less) ?(#R, insert(left), y, right);
              case (#greater) ?(#R, left, y, insert(right));
              case (#equal) {
                index := y;
                tree;
              };
            };
          };
          case (null) {
            index := self.size_;
            ?(#R, null, self.size_, null);
          };
        };
      };

      self.tree := switch (insert(self.tree)) {
        case (?(#R, left, y, right)) ?(#B, left, y, right);
        case other other;
      };

      if (index == self.size_) {
        if (self.size_ == self.array.size()) {
          self.array := VarArray.tabulate<K>(next_size(self.size_), func(i) = if (i < self.size_) { self.array[i] } else { self.empty });
        };
        self.array[self.size_] := key;
        self.size_ += 1;
      };

      index;
    };

    /// Returns `?index` where `index` is the index of `key` in order it was added to enumeration, or `null` it `key` wasn't added.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Blob>("");
    /// assert(e.add("abc", Blob.compare) == 0);
    /// assert(e.add("aaa", Blob.compare) == 1);
    /// assert(e.lookup("abc", Blob.compare) == ?0);
    /// assert(e.lookup("aaa", Blob.compare) == ?1);
    /// assert(e.lookup("bbb", Blob.compare) == null);
    /// ```
    /// Runtime: O(log(n))
    public func lookup<K>(self : Enumeration<K>, key : K, compare : (implicit : (K, K) -> Order.Order)) : ?Nat {
      func get_in_tree(x : K, t : Tree) : ?Nat {
        switch t {
          case (?(_, l, y, r)) {
            switch (compare(x, self.array[y])) {
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

    /// Returns `K` with index `index`.
    /// Traps if `index >= size`.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Blob>("");
    /// assert(e.add("abc", Blob.compare) == 0);
    /// assert(e.add("aaa", Blob.compare) == 1);
    /// assert(e.at(0) == "abc");
    /// assert(e.at(1) == "aaa");
    /// ```
    /// Runtime: O(1)
    public func at<K>(self : Enumeration<K>, index : Nat) : K {
      if (index < self.size_) { self.array[index] } else {
        Runtime.trap("Index out of bounds");
      };
    };

    /// Returns `K` with index `index` as an option.
    /// Returns `null` when `index >= size`.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Blob>("");
    /// assert(e.add("abc", Blob.compare) == 0);
    /// assert(e.add("aaa", Blob.compare) == 1);
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

    /// Returns number of unique keys added to enumeration.
    ///
    /// Example:
    /// ```motoko
    /// let e = Enumeration.empty<Blob>("");
    /// assert(e.add("abc", Blob.compare) == 0);
    /// assert(e.add("aaa", Blob.compare) == 1);
    /// assert(e.size() == 2);
    /// ```
    /// Runtime: O(1)
    public func size<K>(self : Enumeration<K>) : Nat = self.size_;
  };

  /// An optimized version of Enumeration<Blob>
  public module EnumerationBlob {
    public type EnumerationBlob = {
      var array : [var Blob];
      var size_ : Nat;
      var tree : Tree;
    };

    public func empty() : EnumerationBlob {
      {
        var array = [var ""];
        var size_ = 0;
        var tree = (null : Tree);
      };
    };

    /// Add `key` to enumeration. Returns `size` if the key is new to the enumeration and index of key in enumeration otherwise.
    ///
    /// Example:
    /// ```motoko
    /// let e = EnumerationBlob.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.add("abc") == 0);
    /// ```
    /// Runtime: O(log(n))
    public func add(self : EnumerationBlob, key : Blob) : Nat {
      var index = self.size_;

      func insert(tree : Tree) : Tree {
        switch tree {
          case (?(#B, left, y, right)) {
            let res = Prim.blobCompare(key, self.array[y]);
            if (res < 0) {
              lbalance(insert(left), y, right);
            } else if (res > 0) {
              rbalance(left, y, insert(right));
            } else {
              index := y;
              tree;
            };
          };
          case (?(#R, left, y, right)) {
            let res = Prim.blobCompare(key, self.array[y]);
            if (res < 0) {
              ?(#R, insert(left), y, right);
            } else if (res > 0) {
              ?(#R, left, y, insert(right));
            } else {
              index := y;
              tree;
            };
          };
          case (null) {
            index := self.size_;
            ?(#R, null, self.size_, null);
          };
        };
      };

      self.tree := switch (insert(self.tree)) {
        case (?(#R, left, y, right)) ?(#B, left, y, right);
        case other other;
      };

      if (index == self.size_) {
        if (self.size_ == self.array.size()) {
          self.array := VarArray.tabulate<Blob>(next_size(self.size_), func(i) = if (i < self.size_) { self.array[i] } else { "" });
        };
        self.array[self.size_] := key;
        self.size_ += 1;
      };

      index;
    };

    /// Returns `?index` where `index` is the index of `key` in order it was added to enumeration, or `null` it `key` wasn't added.
    ///
    /// Example:
    /// ```motoko
    /// let e = EnumerationBlob.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.lookup("abc") == ?0);
    /// assert(e.lookup("aaa") == ?1);
    /// assert(e.lookup("bbb") == null);
    /// ```
    /// Runtime: O(log(n))
    public func lookup(self : EnumerationBlob, key : Blob) : ?Nat {
      func get_in_tree(x : Blob, t : Tree) : ?Nat {
        switch t {
          case (?(_, l, y, r)) {
            let res = Prim.blobCompare(x, self.array[y]);
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

    /// Returns `K` with index `index`.
    /// Traps it `index >= size`.
    ///
    /// Example:
    /// ```motoko
    /// let e = EnumerationBlob.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.at(0) == "abc");
    /// assert(e.at(1) == "aaa");
    /// ```
    /// Runtime: O(1)
    public func at(self : EnumerationBlob, index : Nat) : Blob {
      if (index < self.size_) { self.array[index] } else {
        Runtime.trap("Index out of bounds");
      };
    };

    /// Returns `K` with index `index`.
    /// Returns `null` when `index >= size`.
    ///
    /// Example:
    /// ```motoko
    /// let e = EnumerationBlob.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.get(0) == ?"abc");
    /// assert(e.get(1) == ?"aaa");
    /// assert(e.get(2) == null);
    /// ```
    /// Runtime: O(1)
    public func get(self : EnumerationBlob, index : Nat) : ?Blob {
      if (index < self.size_) { ?self.array[index] } else {
        null;
      };
    };

    /// Returns number of unique keys added to enumeration.
    ///
    /// Example:
    /// ```motoko
    /// let e = EnumerationBlob.empty();
    /// assert(e.add("abc") == 0);
    /// assert(e.add("aaa") == 1);
    /// assert(e.size() == 2);
    /// ```
    /// Runtime: O(1)
    public func size(self : EnumerationBlob) : Nat = self.size_;
  };
};
