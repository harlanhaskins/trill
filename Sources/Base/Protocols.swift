//
//  Protocol.swift
//  Trill
//

class ProtocolDecl: TypeDecl {
  override func equals(_ rhs: ASTNode) -> Bool {
    guard rhs is ProtocolDecl else { return false }
    return super.equals(rhs)
  }
}
