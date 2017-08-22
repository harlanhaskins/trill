// swift-tools-version:4.0
import PackageDescription

let package = Package(name: "trill",
  products: [
    .executable(name: "trill", targets: ["trill"]),
  ],
  dependencies: [
    .package(url: "https://github.com/trill-lang/cllvm.git", from: "0.0.3"),
    .package(url: "https://github.com/trill-lang/LLVMSwift.git", from: "0.1.11"),
    .package(url: "https://github.com/trill-lang/ClangSwift.git", from: "0.0.4"),
    .package(url: "https://github.com/jatoben/CommandLine.git", .branch("master"))
  ],
  targets: [
    .target(name: "AST", dependencies: [
      "Source", "Diagnostics"
    ]),
    .target(name: "ClangImporter", dependencies: [
      "AST", "Clang", "LLVMWrappers", "Parse", "Runtime"
    ]),
    .target(name: "Driver", dependencies: ["AST"]),
    .target(name: "Diagnostics", dependencies: ["Source"]),
    .target(name: "IRGen", dependencies: ["AST", "LLVM", "LLVMWrappers", "Options", "Runtime"]),
    .target(name: "LLVMWrappers"),
    .target(name: "Options", dependencies: ["CommandLine"]),
    .target(name: "Parse", dependencies: ["AST"]),
    .target(name: "Sema", dependencies: ["AST"]),
    .target(name: "Source"),
    .target(name: "Runtime"),
    .target(name: "trill", dependencies: [
      "AST", "ClangImporter", "Diagnostics", "Driver",
      "IRGen", "LLVMWrappers", "Options", "Parse", "Sema", "Source"
    ])
  ])
