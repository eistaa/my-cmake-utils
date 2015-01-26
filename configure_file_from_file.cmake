
include(CMakeParseArguments)

function(configure_file_from_files)  # {{{*

    # parse arguments
    set(options ESCAPE_QUOTES PRESERVE_BLANK_LINES)
    set(oneValueArgs INPUT OUTPUT)
    set(multiValueArgs READ_FROM TOKEN PREFIX SUFFIX)
    cmake_parse_arguments(CFFF "${options}"
                               "${oneValueArgs}" 
                               "${multiValueArgs}" ${ARGN})

    # message
    message(STATUS "Configuring file: '${CFFF_OUTPUT}' from '${CFFF_INPUT}'")

    # get length of lists
    list(LENGTH CFFF_READ_FROM num_from_files)
    list(LENGTH CFFF_TOKEN     num_tokens)
    list(LENGTH CFFF_PREFIX    num_prefixes)
    list(LENGTH CFFF_SUFFIX    num_suffixes)

    # equal number of arguments
    if((${num_from_files} EQUAL ${num_tokens}) AND
            (${num_tokens} EQUAL ${num_prefixes}) AND
            (${num_prefixes} EQUAL ${num_suffixes}))

        # handle extra args
        set(optional_args "SUB_CMD")
        if(${CFFF_ESCAPE_QUOTES})
            set(optional_args ${optional_args} "ESCAPE_QUOTES")
        endif(${CFFF_ESCAPE_QUOTES})
        if(${CFFF_PRESERVE_BLANK_LINES})
            set(optional_args ${optional_args} "PRESERVE_BLANK_LINES")
        endif(${CFFF_PRESERVE_BLANK_LINES})

        # don't do processing if there are no files
        if(NOT (${num_from_files} EQUAL 0))

            # process all input
            math(EXPR tmp "${num_from_files} - 1")
            foreach(i RANGE ${tmp})
                list(GET CFFF_READ_FROM ${i} read_from)
                list(GET CFFF_TOKEN     ${i} token)
                list(GET CFFF_PREFIX    ${i} prefix)
                list(GET CFFF_SUFFIX    ${i} suffix)

                # read the file to a variable
                process_file_surround(READ_FROM "${read_from}"
                                      TOKEN "${token}"
                                      PREFIX "${prefix}"
                                      SUFFIX "${suffix}"
                                      ${optional_args})
            endforeach(i RANGE ${tmp})
        endif(NOT (${num_from_files} EQUAL 0))

        # configure file
        configure_file(${CFFF_INPUT} ${CFFF_OUTPUT})
    else((${num_from_files} EQUAL ${num_tokens}) AND
            (${num_tokens} EQUAL ${num_prefixes}) AND
            (${num_prefixes} EQUAL ${num_suffixes}))
        message(FATAL_ERROR
                "\nThere must be the same number of files, tokens, prefixes and suffixes.\n")
    endif((${num_from_files} EQUAL ${num_tokens}) AND
            (${num_tokens} EQUAL ${num_prefixes}) AND
            (${num_prefixes} EQUAL ${num_suffixes}))

endfunction(configure_file_from_files)  # *}}}

function(process_file_surround)  # {{{*

    # parse arguments
    set(options ESCAPE_QUOTES PRESERVE_BLANK_LINES SUB_CMD)
    set(oneValueArgs READ_FROM TOKEN PREFIX SUFFIX)
    set(multiValueArgs )
    cmake_parse_arguments(PFS "${options}"
                              "${oneValueArgs}"
                              "${multiValueArgs}" ${ARGN})

    # message
    if(${PFS_SUB_CMD})
        message(STATUS " * Reading file: ${PFS_READ_FROM}")
    else(${PFS_SUB_CMD})
        message(STATUS "Reading file: ${PFS_READ_FROM}")
    endif(${PFS_SUB_CMD})

    # replace SEMI-COLON by ; in suffix and prefix
    string(REPLACE "SEMI-COLON" ";" PFS_SUFFIX "${PFS_SUFFIX}")
    string(REPLACE "SEMI-COLON" ";" PFS_PREFIX "${PFS_PREFIX}")

    # read file
    set(lines )
    file(READ ${PFS_READ_FROM} lines)

    # escape characters
    string(REPLACE ";" "\\;" lines "${lines}")  # protect ; in file
    if(${PFS_ESCAPE_QUOTES})
        string(REGEX REPLACE "\"" "\\\\\"" lines "${lines}")
    endif(${PFS_ESCAPE_QUOTES})

    # turn into list
    string(REGEX REPLACE "\n" ";" lines "${lines}")  # turn into list

    # process each line in the file
    set(processed )
    foreach(line IN LISTS lines)
        string(STRIP "${line}" tmp)
        string(LENGTH "${tmp}" tmp)

        if(${tmp} GREATER 0)
            # line have non-whitespace characters
            set(processed "${processed}${PFS_PREFIX}${line}${PFS_SUFFIX}\n")
        elseif(${PFS_PRESERVE_BLANK_LINES})  
            # blank lines should be kept
            set(processed "${processed}\n")
        endif(${tmp} GREATER 0)  # otherwise; skip blank lines
    endforeach(line IN LISTS lines)

    # store to correct output
    set(${PFS_TOKEN} "${processed}" PARENT_SCOPE)

endfunction(process_file_surround)  # *}}}
         
