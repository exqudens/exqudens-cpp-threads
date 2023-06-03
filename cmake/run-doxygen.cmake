cmake_minimum_required(VERSION 3.25 FATAL_ERROR)

cmake_policy(PUSH)
cmake_policy(SET CMP0007 NEW)
cmake_policy(PUSH)
cmake_policy(SET CMP0010 NEW)
cmake_policy(PUSH)
cmake_policy(SET CMP0012 NEW)
cmake_policy(PUSH)
cmake_policy(SET CMP0054 NEW)
cmake_policy(PUSH)
cmake_policy(SET CMP0057 NEW)

function(execute_script args)
    set(currentFunctionName "${CMAKE_CURRENT_FUNCTION}")
    cmake_path(GET "CMAKE_CURRENT_LIST_DIR" PARENT_PATH projectDir)
    cmake_path(GET "CMAKE_CURRENT_LIST_FILE" STEM currentFileNameNoExt)

    set(options)
    set(oneValueKeywords
        "VERBOSE"
        "SOURCE_DIR"
        "BUILD_DIR"
        "OUTPUT_DIR"
    )
    set(multiValueKeywords
        "FILE_PATTERNS"
        "EXCLUDES"
    )

    cmake_parse_arguments("${currentFunctionName}" "${options}" "${oneValueKeywords}" "${multiValueKeywords}" "${args}")

    if(NOT "${${currentFunctionName}_UNPARSED_ARGUMENTS}" STREQUAL "")
        message(FATAL_ERROR "Unparsed arguments: '${${currentFunctionName}_UNPARSED_ARGUMENTS}'")
    endif()

    if("${${currentFunctionName}_VERBOSE}")
        set(verbose "TRUE")
    else()
        set(verbose "FALSE")
    endif()

    if("${${currentFunctionName}_SOURCE_DIR}" STREQUAL "")
        set(sourceDirRelative "src/main/cpp")
    else()
        set(sourceDirRelative "${${currentFunctionName}_SOURCE_DIR}")
        cmake_path(APPEND sourceDirRelative "DIR")
        cmake_path(GET "sourceDirRelative" PARENT_PATH sourceDirRelative)
    endif()

    if("${${currentFunctionName}_BUILD_DIR}" STREQUAL "")
        set(buildDirRelative "build")
    else()
        set(buildDirRelative "${${currentFunctionName}_BUILD_DIR}")
        cmake_path(APPEND buildDirRelative "DIR")
        cmake_path(GET "buildDirRelative" PARENT_PATH buildDirRelative)
    endif()

    if("${${currentFunctionName}_OUTPUT_DIR}" STREQUAL "")
        set(outputDirRelative "build/doxygen/main")
    else()
        set(outputDirRelative "${${currentFunctionName}_OUTPUT_DIR}")
        cmake_path(APPEND outputDirRelative "DIR")
        cmake_path(GET "outputDirRelative" PARENT_PATH outputDirRelative)
    endif()

    if("${${currentFunctionName}_FILE_PATTERNS}" STREQUAL "")
        set(filePatterns "*.h" "*.c" "*.hpp" "*.cpp")
    else()
        set(filePatterns "${${currentFunctionName}_FILE_PATTERNS}")
    endif()

    if("${${currentFunctionName}_EXCLUDES}" STREQUAL "")
        set(excludesRaw "")
    else()
        set(excludesRaw "")
        foreach(excludeRaw IN LISTS "${currentFunctionName}_EXCLUDES")
            cmake_path(APPEND excludeRaw "DIR")
            cmake_path(GET "excludeRaw" PARENT_PATH excludeRaw)
            list(APPEND excludesRaw "${excludeRaw}")
        endforeach()
    endif()

    if("${verbose}")
        message(STATUS "execute file: '${CMAKE_CURRENT_LIST_FILE}'")
        string(TIMESTAMP currentDateTime "%Y-%m-%d %H:%M:%S")
        message(STATUS "currentDateTime: '${currentDateTime}'")
    endif()

    # run doxygen
    if("${verbose}")
        message(STATUS "run doxygen")
    endif()
    if(EXISTS "${projectDir}/${outputDirRelative}")
        file(REMOVE_RECURSE "${projectDir}/${outputDirRelative}")
    endif()
    if(NOT EXISTS "${projectDir}/${outputDirRelative}")
        string(JOIN "\n" doxygenFileContent
            "PROJECT_NAME = \"${currentFileNameNoExt}\""
            "OUTPUT_DIRECTORY = \"${outputDirRelative}\""
            "RECURSIVE = YES"
            "INPUT = \"${sourceDirRelative}\""
            "ENABLE_PREPROCESSING = YES"
            "GENERATE_XML = YES"
            "GENERATE_HTML = NO"
            "GENERATE_LATEX = NO"
            ""
        )
        if(NOT "${filePatterns}" STREQUAL "")
            string(JOIN "\", \"" filePatternsContent ${filePatterns})
            set(filePatternsContent "FILE_PATTERNS = \"${filePatternsContent}\"")
            string(APPEND doxygenFileContent "${filePatternsContent}\n")
        endif()
        if(NOT "${excludesRaw}" STREQUAL "")
            string(JOIN "\", \"" excludeContent ${excludesRaw})
            set(excludeContent "EXCLUDE = \"${excludeContent}\"")
            string(APPEND doxygenFileContent "${excludeContent}\n")
        endif()
        file(WRITE "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/Doxyfile" "${doxygenFileContent}")

        find_program(DOXYGEN_COMMAND NAMES "doxygen.exe" "doxygen" PATHS ENV CONAN_PATH ENV PATH REQUIRED NO_CACHE NO_DEFAULT_PATH)
        file(MAKE_DIRECTORY "${projectDir}/${outputDirRelative}")
        execute_process(
            COMMAND "${DOXYGEN_COMMAND}" "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/Doxyfile"
            WORKING_DIRECTORY "${projectDir}"
            COMMAND_ECHO "STDOUT"
            COMMAND_ERROR_IS_FATAL "ANY"
        )
    endif()

    if("${verbose}")
        string(TIMESTAMP currentDateTime "%Y-%m-%d %H:%M:%S")
        message(STATUS "currentDateTime: '${currentDateTime}'")
    endif()
endfunction()

block()
    set(args "")
    set(argsStarted "FALSE")
    math(EXPR argIndexMax "${CMAKE_ARGC} - 1")
    foreach(i RANGE "0" "${argIndexMax}")
        if("${argsStarted}")
            list(APPEND args "${CMAKE_ARGV${i}}")
        elseif(NOT "${argsStarted}" AND "${CMAKE_ARGV${i}}" STREQUAL "--")
            set(argsStarted "TRUE")
        endif()
    endforeach()
    execute_script("${args}")
endblock()

cmake_policy(POP)
cmake_policy(POP)
cmake_policy(POP)
cmake_policy(POP)
cmake_policy(POP)
