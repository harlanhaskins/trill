cmake_minimum_required(VERSION 3.4)

include(ExternalProject)

include_directories(include)

set(EXTERNAL_INSTALL_DIR "${CMAKE_BINARY_DIR}/external-projects")
set(BDWGC_SRC_DIR ${EXTERNAL_INSTALL_DIR}/src/bdwgc)

# Add BDW GC dependency
externalproject_add(bdwgc
  GIT_REPOSITORY https://github.com/ivmai/bdwgc.git
  PREFIX "${EXTERNAL_INSTALL_DIR}"
  BINARY_DIR "${BDWGC_SRC_DIR}"
  CONFIGURE_COMMAND
    "${CMAKE_COMMAND}" "-DCMAKE_OSX_ARCHITECTURES=x86_64"
  INSTALL_COMMAND "")

add_subdirectory(src)
