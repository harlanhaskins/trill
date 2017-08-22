///
/// Constraint.swift
///
/// Copyright 2016-2017 the Trill project authors.
/// Licensed under the MIT License.
///
/// Full license text available at https://github.com/trill-lang/trill
///

import AST
import Foundation

/// Describes the kinds of constraints we can use to solve type variables.
struct Constraint {
  enum Kind {
    case equal(DataType, DataType)
    case conforms(DataType, DataType)
  }

  let kind: Kind
  let location: StaticString
  let node: ASTNode?

  func substituting(_ solution: [String: DataType]) -> Constraint {
    switch kind {
    case let .equal(t1, t2):
      return withKind(.equal(t1.substitute(solution),
                             t2.substitute(solution)))
    case let .conforms(t1, t2):
      return withKind(.conforms(t1.substitute(solution),
                                t2.substitute(solution)))
    }
  }

  /// Returns a new constraint based on the provided constraint, but by updating
  /// the kind of constraint.
  func withKind(_ kind: Kind) -> Constraint {
    return Constraint(kind: kind, location: location, node: node)
  }
}
