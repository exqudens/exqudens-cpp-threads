cmake_minimum_required(VERSION 3.21 FATAL_ERROR)
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/name-version.txt" INFO)
string(REPLACE ":" ";" INFO_LIST "${INFO}")
list(GET INFO_LIST 0 RAW_NAME)
list(GET INFO_LIST 1 RAW_VERSION)
string(STRIP "${RAW_NAME}" NAME)
string(STRIP "${RAW_VERSION}" VERSION)
project("${NAME}" VERSION "${VERSION}" LANGUAGES "NONE")

message("project: '${PROJECT_NAME}-${PROJECT_VERSION}'")

include("util.cmake")
include("config.cmake")
include("GenerateExportHeader")
enable_testing()
include(GoogleTest)

set_conan_settings(CONAN_SETTINGS
    "${CMAKE_SYSTEM_NAME}"
    "${CMAKE_SYSTEM_PROCESSOR}"
    "${CMAKE_CXX_COMPILER_ID}"
    "${CMAKE_CXX_COMPILER_VERSION}"
    "${CMAKE_MSVC_RUNTIME_LIBRARY}"
    "${CMAKE_CXX_STANDARD}"
    "${CMAKE_BUILD_TYPE}"
)
set_conan_options(CONAN_OPTIONS
    "interface=${CONAN_INTERFACE_ONLY}"
    "shared=${CONAN_BUILD_SHARED_LIBS}"
)
set("CONAN_INSTALL_PREFIX" "${PROJECT_BINARY_DIR}/conan-install")
if(NOT EXISTS "${CONAN_INSTALL_PREFIX}")
    execute_process(
        COMMAND "${CONAN_COMMAND}"
                install
                "${PROJECT_SOURCE_DIR}/conanfile.py"
                --install-folder
                "${CONAN_INSTALL_PREFIX}"
                ${CONAN_SETTINGS}
                ${CONAN_OPTIONS}
        COMMAND_ECHO "STDERR"
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ENCODING "UTF-8"
        COMMAND_ERROR_IS_FATAL ANY
    )
endif()
if(NOT EXISTS "${CONAN_INSTALL_PREFIX}/conan-packages.cmake")
    message(FATAL_ERROR "Not exists: '${CONAN_INSTALL_PREFIX}/conan-packages.cmake'!")
endif()
include("${CONAN_INSTALL_PREFIX}/conan-packages.cmake")
set(CMAKE_MODULE_PATH "${CONAN_INSTALL_PREFIX}")
foreach(
    conanPackageName
    cmakePackageName
    cmakePackageVersion
    cmakePackagePath
    IN ZIP_LISTS
    "${PROJECT_NAME}_CONAN_PACKAGE_NAMES"
    "${PROJECT_NAME}_CMAKE_PACKAGE_NAMES"
    "${PROJECT_NAME}_CMAKE_PACKAGE_VERSIONS"
    "${PROJECT_NAME}_CMAKE_PACKAGE_PATHS"
)
    if(
        "" STREQUAL "${conanPackageName}"
        OR "" STREQUAL "${cmakePackageName}"
        OR "" STREQUAL "${cmakePackageVersion}"
        OR "" STREQUAL "${cmakePackagePath}"
    )
        string(JOIN " " errorMessage
            "Empty value 'conanPackageName': '${conanPackageName}'"
            "or 'cmakePackageName': '${cmakePackageName}'"
            "or 'cmakePackageVersion': '${cmakePackageVersion}'"
            "or 'cmakePackagePath': '${cmakePackagePath}'!"
        )
        message(FATAL_ERROR "${errorMessage}")
    elseif(NOT IS_DIRECTORY "${cmakePackagePath}")
        message(FATAL_ERROR "Not is directory 'cmakePackagePath': '${cmakePackagePath}'!")
    endif()

    list(APPEND CMAKE_PREFIX_PATH "${cmakePackagePath}")

    if("gtest" STREQUAL "${conanPackageName}")
        file(REMOVE "${CONAN_INSTALL_PREFIX}/Find${cmakePackageName}.cmake")
        list(APPEND NOT_FOUND_PACKAGE_NAMES "${cmakePackageName}")
        find_package("${cmakePackageName}" "${cmakePackageVersion}" EXACT QUIET CONFIG)
    else()
        list(APPEND NOT_FOUND_PACKAGE_NAMES "${cmakePackageName}")
        find_package("${cmakePackageName}" "${cmakePackageVersion}" EXACT QUIET CONFIG)
    endif()

