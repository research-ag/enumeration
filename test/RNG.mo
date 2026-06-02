/// Shared deterministic random generator for the `Enumeration` tests.
///
/// Copyright: 2023 - 2026 MR Research AG
///
/// Main author: Andrii Stepanov (AStepanov25)
///
/// Contributors: Timo Hanke (timohanke), Yurii Pytomets (Pitometsu)

import Array "mo:core/Array";
import Blob "mo:core/Blob";
import Char "mo:core/Char";
import Nat8 "mo:core/Nat8";
import Nat32 "mo:core/Nat32";

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

    public func text() : Text {
      var t = "";
      var j = 0;
      while (j < 24) {
        // map to a lowercase letter 'a'..'z'
        t #= Char.toText(Char.fromNat32(97 + Nat32.fromNat(next() % 26)));
        j += 1;
      };
      t;
    };
  };
};
