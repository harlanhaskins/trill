//
//  FunctionParser.swift
//  Trill
//

import Foundation

/// Distinguishes the
enum FunctionKind {
  case initializer
  case deinitializer
  case method
  case staticMethod
  case `operator`(op: BuiltinOperator)
  case `subscript`
  case property
  case variable
  case free
}

extension Parser {
  /// Function Declaration
  ///
  /// func-decl ::= fun <name>([<name> [internal-name]: <typename>,]*): <typename> <braced-expr-block>
  func parseFuncDecl(_ modifiers: [DeclModifier],
                     forType type: DataType? = nil,
                     isProtocol: Bool = false) throws -> FuncDecl {
    var modifiers = modifiers
    let startLoc = sourceLoc
    var args = [ParamDecl]()
    var genericArgs = [GenericParamDecl]()
    var returnType = TypeRefExpr(type: .void, name: "Void")
    var hasVarArgs = false
    var kind: FunctionKind = .free
    var nameRange: SourceRange? = nil
    if case .Init = peek() {
      modifiers.append(.mutating)
      kind = .initializer
      nameRange = consumeToken().range
    } else if case .deinit = peek() {
      kind = .deinitializer
      nameRange = consumeToken().range
    } else if case .subscript = peek() {
      let tok = consumeToken()
      nameRange = tok.range
      kind = .subscript
    } else {
      try consume(.func)
      if type != nil {
        if modifiers.contains(.static) {
          kind = .staticMethod
        } else {
          kind = isProtocol ? .protocolMethod(type: type) : .method(type: type)
        }
      } else if case .operator(let op) = peek() {
        let tok = consumeToken()
        nameRange = tok.range
        kind = .operator(op: op)
      } else if case .subscript = peek() {
        throw Diagnostic.error(ParseError.globalSubscript,
                               loc: currentToken().range.start)
      } else {
        kind = .free
      }
    }
    var name: Identifier = ""
    switch kind {
    case .free, .method, .staticMethod:
      name = try parseIdentifier()
    default: break
    }
    if case .deinitializer = kind {
    } else {
      (genericArgs, args, returnType, hasVarArgs) = try parseFuncSignature()
    }
    var body: CompoundStmt? = nil
    if case .leftBrace = peek() {
      body = try parseCompoundStmt()
      if case .initializer = kind {
        returnType = type!.ref()
      }
    }
    switch kind {
    case .operator(let op):
      return OperatorDecl(op: op,
                          args: args,
                          genericParams: genericArgs,
                          returnType: returnType,
                          body: body,
                          modifiers: modifiers,
                          opRange: nameRange,
                          sourceRange: range(start: startLoc))
    case .subscript:
      return SubscriptDecl(returnType: returnType,
                           args: args,
                           parentType: type!,
                           genericParams: genericArgs,
                           body: body,
                           modifiers: modifiers,
                           sourceRange: range(start: startLoc))
    case .initializer:
      return InitializerDecl(parentType: type!,
                             args: args,
                             returnType: returnType,
                             body: body,
                             modifiers: modifiers,
                             sourceRange: range(start: startLoc))
    case .deinitializer:
      return DeinitializerDecl(parentType: type!,
                               body: body,
                               sourceRange: range(start: startLoc))
    case .method:
      return MethodDecl(name: name,
                        parentType: type!,
                        args: args,
                        returnType: returnType,
                        body: body,
                        modifiers: modifiers,
                        hasVarArgs: hasVarArgs,
                        sourceRange: range(start: startLoc))
    case .staticMethod:
      return MethodDecl(name: name,
                        parentType: type!,
                        args: args,
                        returnType: returnType,
                        body: body,
                        modifiers: modifiers,
                        isStatic: true,
                        hasVarArgs: hasVarArgs,
                        sourceRange: range(start: startLoc))
    default:
      return FuncDecl(name: name,
                      returnType: returnType,
                      args: args,
                      body: body,
                      modifiers: modifiers,
                      hasVarArgs: hasVarArgs,
                      sourceRange: range(start: startLoc))
    }
    return FuncDecl(name: name,
                    returnType: returnType,
                    args: args,
                    genericParams: genericArgs,
                    kind: kind,
                    body: body,
                    modifiers: modifiers,
                    hasVarArgs: hasVarArgs,
                    sourceRange: range(start: startLoc))
  }
  
