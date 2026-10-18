// Shared benchmark data: N random 32-byte keys, and builders for Enumeration
// and the maps it is compared with (core Map, core pure/Map, zhus).
import { Enumeration; BlobEnumeration } "../src";
import Map "mo:core/Map";
import PureMap "mo:core/pure/Map";
import HashMap "mo:map/Map";
import Blob "mo:core/Blob";
import Array "mo:core/Array";
import Nat64 "mo:core/Nat64";

module {
  public let N = 4096;
  public let KEY_SIZE = 32;

  // Deterministic xorshift64* byte stream.
  public func keys(seed : Nat64, n : Nat) : [Blob] {
    var x : Nat64 = seed;
    func next() : Nat8 {
      x ^= x >> 12;
      x ^= x << 25;
      x ^= x >> 27;
      ((x *% 0x2545F4914F6CDD1D) >> 56).toNat8();
    };
    Array.tabulate<Blob>(n, func(_) = Array.tabulate<Nat8>(KEY_SIZE, func(_) = next()).toBlob());
  };

  public func buildBlobEnum(ks : [Blob]) : BlobEnumeration.BlobEnumeration {
    let e = BlobEnumeration.empty();
    for (k in ks.values()) ignore BlobEnumeration.add(e, k);
    e;
  };
  public func buildGenEnum(ks : [Blob]) : Enumeration.Enumeration<Blob> {
    let e = Enumeration.empty<Blob>();
    for (k in ks.values()) ignore Enumeration.add(e, Blob.compare, k);
    e;
  };
  public func buildBtree(ks : [Blob]) : Map.Map<Blob, Nat> {
    let m = Map.empty<Blob, Nat>();
    var i = 0;
    for (k in ks.values()) { m.add(k, i); i += 1 };
    m;
  };
  public func buildRbtree(ks : [Blob]) : PureMap.Map<Blob, Nat> {
    var m = PureMap.empty<Blob, Nat>();
    var i = 0;
    for (k in ks.values()) { m := m.add(k, i); i += 1 };
    m;
  };
  public func buildHashmap(ks : [Blob]) : HashMap.Map<Blob, Nat> {
    let m = HashMap.new<Blob, Nat>();
    var i = 0;
    for (k in ks.values()) { HashMap.set(m, HashMap.bhash, k, i); i += 1 };
    m;
  };
};
