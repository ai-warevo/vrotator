cmake_minimum_required(VERSION 3.15)
project(VRotatorClicker LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enforce static runtime library linking to generate a single standalone executable
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

# Explicitly outputs binary target straight into the build folder root path
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

# Expose global headers folder workspace tree
include_directories(include)

# Automate source discovery tree
file(GLOB_RECURSE CLICKER_SOURCES "src/*.cpp")

# Core Binary Target Definition
add_executable(vrotator_clicker ${CLICKER_SOURCES})

# Hardware Subsystem Linkage: Requires native OS graphics and peripheral preemption hooks
target_link_libraries(vrotator_clicker PRIVATE gdi32 user32)
