cmake_minimum_required(VERSION 3.16)
project(dda_reference LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_library(voxel_grid voxel_grid.cpp)
target_include_directories(voxel_grid PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

add_executable(dda_reference main.cpp)
target_link_libraries(dda_reference PRIVATE voxel_grid)

add_executable(dda_tests tests.cpp)
target_link_libraries(dda_tests PRIVATE voxel_grid)

enable_testing()
add_test(NAME dda_tests COMMAND dda_tests)
