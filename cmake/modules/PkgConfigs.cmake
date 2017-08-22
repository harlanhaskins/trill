function(find_cllvm_pkgconfig)
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(CLLVM QUIET cllvm)
  if(NOT CLLVM_FOUND)
    message(FATAL "Could not find cllvm pkg-config file. You'll need to generate this file after installing LLVM.")
    message("  git clone https://github.com/trill-lang/LLVMSwift.git /tmp/llvmswift")
    message("  cd /tmp/llvmswift")
    message("  swift utils/make-pkgconfig.swift")
  endif()
endfunction()

function(find_cclang_pkgconfig)
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(CCLANG QUIET cclang)
  if(NOT CCLANG_FOUND)
    message(FATAL "Could not find cclang pkg-config file. You'll need to generate this file after installing LLVM.")
    message("  git clone https://github.com/trill-lang/ClangSwift.git /tmp/clangswift")
    message("  cd /tmp/clangswift")
    message("  swift utils/make-pkgconfig.swift")
  endif()
endfunction()
