cmake_minimum_required(VERSION 3.4)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/modules")
set(TARGET_MACOS FALSE)

include(SwiftPM)
include(PkgConfigs)

add_subdirectory(runtime)

find_cllvm_pkgconfig()
find_cclang_pkgconfig()

if(${CMAKE_GENERATE_XCODEPROJ})
  swift_generate_xcodeproj(trill
    BUILD_DIR "${CMAKE_BINARY_DIR}"
    INCLUDE_DIRS ${CLLVM_INCLUDE_DIRS} ${CCLANG_INCLUDE_DIRS}
    LIBRARY_DIRS ${CLLVM_LIBRARY_DIRS} ${CCLANG_LIBRARY_DIRS}
    LIBRARIES ${CLLVM_LIBRARIES} ${CCLANG_LIBRARIES}
    SWIFT_EXEC ${CMAKE_SWIFT_EXEC}
    DEPENDS trillRuntime)
else()
  # On Darwin, override the `-target` flag to specify a minimum of 10.12 --
  # this avoids a ton of warnings when linking with LLVM's libraries.
  set(swiftc_flags)
  if("${CMAKE_SYSTEM_NAME}" MATCHES "Darwin")
    set(TARGET_MACOS TRUE)
    list(APPEND swiftc_flags -target x86_64-apple-macosx10.12)
  endif()

  # If we're building the release configuration, tell SwiftPM.
  set(swift_flags)
  if("${CMAKE_BUILD_TYPE}" STREQUAL "Release")
    list(APPEND swift_flags --configuration release)
  endif()

  swiftpm(trill
    BUILD
    BUILD_DIR "${CMAKE_BINARY_DIR}"
    FLAGS ${swift_flags}
    INCLUDE_DIRS ${CLLVM_INCLUDE_DIRS} ${CCLANG_INCLUDE_DIRS}
    LIBRARY_DIRS ${CLLVM_LIBRARY_DIRS} ${CCLANG_LIBRARY_DIRS}
    LIBRARIES ${CLLVM_LIBRARIES} ${CCLANG_LIBRARIES}
    SWIFTC_FLAGS ${swiftc_flags}
    SWIFT_EXEC ${CMAKE_SWIFT_EXEC}
    DEPENDS trillRuntime)
endif()

add_custom_target(link-stdlib ALL
  COMMAND
    ${CMAKE_COMMAND} -E create_symlink "${CMAKE_SOURCE_DIR}/stdlib" "${CMAKE_BINARY_DIR}/stdlib")