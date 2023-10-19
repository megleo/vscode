cmake_minimum_required(VERSION 3.23)
project(C_Cpoints C)

set(CMAKE_C_STANDARD 11)
add_subdirectory(Chapter17)
include_directories(Chapter17)
add_executable(C_Cpoints main.c)
link_libraries(C_Cpoints chapter17)

