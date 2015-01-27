# {{{* - LICENSE --------------------------------------------------------------
#
# Copyright (c) 2015 -- Eivind Storm Aarnæs, eistaa
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# ------------------------------------------------------------------------ *}}}

cmake_minimum_required(VERSION 2.8)

include(CMakeParseArguments)

# Function: configure_file_from_files  {{{*

# Function: configure_file_from_files
#  ->  Configure a file using processed data from a set of files.
#
# Read and process a set of files, using the data from the files to configure
# another given file. The processing consist of prepending and appending text
# to the lines read, the text is given on a per file basis.
#
# NB: The four multi value parameters READ_FROM, TOKEN, PREFIX and SUFFIX
#     should all have the same number of elements. If they differ, a fatal
#     error is produced.
#
# PARAMETERS
# ----------
#
# * Single value parameters:
#
#   INPUT  : Path to the file to configure.
#   OUTPUT : Path to write the configured file to.
#
# * Multi value parameters, (all should have the same number of values):
#
#   READ_FROM : List of files to read from.
#   TOKEN     : List of @-tokens in OUTPUT to match to the files in READ_FROM. 
#               Token #i is matched to file #i in READ_FROM.
#   PREFIX    : List of prefixes to prepend to each line in a file from
#               READ_FROM. Prefix #i in this list is used with file #i in
#               READ_FROM.
#               The text '<SEMI-COLON> is replaced by an actual ';'.
#   SUFFIX    : Similar to PREFIX, only difference is that these are suffixes
#               appended to each line in a file from READ_FROM. Suffix #i in
#               this list is used with file #i in READ_FROM.
#               The text '<SEMI-COLON> is replaced by an actual ';'.
#
# * Option parameters:
#
#   ESCAPE_QUOTES        : Escape double quotes (") in the files in READ_FROM.
#   PRESERVE_BLANK_LINES : Do not prepend/append to blank lines.
#
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
    if(${num_from_files} EQUAL ${num_tokens} AND
            ${num_tokens} EQUAL ${num_prefixes} AND
            ${num_prefixes} EQUAL ${num_suffixes})

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
                                      VARIABLE "${token}"
                                      PREFIX "${prefix}"
                                      SUFFIX "${suffix}"
                                      ${optional_args})
            endforeach(i RANGE ${tmp})
        endif(NOT (${num_from_files} EQUAL 0))

        # configure file
        configure_file(${CFFF_INPUT} ${CFFF_OUTPUT})
    else(${num_from_files} EQUAL ${num_tokens} AND
            ${num_tokens} EQUAL ${num_prefixes} AND
            ${num_prefixes} EQUAL ${num_suffixes})
        message(FATAL_ERROR "
There must be the same number of files, tokens, prefixes and suffixes.
")
    endif(${num_from_files} EQUAL ${num_tokens} AND
            ${num_tokens} EQUAL ${num_prefixes} AND
            ${num_prefixes} EQUAL ${num_suffixes})

endfunction(configure_file_from_files)  # *}}}

# *}}}

# Function: process_file_surround  {{{*

# Function: process_file_surround
#  ->  Read a file into a variable, surrounding each line with a prefix/suffix.
#
# Read a file into a variable while prepending and appending text to each line.
#
# PARAMETERS
# ----------
# 
# * Single value parameters:
#
#   READ_FROM : File to read from.
#   VARIABLE  : Variable to save the processed file to.
#   PREFIX    : Prefix to prepend to each line in READ_FROM. The text
#               '<SEMI-COLON>' is replaced by an actual ';'.
#   SUFFIX    : Suffix to append to each line in READ_FROM. The text
#               '<SEMI-COLON>' is replaced by an actual ';'.
#
# * Option parameters:
#
#   ESCAPE_QUOTES        : Escape double quotes (") in READ_FROM.
#   PRESERVE_BLANK_LINES : Do not prepend/append to blank lines.
#   SUB_CMD              : (Internal) Prepend an astrix to status lines.
#
function(process_file_surround)  # {{{*

    # parse arguments
    set(options ESCAPE_QUOTES PRESERVE_BLANK_LINES SUB_CMD)
    set(oneValueArgs READ_FROM VARIABLE PREFIX SUFFIX)
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
    string(REPLACE "<SEMI-COLON>" ";" PFS_SUFFIX "${PFS_SUFFIX}")
    string(REPLACE "<SEMI-COLON>" ";" PFS_PREFIX "${PFS_PREFIX}")

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
    set(${PFS_VARIABLE} "${processed}" PARENT_SCOPE)

endfunction(process_file_surround)  # *}}}

# *}}}
         
# vim: fdm=marker:fmr="{{{*,*}}}":ts=4:sts=4:sw=4:et
