function(join values glue output)
  string(REPLACE ";" "${glue}" _tmp_str "${values}")
  set(${output} "${_tmp_str}" PARENT_SCOPE)
endfunction()

function(swiftpm build_name)
  set(options BUILD TEST)
  set(oneValueArgs SWIFT_EXEC BUILD_DIR)
  set(multiValueArgs DEPEDNS FLAGS INCLUDE_DIRS LIBRARY_DIRS LIBRARIES SWIFTC_FLAGS)
  cmake_parse_arguments(SWIFTPM "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if("${SWIFTPM_BUILD_DIR}" STREQUAL "")
    message(FATAL_ERROR "must provide BUILD_DIR to swiftpm()")
  endif()

  if(${SWIFTPM_BUILD} AND ${SWIFTPM_TEST})
    message(FATAL_ERROR "you may only specify one of BUILD or TEST")
  endif()

  if("${SWIFTPM_SWIFT_EXEC}" STREQUAL "")
    set(SWIFTPM_SWIFT_EXEC swift)
  endif()

  # Construct a list of flags to pass to swift build

  set(swiftpm_args)

  if(${SWIFTPM_BUILD})
    list(APPEND swiftpm_args build)
  endif()

  if(${SWIFTPM_TEST})
    list(APPEND swiftpm_args test)
  endif()

  foreach(flag ${SWIFTPM_FLAGS})
    list(APPEND swiftpm_args ${flag})
  endforeach()

  foreach(dir ${SWIFTPM_INCLUDE_DIRS})
    list(APPEND swiftpm_args -Xcc -I${dir})
  endforeach()

  foreach(dir ${SWIFTPM_LIBRARY_DIRS})
    list(APPEND swiftpm_args -Xlinker -L${dir})
  endforeach()

  foreach(lib ${SWIFTPM_LIBRARIES})
    list(APPEND swiftpm_args -Xlinker -l${lib})
  endforeach()

  foreach(flag ${SWIFTPM_SWIFTC_FLAGS})
    list(APPEND swiftpm_args -Xswiftc ${flag})
  endforeach()

  # Make a temporary directory for swiftpm to do all its work.
  set(swiftpm_build_path "${SWIFTPM_BUILD_DIR}/swiftpm")
  list(APPEND swiftpm_args --build-path "${swiftpm_build_path}")

  # Ask swiftpm where it's going to put the resulting binary.

  set(swiftpm_result_dir)
  execute_process(
    COMMAND ${SWIFTPM_SWIFT_EXEC} build --show-bin-path --build-path "${swiftpm_build_path}"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    OUTPUT_VARIABLE swiftpm_result_dir
    OUTPUT_STRIP_TRAILING_WHITESPACE)

  # Create a new path for the binary, in the top-level bin/ dir.
  set(output_binary_dir "${SWIFTPM_BUILD_DIR}/bin")

  # Create a target that will do three things:
  #   1) Run swiftpm
  #   2) Make the output binary dir
  #   3) Copy the built executable into the output dir.
  set(target_name "swift-build-${build_name}")

  add_custom_target(${target_name} ALL
    COMMAND
      "${SWIFTPM_SWIFT_EXEC}" ${swiftpm_args}
    COMMAND
      ${CMAKE_COMMAND} -E make_directory "${output_binary_dir}"
    COMMAND
      ${CMAKE_COMMAND} -E copy "${swiftpm_result_dir}/${build_name}" "${output_binary_dir}"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    DEPENDS ${SWIFTPM_DEPENDS})

endfunction()

function(swift_generate_xcodeproj build_name)
  set(options)
  set(oneValueArgs SWIFT_EXEC BUILD_DIR)
  set(multiValueArgs DEPENDS INCLUDE_DIRS LIBRARY_DIRS LIBRARIES)
  cmake_parse_arguments(SWIFT_XCODE "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(${SWIFT_XCODE_SWIFT_EXEC} STREQUAL "")
    set(SWIFT_XCODE_SWIFT_EXEC swift)
  endif()

  set(ldflags)

  foreach(dir ${SWIFT_XCODE_LIBRARY_DIRS})
    list(APPEND ldflags " -L${dir}")
  endforeach()

  foreach(lib ${SWIFT_XCODE_LIBRARIES})
    list(APPEND ldflags " -l${lib}")
  endforeach()

  join("${SWIFT_XCODE_INCLUDE_DIRS}" " " include_dirs)
  join("${SWIFT_XCODE_LIBRARY_DIRS}" " " library_dirs)

  set(xcconfig_contents)
  string(CONCAT xcconfig_contents
    "MACOSX_DEPLOYMENT_TARGET = 10.12\n"
    "SWIFT_VERSION = 4.0\n"
    "HEADER_SEARCH_PATHS = $(inherited) " ${include_dirs} "\n"
    "LIBRARY_SEARCH_PATHS = $(inherited) " ${library_dirs} "\n"
    "OTHER_LDFLAGS = $(inherited) " ${ldflags} "\n"
    "CLANG_CXX_LANGUAGE_STANDARD = c++14\n")

  if(NOT "${SWIFT_XCODE_BUILD_DIR}" STREQUAL "")
    list(APPEND xcconfig_contents
         "BUILD_DIR = ${SWIFT_XCODE_BUILD_DIR}\n")
  endif()

  set(xcconfig_path ${CMAKE_BINARY_DIR}/trill.xcconfig)

  file(WRITE ${xcconfig_path} ${xcconfig_contents})

  set(target_name "swift-xcodeproj-${build_name}")
  add_custom_target(${target_name} ALL
    COMMAND ${SWIFT_XCODE_SWIFT_EXEC} package generate-xcodeproj --xcconfig-overrides "${xcconfig_path}"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    DEPENDS ${SWIFT_XCODE_DEPENDS})
endfunction()