endforeach()
set_not_found_package_names(NOT_FOUND_PACKAGE_NAMES ${NOT_FOUND_PACKAGE_NAMES})
if(NOT "" STREQUAL "${NOT_FOUND_PACKAGE_NAMES}")
    foreach(package ${NOT_FOUND_PACKAGE_NAMES})
        message(WARNING "${package}_FOUND: '${${package}_FOUND}'")
    endforeach()
    return()
endif()

if("${INTERFACE_ONLY}")
    file(GLOB_RECURSE header_files "${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/**/*.hpp")
    file(GLOB_RECURSE source_files "${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp/**/*.cpp")
    foreach(header ${header_files})
        get_filename_component(header_file_dir "${header}" DIRECTORY)
        get_filename_component(header_file_name "${header}" NAME_WE)
        foreach(source ${source_files})
            get_filename_component(source_file_dir "${source}" DIRECTORY)
            get_filename_component(source_file_name "${source}" NAME_WE)
            if("${header_file_dir}" STREQUAL "${source_file_dir}" AND "${header_file_name}" STREQUAL "${source_file_name}")
                if(NOT "${header}" IN_LIST paired_header_files)
                    list(APPEND paired_header_files "${header}")
                    list(APPEND paired_source_files "${source}")
                endif()
            else()
                if(NOT "${header}" IN_LIST single_header_files)
                    list(APPEND single_header_files "${header}")
                endif()
            endif()
        endforeach()
    endforeach()
    foreach(header ${single_header_files})
        cmake_path(RELATIVE_PATH header BASE_DIRECTORY "${PROJECT_SOURCE_DIR}" OUTPUT_VARIABLE new_header_relative_path)
        get_filename_component(new_header_relative_dir "${new_header_relative_path}" DIRECTORY)
        set(new_header_dir "${PROJECT_BINARY_DIR}/generated/${new_header_relative_dir}")

        file(MAKE_DIRECTORY "${new_header_dir}")
        file(COPY "${header}" DESTINATION "${new_header_dir}")

        list(APPEND GENERATED_SOURCES "${new_header_relative_path}")
    endforeach()
    foreach(header source IN ZIP_LISTS paired_header_files paired_source_files)
        file(READ "${header}" header_content)
        file(READ "${source}" source_content)

        string_substring_between(source_part_1 "${source_content}" "\n" "namespace ")
        string_substring_from(source_part_2 "${source_content}" "namespace ")
        string(PREPEND source_part_2 "namespace ")
        string(STRIP "${header_content}" header_content)
        string(STRIP "${source_part_1}" source_part_1)
        string(STRIP "${source_part_2}" source_part_2)
        string(APPEND new_header_content "${header_content}" "\n" "\n")
        if(NOT "" STREQUAL "${source_part_1}")
            string(APPEND new_header_content "${source_part_1}" "\n" "\n")
        endif()
        string(APPEND new_header_content "${source_part_2}" "\n")
        cmake_path(RELATIVE_PATH header BASE_DIRECTORY "${PROJECT_SOURCE_DIR}/src/main/cpp" OUTPUT_VARIABLE new_header_path)
        set(new_header_path "${PROJECT_BINARY_DIR}/generated/src/main/cpp/${new_header_path}")
        get_filename_component(new_header_dir "${new_header_path}" DIRECTORY)
        cmake_path(RELATIVE_PATH new_header_path BASE_DIRECTORY "${PROJECT_SOURCE_DIR}" OUTPUT_VARIABLE new_header_relative_path)

        file(MAKE_DIRECTORY "${new_header_dir}")
        file(WRITE "${new_header_path}" "${new_header_content}")

        list(APPEND GENERATED_SOURCES "${new_header_relative_path}")
    endforeach()

    add_library("${PROJECT_NAME}" INTERFACE
        ${GENERATED_SOURCES}
    )
    file(MAKE_DIRECTORY "${PROJECT_BINARY_DIR}/generated/src/main/cpp/exqudens")
    file(WRITE "${PROJECT_BINARY_DIR}/generated/src/main/cpp/exqudens/ThreadsExport.hpp" "#define EXQUDENS_THREADS_EXPORT\n")
    target_include_directories("${PROJECT_NAME}" INTERFACE
        "$<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/generated/src/main/cpp>"
        "$<INSTALL_INTERFACE:include>"
    )
