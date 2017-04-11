//
//  Constraint.swift
//  trill
//
//  Created by Harlan Haskins on 4/11/17.
//  Copyright © 2017 Harlan. All rights reserved.
//

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

  /// Returns a new constraint based on the provided constraint, but by updating
  /// the kind of constraint.
  func withKind(_ kind: Kind) -> Constraint {
    return Constraint(kind: kind, location: location, node: node)
  }
}
