import LLVM

struct WitnessTable {
  let proto: ProtocolDecl
  let implementingType: TypeDecl
}

extension IRGenerator {

  func codegenWitnessTables(_ type: TypeDecl) -> [Global] {
    var globals = [Global]()
    for typeRef in type.conformances {
      guard let proto = context.protocol(named: typeRef.name) else {
        fatalError("no protocol named \(typeRef.name)")
      }
      let table = WitnessTable(proto: proto, implementingType: type)
      globals.append(codegenWitnessTable(table))
    }
    return globals
  }

  /// A Witness Table for a protocol consists of:
  ///
  /// - A pointer to the type metadata for the protocol type.
  /// - A pointer to an array of the protocol's witness table
  func codegenWitnessTable(_ table: WitnessTable) -> Global {
    let methodArrayType = ArrayType(elementType: PointerType.toVoid,
                                     count: table.proto.methods.count)
    var array = builder.addGlobal(Mangler.mangle(table),
                                  type: methodArrayType)

    let methods = table.implementingType.methodsSatisfyingRequirements(of: table.proto)

    let entries: [IRValue] = methods.map {
      let function = codegenFunctionPrototype($0)
      return builder.buildBitCast(function, type: PointerType.toVoid)
    }

    array.initializer = ArrayType.constant(entries, type: PointerType.toVoid)

    return array
  }
}
