//
//  Generic.swift
//  Trill
//
//  Created by Harlan Haskins on 1/26/17.
//  Copyright © 2017 Harlan. All rights reserved.
//

import Foundation

class GenericParamDecl: TypeDecl {
    init(name: Identifier, constraints: [TypeRefExpr], sourceRange: SourceRange? = nil) {
        super.init(name: name,
                   fields: [],
                   methods: [],
                   staticMethods: [],
                   initializers: [],
                   subscripts: [],
                   modifiers: [],
                   conformances: constraints,
                   deinit: nil,
                   sourceRange: sourceRange)
    }
}

class GenericParam: ASTNode {
    let typeName: TypeRefExpr
    var decl: GenericParamDecl? = nil

    init(typeName: TypeRefExpr, sourceRange: SourceRange? = nil) {
        self.typeName = typeName
        super.init(sourceRange: sourceRange)
    }
}
