cmake_minimum_required(VERSION 3.15)
project(VRotatorClicker LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")

file(GLOB_RECURSE CLICKER_CORE_SOURCES 
    "src/input_engine.cpp"
    "src/window_manager.cpp"
    "src/pixel_reader.cpp"
)

add_executable(vrotator_clicker src/main.cpp ${CLICKER_CORE_SOURCES})
target_link_libraries(vrotator_clicker PRIVATE gdi32 user32)
target_include_directories(vrotator_clicker PRIVATE "${CMAKE_SOURCE_DIR}/include")

# ==========================================
# AUTOMATED TESTING SUITE ARCHITECTURE (Catch2 v3.16.0)
# ==========================================
option(ENABLE_VROTATOR_TESTS "Compile and link the native Catch2 test suite targets" ON)

if(ENABLE_VROTATOR_TESTS)
    enable_testing()

    set(CATCH_VERSION "v3.16.0")
    set(CATCH_DOWNLOAD_BASE "https://github.com/catchorg/Catch2/releases/download/${CATCH_VERSION}")
    set(CATCH_HPP_URL  "${CATCH_DOWNLOAD_BASE}/catch_amalgamated.hpp")
    set(CATCH_CPP_URL "${CATCH_DOWNLOAD_BASE}/catch_amalgamated.cpp")
    set(CATCH_DIR "${CMAKE_CURRENT_SOURCE_DIR}/tests/catch2")
    set(CATCH_HPP  "${CATCH_DIR}/catch_amalgamated.hpp")
    set(CATCH_CPP "${CATCH_DIR}/catch_amalgamated.cpp")

    if(NOT EXISTS "${CATCH_HPP}")
        message(STATUS "Downloading Catch2 v3.16.0 amalgamated header...")
        file(MAKE_DIRECTORY "${CATCH_DIR}")
        file(DOWNLOAD "${CATCH_HPP_URL}" "${CATCH_HPP}" SHOW_PROGRESS)
    endif()

    if(NOT EXISTS "${CATCH_CPP}")
        message(STATUS "Downloading Catch2 v3.16.0 amalgamated implementation...")
        file(DOWNLOAD "${CATCH_CPP_URL}" "${CATCH_CPP}" SHOW_PROGRESS)
    endif()

    file(GLOB_RECURSE TEST_SOURCES "tests/*.cpp")
    list(REMOVE_ITEM TEST_SOURCES "${CATCH_CPP}")

    if(TEST_SOURCES STREQUAL "")
        message(WARNING "No test files found in tests/ directory.")
    endif()

    add_executable(vrotator_tests ${TEST_SOURCES} ${CLICKER_CORE_SOURCES} ${CATCH_CPP})
    target_link_libraries(vrotator_tests PRIVATE gdi32 user32)
    target_include_directories(vrotator_tests PRIVATE
        "${CMAKE_SOURCE_DIR}/include"
        "${CMAKE_SOURCE_DIR}/src"
        "${CATCH_DIR}"
    )

    add_test(NAME CoreUnitTests COMMAND vrotator_tests)
endif()
