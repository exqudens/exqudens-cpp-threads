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
        "SSL"
        "WARNINGS_TO_ERRORS"
        "TOCTREE_MAXDEPTH"
        "TOCTREE_CAPTION"
        "SOURCE_DIR"
        "BUILD_DIR"
        "TITLE"
        "OUTPUT_DIR"
    )
    set(multiValueKeywords
        "FILES"
        "EXTRA_FILES"
        "TEST_REPORT_FILES"
        "BUILDERS"
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

    if("${verbose}")
        message(STATUS "execute file: '${CMAKE_CURRENT_LIST_FILE}'")
        string(TIMESTAMP currentDateTime "%Y-%m-%d %H:%M:%S")
        message(STATUS "currentDateTime: '${currentDateTime}'")
    endif()

    if("${${currentFunctionName}_SSL}" STREQUAL "")
        set(ssl "TRUE")
    else()
        if("${${currentFunctionName}_SSL}")
            set(ssl "TRUE")
        else()
            set(ssl "FALSE")
        endif()
    endif()

    if("${${currentFunctionName}_WARNINGS_TO_ERRORS}" STREQUAL "")
        set(warningsToErrors "TRUE")
    else()
        if("${${currentFunctionName}_WARNINGS_TO_ERRORS}")
            set(warningsToErrors "TRUE")
        else()
            set(warningsToErrors "FALSE")
        endif()
    endif()

    if("${${currentFunctionName}_TOCTREE_MAXDEPTH}" STREQUAL "")
        set(toctreeMaxdepth "2")
    else()
        set(toctreeMaxdepth "${${currentFunctionName}_TOCTREE_MAXDEPTH}")
    endif()

    if("${${currentFunctionName}_TOCTREE_CAPTION}" STREQUAL "")
        set(toctreeCaption "Contents:")
    else()
        set(toctreeCaption "${${currentFunctionName}_TOCTREE_CAPTION}")
    endif()

    if("${${currentFunctionName}_SOURCE_DIR}" STREQUAL "")
        set(sourceDirRelative "doc")
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

    if("${${currentFunctionName}_TITLE}" STREQUAL "")
        set(title "full")
        string(REPLACE " " "_" titleFileName "${title}")
    else()
        set(title "${${currentFunctionName}_TITLE}")
        string(REPLACE " " "_" titleFileName "${title}")
    endif()

    if("${${currentFunctionName}_OUTPUT_DIR}" STREQUAL "")
        set(outputDirRelative "build/doc/${titleFileName}")
    else()
        set(outputDirRelative "${${currentFunctionName}_OUTPUT_DIR}")
        cmake_path(APPEND outputDirRelative "DIR")
        cmake_path(GET "outputDirRelative" PARENT_PATH outputDirRelative)
    endif()

    if("${${currentFunctionName}_BUILDERS}" STREQUAL "")
        set(builders "html" "docx" "pdf")
    else()
        set(builders "${${currentFunctionName}_BUILDERS}")
    endif()

    if("${${currentFunctionName}_FILES}" STREQUAL "")
        set(files
            "flat-table/index.rst"
            "numbered-list/index.rst"
            "traceability/user-requirements.rst"
            "traceability/system-tests.rst"
            "traceability/matrix.rst"
            "test-report/index.rst"
        )
    else()
        set(files "")
        foreach(file IN LISTS "${currentFunctionName}_FILES")
            set(fileRelative "${file}")
            cmake_path(APPEND fileRelative "DIR")
            cmake_path(GET "fileRelative" PARENT_PATH fileRelative)
            list(APPEND files "${fileRelative}")
        endforeach()
    endif()

    if("${${currentFunctionName}_EXTRA_FILES}" STREQUAL "")
        set(extraFiles "")
    else()
        set(extraFiles "${${currentFunctionName}_EXTRA_FILES}")
    endif()

    if("${${currentFunctionName}_TEST_REPORT_FILES}" STREQUAL "")
        set(testReportFiles "None")
    else()
        set(testReportFiles "${${currentFunctionName}_TEST_REPORT_FILES}")
    endif()

    find_program(SPHINX_BUILD_COMMAND
        NAMES "sphinx-build.exe" "sphinx-build"
        PATHS "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/py-env/Scripts"
              "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/py-env/bin"
        NO_CACHE
        NO_DEFAULT_PATH
    )

    # create py-env
    if("${SPHINX_BUILD_COMMAND}" STREQUAL "SPHINX_BUILD_COMMAND-NOTFOUND")
        if("${verbose}")
            message(STATUS "create py-env")
        endif()
        find_program(PYTHON_COMMAND NAMES "py.exe" "py" "python.exe" "python" NO_CACHE REQUIRED)
        execute_process(
            COMMAND "${PYTHON_COMMAND}" "-m" "venv" "${buildDirRelative}/${currentFileNameNoExt}/py-env"
            WORKING_DIRECTORY "${projectDir}"
            COMMAND_ECHO "STDOUT"
            COMMAND_ERROR_IS_FATAL "ANY"
        )
        find_program(PIP_COMMAND
            NAMES "pip.exe" "pip"
            PATHS "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/py-env/Scripts"
                  "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/py-env/bin"
            NO_CACHE
            REQUIRED
            NO_DEFAULT_PATH
        )
        set(command "${PIP_COMMAND}" "install")
        if(NOT "${ssl}")
            list(APPEND command "--trusted-host" "pypi.org" "--trusted-host" "pypi.python.org" "--trusted-host" "files.pythonhosted.org" "-r" "requirements.txt")
        endif()
        list(APPEND command "-r" "cmake/${currentFileNameNoExt}/requirements.txt")
        execute_process(
            COMMAND ${command}
            WORKING_DIRECTORY "${projectDir}"
            COMMAND_ECHO "STDOUT"
            COMMAND_ERROR_IS_FATAL "ANY"
        )
        find_program(SPHINX_BUILD_COMMAND
            NAMES "sphinx-build.exe" "sphinx-build"
            PATHS "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/py-env/Scripts"
                  "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/py-env/bin"
            NO_CACHE
            REQUIRED
            NO_DEFAULT_PATH
        )
    endif()

    # create structure
    if("${verbose}")
        message(STATUS "create structure")
    endif()
    if(EXISTS "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/${titleFileName}")
        file(REMOVE_RECURSE "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/${titleFileName}")
    endif()
    string(JOIN "\n" indexRstContent
        ".. toctree::"
        "   :maxdepth: ${toctreeMaxdepth}"
        "   :caption: ${toctreeCaption}"
        ""
        ""
    )
    foreach(file IN LISTS "files")
        cmake_path(GET "file" PARENT_PATH fileDir)
        cmake_path(GET "file" FILENAME fileName)
        cmake_path(GET "fileName" STEM fileNameNoExt)
        if("${fileDir}" STREQUAL "")
            string(APPEND indexRstContent "   ${fileNameNoExt}" "\n")
            file(COPY "${projectDir}/${sourceDirRelative}/${file}" DESTINATION "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/${titleFileName}")
        else()
            string(APPEND indexRstContent "   ${fileDir}/${fileNameNoExt}" "\n")
            file(MAKE_DIRECTORY "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/${titleFileName}/${fileDir}")
            file(COPY "${projectDir}/${sourceDirRelative}/${file}" DESTINATION "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/${titleFileName}/${fileDir}")
        endif()
    endforeach()
    foreach(file IN LISTS "extraFiles")
        string(FIND "${file}" ">" delimiterIndex)
        if("${delimiterIndex}" EQUAL "-1")
            set(fileSrc "${projectDir}/${sourceDirRelative}/${file}")
            set(fileDst "${file}")
        else()
            string(REPLACE ">" ";" fileParts "${file}")
            list(GET "fileParts" "0" fileSrc)
            list(GET "fileParts" "1" fileDst)
            cmake_path(RELATIVE_PATH "fileSrc" BASE_DIRECTORY "${projectDir}" OUTPUT_VARIABLE fileSrc)
        endif()

        cmake_path(GET "fileDst" PARENT_PATH fileDir)
        if("${fileDir}" STREQUAL "")
            file(COPY "${fileSrc}" DESTINATION "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/${titleFileName}")
        else()
            file(MAKE_DIRECTORY "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/${titleFileName}/${fileDir}")
            file(COPY "${fileSrc}" DESTINATION "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/${titleFileName}/${fileDir}")
        endif()

    endforeach()
    file(WRITE "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/${titleFileName}/index.rst" "${indexRstContent}")
    file(COPY "${projectDir}/${sourceDirRelative}/conf.py" DESTINATION "${projectDir}/${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/${titleFileName}")

    # run doxygen
    if(
        EXISTS "${projectDir}/${buildDirRelative}/doxygen/main/xml/index.xml"
        OR EXISTS "${projectDir}/${buildDirRelative}/doxygen/test/xml/index.xml"
    )
        if(EXISTS "${projectDir}/${buildDirRelative}/doxygen/main/xml/index.xml")
            file(REMOVE_RECURSE "${projectDir}/${buildDirRelative}/doxygen/main")
        endif()
        if(EXISTS "${projectDir}/${buildDirRelative}/doxygen/test/xml/index.xml")
            file(REMOVE_RECURSE "${projectDir}/${buildDirRelative}/doxygen/test")
        endif()
    endif()
    if(
        NOT EXISTS "${projectDir}/${buildDirRelative}/doxygen/main/xml/index.xml"
        OR NOT EXISTS "${projectDir}/${buildDirRelative}/doxygen/test/xml/index.xml"
    )
        if(NOT EXISTS "${projectDir}/${buildDirRelative}/doxygen/main/xml/index.xml")
            execute_process(
                COMMAND "${CMAKE_COMMAND}" "-P" "cmake/run-doxygen.cmake" "--"
                        "SOURCE_DIR" "src/main/cpp"
                        "OUTPUT_DIR" "${buildDirRelative}/doxygen/main"
                WORKING_DIRECTORY "${projectDir}"
                COMMAND_ECHO "STDOUT"
                COMMAND_ERROR_IS_FATAL "ANY"
            )
        endif()
        if(NOT EXISTS "${projectDir}/${buildDirRelative}/doxygen/test/xml/index.xml")
            execute_process(
                COMMAND "${CMAKE_COMMAND}" "-P" "cmake/run-doxygen.cmake" "--"
                        "SOURCE_DIR" "src/test/cpp"
                        "OUTPUT_DIR" "${buildDirRelative}/doxygen/test"
                WORKING_DIRECTORY "${projectDir}"
                COMMAND_ECHO "STDOUT"
                COMMAND_ERROR_IS_FATAL "ANY"
            )
        endif()
    endif()

    foreach(builder IN LISTS "builders")

        # build
        if("${verbose}")
            message(STATUS "build ${builder}")
        endif()
        if(EXISTS "${projectDir}/${outputDirRelative}/${builder}")
            file(REMOVE_RECURSE "${projectDir}/${outputDirRelative}/${builder}")
        endif()
        set(flags "")
        if("${warningsToErrors}")
            list(APPEND "flags" "-W")
        endif()
        list(APPEND "flags"
            "-E"
        )
        execute_process(
            COMMAND "${CMAKE_COMMAND}"
                    "-E"
                    "env"
                    "PROJECT_DIR=${projectDir}"
                    "PROJECT_TITLE=${title}"
                    "PROJECT_TEST_REPORT_FILES=${testReportFiles}"
                    "--"
                    "${SPHINX_BUILD_COMMAND}"
                    ${flags}
                    "-b"
                    "${builder}"
                    "${buildDirRelative}/${currentFileNameNoExt}/${sourceDirRelative}/${titleFileName}"
                    "${outputDirRelative}/${builder}"
            WORKING_DIRECTORY "${projectDir}"
            COMMAND_ECHO "STDOUT"
            COMMAND_ERROR_IS_FATAL "ANY"
        )

    endforeach()

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