else()
    add_library("${PROJECT_NAME}"
        "src/main/cpp/exqudens/Macros.hpp"
        "src/main/cpp/exqudens/ThreadPool.hpp"
        "src/main/cpp/exqudens/ThreadPool.cpp"
    )
    generate_export_header("${PROJECT_NAME}" BASE_NAME "EXQUDENS_THREADS" EXPORT_FILE_NAME
        "generated/src/main/cpp/exqudens/ThreadsExport.hpp"
    )
    if(NOT "${BUILD_SHARED_LIBS}")
        set_target_properties("${PROJECT_NAME}" PROPERTIES COMPILE_FLAGS -DEXQUDENS_THREADS_STATIC_DEFINE)
    endif()
    target_include_directories("${PROJECT_NAME}" PUBLIC
        "$<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/generated/src/main/cpp>"
        "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src/main/cpp>"
        "$<INSTALL_INTERFACE:include>"
    )
    set_target_properties("${PROJECT_NAME}" PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY                "${PROJECT_BINARY_DIR}/main/bin"
        RUNTIME_OUTPUT_DIRECTORY_RELEASE        "${PROJECT_BINARY_DIR}/main/bin"
        RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_BINARY_DIR}/main/bin"
        RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL     "${PROJECT_BINARY_DIR}/main/bin"
        RUNTIME_OUTPUT_DIRECTORY_DEBUG          "${PROJECT_BINARY_DIR}/main/bin"

        ARCHIVE_OUTPUT_DIRECTORY                "${PROJECT_BINARY_DIR}/main/lib"
        ARCHIVE_OUTPUT_DIRECTORY_RELEASE        "${PROJECT_BINARY_DIR}/main/lib"
        ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_BINARY_DIR}/main/lib"
        ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL     "${PROJECT_BINARY_DIR}/main/lib"
        ARCHIVE_OUTPUT_DIRECTORY_DEBUG          "${PROJECT_BINARY_DIR}/main/lib"

        LIBRARY_OUTPUT_DIRECTORY                "${PROJECT_BINARY_DIR}/main/lib"
        LIBRARY_OUTPUT_DIRECTORY_RELEASE        "${PROJECT_BINARY_DIR}/main/lib"
        LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_BINARY_DIR}/main/lib"
        LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL     "${PROJECT_BINARY_DIR}/main/lib"
        LIBRARY_OUTPUT_DIRECTORY_DEBUG          "${PROJECT_BINARY_DIR}/main/lib"
    )
endif()
set_property(TARGET "${PROJECT_NAME}" PROPERTY "VERSION" "${PROJECT_VERSION}")
set_property(TARGET "${PROJECT_NAME}" PROPERTY "SOVERSION" "${PROJECT_VERSION_MAJOR}")
set_property(TARGET "${PROJECT_NAME}" PROPERTY "INTERFACE_${PROJECT_NAME}_MAJOR_VERSION" "${PROJECT_VERSION_MAJOR}")
set_property(TARGET "${PROJECT_NAME}" APPEND PROPERTY "COMPATIBLE_INTERFACE_STRING" "${PROJECT_NAME}_MAJOR_VERSION")
install(
    TARGETS "${PROJECT_NAME}"
    EXPORT "${PROJECT_NAME}-targets"
    INCLUDES DESTINATION "include"
    RUNTIME DESTINATION "bin"
    LIBRARY DESTINATION "lib"
    ARCHIVE DESTINATION "lib"
)
install(
    EXPORT "${PROJECT_NAME}-targets"
    DESTINATION "cmake"
    NAMESPACE "${PROJECT_NAME}::"
    FILE "${PROJECT_NAME}-targets.cmake"
)
include(CMakePackageConfigHelpers)
configure_package_config_file(
    "${PROJECT_SOURCE_DIR}/package-config.cmake.in"
    "${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config.cmake"
    INSTALL_DESTINATION "cmake"
)
write_basic_package_version_file(
    "${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake"
    VERSION "${PROJECT_VERSION}"
    COMPATIBILITY "ExactVersion"
)
install(
    FILES "${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config.cmake"
    "${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake"
    DESTINATION "cmake"
)
if("${INTERFACE_ONLY}")
    install(
        DIRECTORY "${PROJECT_BINARY_DIR}/generated/src/main/cpp/"
        DESTINATION "include"
        FILES_MATCHING
        PATTERN "*.h"
        PATTERN "*.hpp"
    )
