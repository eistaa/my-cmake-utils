project(insert_processed)
cmake_minimum_required(VERSION 2.8)

include(../../ConfigureFileFromFiles.cmake)

configure_file_from_files(INPUT "file.txt.in" OUTPUT "file.txt"
                          READ_FROM "data.txt" "data2.txt"
                          TOKEN "to_be_inserted" "some_more_data"
                          PREFIX "TEXT: \"" "SECOND: "
                          SUFFIX "\"<SEMI-COLON>" "!!!"
                          ESCAPE_BACKSLASH ESCAPE_QUOTES)
