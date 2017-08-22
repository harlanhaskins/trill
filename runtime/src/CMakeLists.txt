add_library(trillRuntime STATIC
  Demangle.cpp
  Generics.cpp
  Metadata.cpp
  private/Metadata.cpp
  Runtime.cpp)

add_dependencies(trillRuntime bdwgc)

set_property(TARGET trillRuntime PROPERTY CXX_STANDARD 14)

# Add BDW's include directory to the trillRuntime includes
target_include_directories(trillRuntime PUBLIC "${BDWGC_SRC_DIR}/include")

set(lib_dir "${CMAKE_BINARY_DIR}/lib")
file(MAKE_DIRECTORY ${lib_dir})

# Link bdw's libgc directly into libTrillRuntime.a
add_custom_command(TARGET trillRuntime
  COMMAND
    libtool -static -o "${lib_dir}/libTrillRuntime.a" "${BDWGC_SRC_DIR}/libgc-lib.a" "$<TARGET_FILE:trillRuntime>")

file(
  COPY "${CMAKE_SOURCE_DIR}/runtime/include"
  DESTINATION "${CMAKE_BINARY_DIR}")