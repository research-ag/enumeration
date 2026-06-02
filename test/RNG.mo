/// Shared deterministic random generator for the `Enumeration` tests.
///
/// Copyright: 2023 - 2026 MR Research AG
///
/// Main author: Andrii Stepanov (AStepanov25)
///
/// Contributors: Timo Hanke (timohanke), Yurii Pytomets (Pitometsu)

import Array "mo:core/Array";
import Blob "mo:core/Blob";
import Nat8 "mo:core/Nat8";
import Principal "mo:core/Principal";
import Text "mo:core/Text";

module {
  public class RNG() {
    var seed = 234234;

    public func next() : Nat {
      seed += 1;
      let a = seed * 15485863;
      a * a * a % 2038074743;
    };

    public func blob() : Blob {
      let a = Array.tabulate<Nat8>(29, func(i) = Nat8.fromNat(next() % 256));
      Blob.fromArray(a);
    };

    public func maxBlob() : Blob {
      let a = Array.tabulate<Nat8>(29, func(i) = Nat8.fromNat(0));
      Blob.fromArray(a);
    };

    public func principal() : Principal = Principal.fromBlob(blob());
    public func maxPrincipal() : Principal = Principal.fromBlob(maxBlob());
    public func text() : Text = Principal.toText(Principal.fromBlob(blob()));
    public func maxText() : Text = Principal.toText(Principal.fromBlob(maxBlob()));
  };
};
