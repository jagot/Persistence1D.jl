project(Persistence1D)
cmake_minimum_required(VERSION 2.8)

set(CMAKE_BUILD_TYPE Release)
set(CMAKE_CXX_FLAGS "--std=c++11 -Wall -Wextra -O3")

add_library(persistence1d SHARED persistence1d.cpp)

install(TARGETS persistence1d
  RUNTIME DESTINATION lib
  LIBRARY DESTINATION lib)
