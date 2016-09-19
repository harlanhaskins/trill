//
//  Protocol.swift
//  Trill
//

class ProtocolDecl: Decl {
  let name: Identifier
  let inherited: [TypeRefExpr]
  var methods: [FuncDecl]
  
  init(name: Identifier, inherited: [TypeRefExpr], methods: [FuncDecl],
       modifiers: [DeclModifier], sourceRange: SourceRange?) {
    self.name = name
    self.inherited = inherited
    self.methods = methods
    super.init(type: DataType(name: name.name),
               modifiers: modifiers,
               sourceRange: sourceRange)
  }
  
  override func equals(_ rhs: ASTNode) -> Bool {
    guard let proto = rhs as? ProtocolDecl else { return false }
    return proto.name == name &&
           proto.inherited == inherited &&
           proto.methods == methods
  }
}