else()
    install(
        DIRECTORY "${PROJECT_BINARY_DIR}/generated/src/main/cpp/"
                  "src/main/cpp/"
        DESTINATION "include"
        FILES_MATCHING
        PATTERN "*.h"
        PATTERN "*.hpp"
    )
endif()

add_library("test-lib" INTERFACE
    "src/test/cpp/exqudens/TestApplication.hpp"
    "src/test/cpp/exqudens/TestUtils.hpp"
    "src/test/cpp/exqudens/Tests.hpp"
)
target_include_directories("test-lib" INTERFACE
    "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src/test/cpp>"
    "$<INSTALL_INTERFACE:include>"
)
target_link_libraries("test-lib" INTERFACE
    "${PROJECT_NAME}"
    "GTest::gmock"
    "GTest::gtest"
    "GTest::gmock_main"
    "GTest::gtest_main"
)
set_target_properties("test-lib" PROPERTIES
    CXX_STANDARD 23
)

add_executable("test-app" "src/test/cpp/main.cpp")
target_link_libraries("test-app"
    "test-lib"
)
set_target_properties("test-app" PROPERTIES
    CXX_STANDARD 23

    RUNTIME_OUTPUT_DIRECTORY                "${PROJECT_BINARY_DIR}/test/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE        "${PROJECT_BINARY_DIR}/test/bin"
    RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_BINARY_DIR}/test/bin"
    RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL     "${PROJECT_BINARY_DIR}/test/bin"
    RUNTIME_OUTPUT_DIRECTORY_DEBUG          "${PROJECT_BINARY_DIR}/test/bin"

    ARCHIVE_OUTPUT_DIRECTORY                "${PROJECT_BINARY_DIR}/test/lib"
    ARCHIVE_OUTPUT_DIRECTORY_RELEASE        "${PROJECT_BINARY_DIR}/test/lib"
    ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_BINARY_DIR}/test/lib"
    ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL     "${PROJECT_BINARY_DIR}/test/lib"
    ARCHIVE_OUTPUT_DIRECTORY_DEBUG          "${PROJECT_BINARY_DIR}/test/lib"

    LIBRARY_OUTPUT_DIRECTORY                "${PROJECT_BINARY_DIR}/test/lib"
    LIBRARY_OUTPUT_DIRECTORY_RELEASE        "${PROJECT_BINARY_DIR}/test/lib"
    LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_BINARY_DIR}/test/lib"
    LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL     "${PROJECT_BINARY_DIR}/test/lib"
    LIBRARY_OUTPUT_DIRECTORY_DEBUG          "${PROJECT_BINARY_DIR}/test/lib"
)
if("${BUILD_SHARED_LIBS}")
    add_custom_command(TARGET "test-app"
        POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy_directory "$<TARGET_PROPERTY:${PROJECT_NAME},RUNTIME_OUTPUT_DIRECTORY>" "$<TARGET_PROPERTY:test-app,RUNTIME_OUTPUT_DIRECTORY>"
        COMMAND "${CMAKE_COMMAND}" -E copy_directory "${CONAN_INSTALL_PREFIX}/bin" "$<TARGET_PROPERTY:test-app,RUNTIME_OUTPUT_DIRECTORY>"
        VERBATIM
    )
endif()

gtest_discover_tests("test-app"
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}/test/bin"
    PROPERTIES ENVIRONMENT "PARENT_PATH=;PATH="
)

add_custom_target("cmake-test"
    COMMAND "${CMAKE_CTEST_COMMAND}" --preset "${PRESET_NAME}"
    DEPENDS "test-app"
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
    VERBATIM
)

add_custom_target("cmake-install" ALL
    COMMAND "${CMAKE_COMMAND}" --install "${PROJECT_BINARY_DIR}" --prefix "${CMAKE_INSTALL_PREFIX}"
    DEPENDS ${TARGET_CMAKE_INSTALL_DEPENDS_ON}
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
    VERBATIM
)

add_custom_target("conan-export"
    COMMAND "${CONAN_COMMAND}"
            export-pkg
            --force
            "${PROJECT_SOURCE_DIR}/conanfile.py"
            #"gitlab-group+gitlab-sub-group+${PROJECT_NAME}/stable"
            --package-folder
            "${CMAKE_INSTALL_PREFIX}"
            ${CONAN_SETTINGS}
            ${CONAN_OPTIONS}
    DEPENDS "cmake-install"
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
    VERBATIM
)
