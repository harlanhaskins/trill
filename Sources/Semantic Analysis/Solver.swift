//
//  CSGen.swift
//  Trill
//
//  Created by Robert Widmann on 3/14/17.
//  Copyright © 2017 Harlan. All rights reserved.
//

final class Solver {
  typealias ConstraintSystem = [Constraint]
  typealias Solution = [String:DataType]

  enum Constraint {
    case Eq(DataType, DataType)
  }

  static func solveSystem(_ cs : ConstraintSystem) -> Solution {
    var sub : Solution = [:]
    for c in cs {
      let soln = self.solveSingle(c)

      sub.unionInPlace(soln)
    }
    return sub
  }

  // Unify
  static func solveSingle(_ c : Constraint) -> Solution {
    switch c {
    case let .Eq(t1, t2):
      // If the two types are already equal there's nothing to be done.
      if t1 == t2 {
        return [:]
      }

      switch (t1, t2) {
      case let (.metaVariable(m), t), let (t, .metaVariable(m)):
        // Perform the occurs check
        if t.contains(m) {
          fatalError("Infinite type")
        }
        // Unify the metavariable with the concrete type.
        return [m:t]
      case let (.typeVariable(m), t), let (t, .typeVariable(m)):
        // Perform the occurs check
        if t.contains(m) {
          fatalError("Infinite type")
        }
        // Unify the type variable with the concrete type.
        return [m:t]
      case let (.function(args1, returnType1), .function(args2, returnType2)):
        return solveSystem([.Eq(returnType1, returnType2)] + zip(args1, args2).map(Constraint.Eq))
      case (.pointer(_), .pointer(_)):
        // Pointers may unify with any other kind of pointer.
        return [:]
      case (.bool, .int):
        // Boolean values may coerce to integer values (but not vice-versa).
        return [:]
      case (_, .any):
        // Anything can unify to an existential
        return [:]
      default:
        fatalError()
      }
    }
  }

  final class Generator: ASTTransformer {
    var goal: DataType? = nil
    var env: [Identifier:DataType] = [:]
    var constraints: [Constraint] = []

    func reset(with env: [Identifier:DataType]) {
      self.goal = nil
      self.env = env
      self.constraints = []
    }

    func byBinding(_ n : Identifier, _ t : DataType, _ f : () -> ()) {
      let oldEnv = self.env
      self.env[n] = t
      f()
      self.env = oldEnv
    }

    // MARK: Monotypes

    override func visitVarExpr(_ expr: VarExpr) {
      if expr.isSelf {
        self.goal = expr.type
        return
      }

      if let t = self.env[expr.name] ?? self.context.global(named: expr.name)?.type {
        self.goal = t
        return
      }
      
      let functions = self.context.functions(named: expr.name)
      guard !functions.isEmpty else {
        fatalError()
      }

      // If we can avoid overload resolution, avoid it
      if functions.count == 1 {
        self.goal = functions[0].type!
      } else {
        self.goal = DataType.function(args: [ DataType.freshTypeVariable ], returnType: DataType.freshTypeVariable)
      }
    }

    override func visitSizeofExpr(_ expr: SizeofExpr) {
      self.goal = expr.type!
    }

    override func visitPropertyRefExpr(_ expr: PropertyRefExpr) {
      self.goal = expr.type!
    }

    override func visitVarAssignDecl(_ expr: VarAssignDecl) {
      let goalType: DataType
      // let <ident> : <Type> = <expr>
      if let e = expr.rhs, let t = expr.type {
        goalType = t
        byBinding(expr.name, goalType, {
          visit(e)
        })
        // Bind the given type to the goal type the initializer generated.
        self.constraints.append(.Eq(goalType, self.goal!))
      }
      // let <ident> = <expr>
      else if let e = expr.rhs {
        // Generate 
        let tau = DataType.freshMetaVariable
        byBinding(expr.name, tau, {
          visit(e)
        })
        let phi = Solver.solveSystem(self.constraints)
        goalType = tau.substitute(phi)
      }
      // let <ident> : <Type>
      else if let t = expr.type {
        // Take the type binding as fact and move on.
        goalType = t
        self.env[expr.name] = goalType
      }
      else {
        fatalError()
      }

      self.goal = goalType
    }

    override func visitFuncDecl(_ expr: FuncDecl) {
      if let body = expr.body {
        let oldEnv = self.env
        for p in expr.args {
          // Bind the type of the parameters.
          self.env[p.name] = p.type!
        }
        // Walk into the function body
        self.visit(body)
        self.env = oldEnv
      }
      self.goal = expr.type!
    }

    override func visitFuncCallExpr(_ expr: FuncCallExpr) {
      visit(expr.lhs)
      let lhsGoal = self.goal!
      var goals : [DataType] = []
      if let pre = expr.lhs as? PropertyRefExpr {
        goals.append(pre.lhs.type!)
      }
      expr.args.forEach { a in
        visit(a.val)
        goals.append(self.goal!)
      }
      let tau = DataType.freshMetaVariable
      self.constraints.append(.Eq(lhsGoal, .function(args: goals, returnType: tau)))
      self.goal = tau
    }

    override func visitInfixOperatorExpr(_ expr: InfixOperatorExpr) {
      let lhsGoal = expr.decl!.type!
      var goals : [DataType] = []
      [ expr.lhs, expr.rhs ].forEach { e in
        visit(e)
        goals.append(self.goal!)
      }
      let tau = DataType.freshMetaVariable
      self.constraints.append(.Eq(lhsGoal, .function(args: goals, returnType: tau)))
      self.goal = tau
    }

    override func visitSubscriptExpr(_ expr: SubscriptExpr) {
      visit(expr.lhs)
      var goals : [DataType] = [ self.goal! ]
      expr.args.forEach { a in
        visit(a.val)
        goals.append(self.goal!)
      }
      let tau = DataType.freshMetaVariable
      self.constraints.append(.Eq(expr.decl!.type!, .function(args: goals, returnType: tau)))
      self.goal = tau
    }

    // MARK: Literals

    override func visitNumExpr(_ expr: NumExpr) { self.goal = expr.type! }
    override func visitCharExpr(_ expr: CharExpr) { self.goal = expr.type! }
    override func visitFloatExpr(_ expr: FloatExpr) { self.goal = expr.type! }
    override func visitBoolExpr(_ expr: BoolExpr) { self.goal = expr.type! }
    override func visitVoidExpr(_ expr: VoidExpr) { self.goal = expr.type! }
    override func visitNilExpr(_ expr: NilExpr) { self.goal = expr.type! }
    override func visitStringExpr(_ expr: StringExpr) { self.goal = expr.type! }
  }
}

extension Dictionary {
  mutating func unionInPlace(_ with : Dictionary) {
    with.forEach { self.updateValue($1, forKey: $0) }
  }

  func union(_ other : Dictionary) -> Dictionary {
    var dictionary = other
    dictionary.unionInPlace(self)
    return dictionary
  }

  init<S : Sequence>(_ pairs : S) where S.Iterator.Element == (Key, Value) {
    self.init()
    var g = pairs.makeIterator()
    while let (k, v): (Key, Value) = g.next() {
      self[k] = v
    }
  }
}

