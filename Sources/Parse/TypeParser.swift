//
//  TypeParser.swift
//  Trill
//

import Foundation

extension Parser {
  /// Type Declaration
  ///
  /// type-decl ::= type <typename> {
  ///   [<field-decl> | <func-decl>]*
  /// }
  func parseTypeDecl(_ modifiers: [DeclModifier]) throws -> ASTNode {
    try consume(.type)
    let startLoc = sourceLoc
    let name = try parseIdentifier()
    var conformances = [TypeRefExpr]()
    
    if case .operator(op: .assign) = peek() {
      consumeToken()
      let bound = try parseType()
      return TypeAliasDecl(name: name,
                           bound: bound,
                           sourceRange: range(start: startLoc))
    }
    if case .colon = peek() {
      conformances = try parseSeparated(by: .comma, until: .leftBrace, parseType)
    }
    try consume(.leftBrace)
    var fields = [VarAssignDecl]()
    var methods = [FuncDecl]()
    var initializers = [FuncDecl]()
    var deinitializer: FuncDecl?
    let type = DataType(name: name.name)
    loop: while true {
      if case .rightBrace = peek() {
        consumeToken()
        break
      }
      let modifiers = try parseModifiers()
      switch peek() {
      case .poundError, .poundWarning:
        context.add(try parsePoundDiagnosticExpr())
      case .func:
        methods.append(try parseFuncDecl(modifiers, forType: type))
      case .Init:
        initializers.append(try parseFuncDecl(modifiers, forType: type))
      case .var, .let:
        fields.append(try parseVarAssignDecl(modifiers: modifiers))
      case .deinit:
        if deinitializer != nil {
          throw Diagnostic.error(ParseError.duplicateDeinit, loc: sourceLoc)
        }
        deinitializer = try parseFuncDecl(modifiers, forType:type, isDeinit: true)
      default:
        throw unexpectedToken()
      }
      try consumeAtLeastOneLineSeparator()
    }
    return TypeDecl(name: name, fields: fields, methods: methods,
                    initializers: initializers,
                    modifiers: modifiers,
                    conformances: conformances,
                    deinit: deinitializer,
                    sourceRange: range(start: startLoc))
  }
  
  func parseSeparated<T>(by separator: TokenKind, until end: TokenKind, _ parser: () throws -> T) throws -> [T] {
    var values = [T]()
    while peek() != end {
      values.append(try parser())
      if peek() != end {
        try consume(separator)
      }
    }
    return values
  }
  
  func parseType() throws -> TypeRefExpr {
    let startLoc = sourceLoc
    while true {
      switch peek() {
      // HACK
      case .unknown(let char):
        var pointerLevel = 0
        for c in char.characters {
          if c != "*" {
            throw unexpectedToken()
          }
          pointerLevel += 1
        }
        consumeToken()
        return PointerTypeRefExpr(pointedTo: try parseType(),
                                  level: pointerLevel,
                                  sourceRange: range(start: startLoc))
      case .leftParen:
        consumeToken()
        let args = try parseSeparated(by: .comma, until: .rightParen, parseType)
        try consume(.rightParen)
        if case .arrow = peek() {
          consumeToken()
          let ret = try parseType()
          return FuncTypeRefExpr(argNames: args,
                                 retName: ret,
                                 sourceRange: range(start: startLoc))
        } else {
          return TupleTypeRefExpr(fieldNames: args,
                                  sourceRange: range(start: startLoc))
        }
      case .leftBracket:
        consumeToken()
        let innerType = try parseType()
        try consume(.rightBracket)
        return ArrayTypeRefExpr(element: innerType,
                                length: nil,
                                sourceRange: range(start: startLoc))
      case .operator(op: .star):
        consumeToken()
        return PointerTypeRefExpr(pointedTo: try parseType(),
                                  level: 1,
                                  sourceRange: range(start: startLoc))
      case .identifier:
        var id = try parseIdentifier()
        let r = range(start: startLoc)
        id = Identifier(name: id.name, range: r)
        return TypeRefExpr(type: DataType(name: id.name),
                           name: id, sourceRange: r)
      default:
        throw unexpectedToken()
      }
    }
  }
  
  func parseExtensionDecl() throws -> ExtensionDecl {
    let startLoc = sourceLoc
    try consume(.extension)
    let type = try parseType()
    try consume(.leftBrace)
    var methods = [FuncDecl]()
    while true {
      if case .rightBrace = peek() {
        consumeToken()
        break
      }
      let modifiers = try parseModifiers()
      guard case .func = peek()  else {
        throw Diagnostic.error(ParseError.unexpectedExpression(expected: "function"),
                               loc: sourceLoc)
      }
      methods.append(try parseFuncDecl(modifiers, forType: type.type))
    }
    return ExtensionDecl(type: type, methods: methods,
                         sourceRange: range(start: startLoc))
  }
  
  func parseProtocolDecl(modifiers: [DeclModifier]) throws -> ProtocolDecl {
    let startLoc = sourceLoc
    try consume(.protocol)
    let name = try parseIdentifier()
    var conformances = [TypeRefExpr]()
    if case .colon = peek() {
      consumeToken()
      guard case .identifier = peek() else {
        throw Diagnostic.error(ParseError.expectedIdentifier(got: peek()),
                               loc: currentToken().range.start,
                               highlights: [
                                 currentToken().range
                               ])
      }
      conformances = try parseSeparated(by: .comma, until: .leftBrace) {
        let name = try parseIdentifier()
        return TypeRefExpr(type: DataType(name: name.name), name: name)
      }
    }
    try consume(.leftBrace)
    var methods = [FuncDecl]()
    while true {
      if case .rightBrace = peek() {
        consumeToken()
        break
      }
      let modifiers = try parseModifiers()
      guard case .func = peek()  else {
        throw Diagnostic.error(ParseError.unexpectedExpression(expected: "function"),
                               loc: sourceLoc)
      }
      methods.append(try parseFuncDecl(modifiers))
    }
    return ProtocolDecl(name: name,
                        fields: [],
                        methods: methods,
                        modifiers: [],
                        conformances: conformances,
                        sourceRange: range(start: startLoc))
  }
}
