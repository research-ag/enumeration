/// Example: assigning permanent, consecutive user numbers to principals.
///
/// This is the canonical use case from the README's "Motivation" section.
/// The first time a principal registers it is appended to the enumeration and
/// receives a permanent number (its index); subsequent registrations return the
/// same number. The number can be mapped back to the principal in `O(1)`, so all
/// per-user data elsewhere in the canister can be keyed by the (small) number
/// instead of the (large) principal.
///
/// Build with `mops build`, type-check with `mops check`.
///
/// Copyright: 2023 - 2026 MR Research AG

import { Enumeration } "mo:enumeration";
import Principal "mo:core/Principal";

persistent actor Users {
  // `Enumeration` is composed of stable types, so it can be held directly in
  // the persistent actor state without any `preupgrade`/`postupgrade` hooks.
  let users = Enumeration.empty<Principal>();

  /// Register the caller and return its permanent user number.
  /// Idempotent: calling it again returns the same number.
  public shared ({ caller }) func register() : async Nat {
    // `compare` is implicit and resolved to `Principal.compare`.
    users.add(caller);
  };

  /// Return the caller's user number, or `null` if it never registered.
  public shared query ({ caller }) func myNumber() : async ?Nat {
    users.lookup(caller);
  };

  /// Return the principal that holds the given user number, or `null`.
  public query func principalOf(number : Nat) : async ?Principal {
    users.get(number);
  };

  /// Total number of registered users.
  public query func count() : async Nat {
    users.size();
  };
};
