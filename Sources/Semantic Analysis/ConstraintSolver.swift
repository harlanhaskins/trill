//
//  ConstraintSolver.swift
//  Trill
//
//  Created by Robert Widmann on 3/14/17.
//  Copyright © 2017 Harlan. All rights reserved.
//

struct ConstraintSolver {
  typealias Solution = [String: DataType]

  let context: ASTContext

  /// Solves a full system of constraints, providing a full environment
  /// of concrete type-variable mappings.
  /// - parameter cs: The constraint system you're trying to solve.
  /// - returns: A full environment of concrete types to fill in the type
  ///            variables in the system.
  func solveSystem(_ system: ConstraintSystem) -> Solution? {
    var fullSolution: Solution = [:]
    for constraint in system.constraints {
      let subst = constraint.substituting(fullSolution)
      guard let solution = self.solveSingle(subst) else { return nil }
      fullSolution.unionInPlace(solution)
    }
    return fullSolution
  }

  /// Solves a single constraint based on the set of available
  /// relationships between types in Trill.
  /// - parameter c: The constraint to solve.
  /// - returns: A `Solution`, essentially a set of bindings that concretize
  ///            all type variables present in the constraint, if any.
  func solveSingle(_ c: Constraint) -> Solution? {
    switch c.kind {
    case let .conforms(_t1, _t2):
      // Canonicalize types before checking.
      let t1 = context.canonicalType(_t1)
      let t2 = context.canonicalType(_t2)

      guard
        let typeDecl = context.decl(for: t1),
        let protocolDecl = context.protocolDecl(for: t2) else {
        return nil
      }

      guard context.conformsToProtocol(typeDecl, protocolDecl) else {
        return nil
      }

      return solveSingle(c.withKind(.equal(t1, .any)))

    case let .equal(_t1, _t2):

      // Canonicalize types before checking.
      let t1 = context.canonicalType(_t1)
      let t2 = context.canonicalType(_t2)

      // If the two types are already equal there's nothing to be done.
      if t1 == t2 {
        return [:]
      }

      switch (t1, t2) {
      case (.typeVariable, .typeVariable):
        context.diag.error("expression type is ambiguous",
                           loc: c.node?.startLoc,
                           highlights: [
                              c.node?.sourceRange
                           ])
        return nil
      case let (t, .typeVariable(m)):
        // Perform the occurs check
        if t.contains(m) {
          context.diag.error("type \(t) is infinite",
                             loc: c.node?.startLoc,
                             highlights: [
                               c.node?.sourceRange
                             ])
          return nil
        }
        // Unify the type variable with the concrete type.
        return [m: _t1]
      case let (.typeVariable(m), t):
        // Perform the occurs check
        if t.contains(m) {
          context.diag.error("type \(t) is infinite",
                             loc: c.node?.startLoc,
                             highlights: [
                               c.node?.sourceRange
                             ])
          return nil
        }
        // Unify the type variable with the concrete type.
        return [m: _t2]
      case let (.function(args1, returnType1, hasVarArgs1),
                .function(args2, returnType2, hasVarArgs2)):

        guard args1.count == args2.count || hasVarArgs1 || hasVarArgs2 else {
          break
        }

        var system = ConstraintSystem()
        for (arg1, arg2) in zip(args1, args2) {
          system.constrainEqual(arg1, arg2,
                                node: c.node, caller: c.location)
        }
        system.constrainEqual(returnType1, returnType2,
                              node: c.node, caller: c.location)

        return solveSystem(system)
      case (.pointer(_), .pointer(_)):
        // Pointers may unify with any other kind of pointer.
        return [:]
      case (_, .any), (.any, _):
        // Anything can unify to an existential
        return [:]
      default:
        break
      }
      context.diag.error("cannot convert value of type \(t1) to \(t2)",
                         loc: c.node?.startLoc,
                         highlights: [
                           c.node?.sourceRange
                         ])
      return nil
    }
  }
}

extension Dictionary {
  mutating func unionInPlace(_ with: Dictionary) {
    with.forEach { self.updateValue($1, forKey: $0) }
  }

  func union(_ other: Dictionary) -> Dictionary {
    var dictionary = other
    dictionary.unionInPlace(self)
    return dictionary
  }

  init<S: Sequence>(_ pairs: S) where S.Iterator.Element == (Key, Value) {
    self.init()
    var g = pairs.makeIterator()
    while let (k, v): (Key, Value) = g.next() {
      self[k] = v
    }
  }
}

