cmake_minimum_required(VERSION 2.8)
set(project test)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/module)
if(CMAKE_COMPILER_IS_GNUCXX)
    add_definitions(-std=gnu++0x)
endif()

SET(BOOST_DIR "/usr/include")

add_subdirectory(gtest)
enable_testing()
include_directories(${gtest_SOURCE_DIR}/include ${gtest_SOURCE_DIR})
#set(CMAKE_BUILD_TYPE Debug)  

FILE(GLOB SRC_LIST "*.cpp")
FIND_PACKAGE(Eigen3 REQUIRED)
FIND_PACKAGE(OpenBLAS REQUIRED)
FIND_PACKAGE(OpenCV REQUIRED)
find_package(Boost COMPONENTS chrono thread date_time program_options filesystem system REQUIRED)



if( CMAKE_BUILD_TYPE STREQUAL "Debug" )
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -g -Wall -Wno-unused-variable -pthread")
else( CMAKE_BUILD_TYPE STREQUAL "Debug" )
        set(CMAKE_BUILD_TYPE "Release")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -O2 -pthread -fopenmp")
endif( CMAKE_BUILD_TYPE STREQUAL "Debug" )

message("Build Type:"${CMAKE_BUILD_TYPE} ${CMAKE_CXX_FLAGS})
SET(EIGEN_UNSUPPORTED_INCLUDE_DIR "${EIGEN3_INCLUDE_DIR}/unsupported")
include_directories(${BOOST_LIBRARYDIR} ${OpenCV_INCLUDE_PATH} ${EIGEN3_INCLUDE_DIR} ${OpenBLAS_INCLUDE_DIR})


add_executable(runUnitTests main.cpp)
target_link_libraries(runUnitTests gtest gtest_main ${OpenBLAS_LIB})
add_test(NAME test COMMAND runUnitTests)