  func parseFuncSignature() throws -> (genericArgs: [GenericParamDecl], args: [ParamDecl], ret: TypeRefExpr, hasVarArgs: Bool) {
    var genericArgs = [GenericParamDecl]()

    if case .operator(.lessThan) = peek() {
      genericArgs = try parseGenericParamDecls()
    }

    try consume(.leftParen)
    var hasVarArgs = false
    var args = [ParamDecl]()
    while true {
      if case .rightParen = peek() {
        consumeToken()
        break
      }
      let startLoc = sourceLoc
      // An argument has both an internal and external name.
      // If there is only one name specified, then the internal
      // and external names match.
      var externalName: Identifier? = nil
      var internalName: Identifier = ""
      if let name = try? attempt(try parseIdentifier()) {
        externalName = name
        internalName = name
      } else if case .underscore = peek() {
        // allow for discarding a external name using '_'
        externalName = nil
        consumeToken()
      } else {
        throw unexpectedToken()
      }
      if let id = try? attempt(try parseIdentifier()) {
        internalName = id
      }
      try consume(.colon)
      
      if case .ellipsis = peek() {
        consumeToken()
        try consume(.rightParen)
        hasVarArgs = true
        break
      }
      let type = try parseType()
      let arg = ParamDecl(name: internalName,
                                       type: type,
                                       externalName: externalName,
                                       sourceRange: range(start: startLoc))
      args.append(arg)
      if case .rightParen = peek() {
        consumeToken()
        break
      }
      try consume(.comma)
    }
    let returnType: TypeRefExpr
    if case .arrow = peek() {
      consumeToken()
      returnType = try parseType()
    } else {
      returnType = TypeRefExpr(type: .void, name: "Void")
    }
    return (genericArgs: genericArgs, args: args, ret: returnType, hasVarArgs: hasVarArgs)
  }

  func parseGenericParamDecls() throws -> [GenericParamDecl] {
    try consume(.leftAngle)
    var names = [Identifier]()
    var constraints = [String: [TypeRefExpr]]()

    var hasWhere = false
    loop: while true {
      names.append(try parseIdentifier())
      let tok = currentToken()
      switch tok.kind {
      case .where:
        consumeToken()
        hasWhere = true
        break loop
      case .operator(.greaterThan):
        break loop
      case .comma:
        consumeToken()
        continue
      default:
        throw unexpectedToken()
      }
    }

    if hasWhere {
      let values = try parseSeparated(by: .comma, until: .rightAngle) {
        () -> (Identifier, TypeRefExpr) in
        let name = try parseIdentifier()
        try consume(.colon)
        let type = try parseType()
        return (name, type)
      }
      for (name, type) in values {
        var newVals = constraints[name.name] ?? []
        newVals.append(type)
        constraints[name.name] = newVals
      }
    }
    try consume(.rightAngle)

    return names.map { GenericParamDecl(name: $0, constraints: constraints[$0.name] ?? []) }
  }
 
  /// Function Call Args
  ///
  /// func-call-args ::= ([<label>:] <val-expr>,*)
  func parseFunCallArgs(open: TokenKind, close: TokenKind) throws -> [Argument] {
    try consume(open)
    var args = [Argument]()
    while true {
      if peek() == close {
        consumeToken()
        break
      }
      var label: Identifier? = nil
      if let id = try? attempt(try parseIdentifier()) {
        if case .colon = peek() {
          consumeToken()
          label = id
        } else {
          // backtrack behind the identifier
          backtrack()
        }
      }
      let expr = try parseValExpr()
      args.append(Argument(val: expr, label: label))
      
      if peek() == close {
        consumeToken()
        break
      }
      
      try consume(.comma)
    }
    return args
  }
}
