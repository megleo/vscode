cmake_minimum_required(VERSION 3.10)
project(hellocuda LANGUAGES CXX CUDA)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CUDA_ARCHITECTURES 75)
set(CUDA_TOOLKIT)
add_executable(untitled1 main.cu)

set_target_properties(untitled1 PROPERTIES
        CUDA_SEPARABLE_COMPILATION ON)
