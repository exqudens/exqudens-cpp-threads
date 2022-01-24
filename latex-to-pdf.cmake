math(EXPR SCRIPT_ARGUMENTS_MAX_INDEX "${CMAKE_ARGC} - 1")

foreach(i RANGE "${SCRIPT_ARGUMENTS_MAX_INDEX}")
    list(APPEND SCRIPT_ARGUMENTS "${CMAKE_ARGV${i}}")
endforeach()

function(script_get_os var args)
    set(oneValueArgs "--os")
    cmake_parse_arguments("script_get_os" "" "${oneValueArgs}" "" "${args}")
    set("${var}" "${script_get_os_--os}" PARENT_SCOPE)
endfunction()

function(script_get_path var args)
    set(oneValueArgs "--path")
    cmake_parse_arguments("script_get_path" "" "${oneValueArgs}" "" "${args}")
    set("${var}" "${script_get_path_--path}" PARENT_SCOPE)
endfunction()

function(script_get_file_name var args)
    set(oneValueArgs "--file-name")
    cmake_parse_arguments("script_get_file_name" "" "${oneValueArgs}" "" "${args}")
    set("${var}" "${script_get_file_name_--file-name}" PARENT_SCOPE)
endfunction()

function(script_get_dir var args)
    set(oneValueArgs "--dir")
    cmake_parse_arguments("script_get_dir" "" "${oneValueArgs}" "" "${args}")
    set("${var}" "${script_get_dir_--dir}" PARENT_SCOPE)
endfunction()

script_get_os(SCRIPT_OS "${SCRIPT_ARGUMENTS}")
script_get_path(SCRIPT_PATH "${SCRIPT_ARGUMENTS}")
script_get_file_name(SCRIPT_FILE_NAME "${SCRIPT_ARGUMENTS}")
script_get_dir(SCRIPT_DIR "${SCRIPT_ARGUMENTS}")

if("" STREQUAL "${SCRIPT_OS}")
    set(SCRIPT_OS "Windows")
endif()

if("" STREQUAL "${SCRIPT_PATH}")
    if("Windows" STREQUAL "${SCRIPT_OS}")
        set(SCRIPT_PATH "C:/Program Files/MiKTeX/miktex/bin/x64")
    else()
        message(FATAL_ERROR "Unsupported 'SCRIPT_OS': '${SCRIPT_OS}'")
    endif()
endif()

if("" STREQUAL "${SCRIPT_FILE_NAME}")
    set(SCRIPT_FILE_NAME "refman")
endif()

if("" STREQUAL "${SCRIPT_DIR}")
    message(FATAL_ERROR "Unsupported 'SCRIPT_DIR': '${SCRIPT_DIR}'")
endif()

set(ENV{PATH} "${SCRIPT_PATH}")

find_program(PDFLATEX_COMMAND NAMES "pdflatex.exe" "pdflatex" NO_CACHE)
find_program(MAKEINDEX_COMMAND NAMES "makeindex.exe" "makeindex" NO_CACHE)

set(SCRIPT_LATEX_COUNT "8")
set(SCRIPT_LATEX_LOG_FIND_TOKEN "Rerun (LaTeX|to get cross-references right)")

execute_process(
    COMMAND "${PDFLATEX_COMMAND}" "${SCRIPT_FILE_NAME}"
    WORKING_DIRECTORY "${SCRIPT_DIR}"
    OUTPUT_QUIET
    #ERROR_QUIET
    COMMAND_ECHO "STDERR"
    ENCODING "UTF-8"
    COMMAND_ERROR_IS_FATAL ANY
)
execute_process(
    COMMAND "${MAKEINDEX_COMMAND}" "${SCRIPT_FILE_NAME}.idx"
    WORKING_DIRECTORY "${SCRIPT_DIR}"
    OUTPUT_QUIET
    #ERROR_QUIET
    COMMAND_ECHO "STDERR"
    ENCODING "UTF-8"
    COMMAND_ERROR_IS_FATAL ANY
)
execute_process(
    COMMAND "${PDFLATEX_COMMAND}" "${SCRIPT_FILE_NAME}"
    WORKING_DIRECTORY "${SCRIPT_DIR}"
    OUTPUT_QUIET
    #ERROR_QUIET
    COMMAND_ECHO "STDERR"
    ENCODING "UTF-8"
    COMMAND_ERROR_IS_FATAL ANY
)

file(READ "${SCRIPT_DIR}/${SCRIPT_FILE_NAME}.log" SCRIPT_PDFLATEX_LOG)
string(FIND "${SCRIPT_PDFLATEX_LOG}" "${SCRIPT_LATEX_LOG_FIND_TOKEN}" SCRIPT_LATEX_LOG_FIND_TOKEN_INDEX)

foreach(i RANGE "7")
    if ("-1" STREQUAL "${SCRIPT_LATEX_LOG_FIND_TOKEN_INDEX}")
        break()
    endif()
    if("${SCRIPT_LATEX_COUNT}" LESS_EQUAL "0")
        break()
    endif()
    message("Rerunning latex....")
    execute_process(
        COMMAND "${SCRIPT_PATH}/pdflatex" "${SCRIPT_FILE_NAME}"
        WORKING_DIRECTORY "${SCRIPT_DIR}"
        OUTPUT_QUIET
        #ERROR_QUIET
        COMMAND_ECHO "STDERR"
        ENCODING "UTF-8"
        COMMAND_ERROR_IS_FATAL ANY
    )
    math(EXPR SCRIPT_LATEX_COUNT "${SCRIPT_LATEX_COUNT} - 1")
    file(READ "${SCRIPT_DIR}/${SCRIPT_FILE_NAME}.log" SCRIPT_PDFLATEX_LOG)
    string(FIND "${SCRIPT_PDFLATEX_LOG}" "${SCRIPT_LATEX_LOG_FIND_TOKEN}" SCRIPT_LATEX_LOG_FIND_TOKEN_INDEX)
endforeach()

execute_process(
    COMMAND "${MAKEINDEX_COMMAND}" "${SCRIPT_FILE_NAME}.idx"
    WORKING_DIRECTORY "${SCRIPT_DIR}"
    OUTPUT_QUIET
    #ERROR_QUIET
    COMMAND_ECHO "STDERR"
    ENCODING "UTF-8"
    COMMAND_ERROR_IS_FATAL ANY
)
execute_process(
    COMMAND "${PDFLATEX_COMMAND}" "${SCRIPT_FILE_NAME}"
    WORKING_DIRECTORY "${SCRIPT_DIR}"
    OUTPUT_QUIET
    #ERROR_QUIET
    COMMAND_ECHO "STDERR"
    ENCODING "UTF-8"
    COMMAND_ERROR_IS_FATAL ANY
)
