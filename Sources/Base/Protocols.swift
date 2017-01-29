//
//  Protocol.swift
//  Trill
//

class ProtocolDecl: TypeDecl {
  override func equals(_ rhs: ASTNode) -> Bool {
    guard rhs is ProtocolDecl else { return false }
    return super.equals(rhs)
  }

  /// Returns all methods required by this protocol by recursively
  /// traversing the conformances.
  var allMethods: [FuncDecl] {
    var methods = self.methods
    for conformance in conformances {
      guard let decl = conformance.decl as? ProtocolDecl else { continue }
      methods.append(contentsOf: decl.allMethods)
    }
    return methods
  }
}
