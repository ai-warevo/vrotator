#define CATCH_CONFIG_MAIN

#include "catch_amalgamated.hpp"

TEST_CASE("example") {
    REQUIRE(1 + 1 == 2);
}

// Catch2 v3 auto-generates the entry point when linking catch_amalgamated.cpp 
// with the core test suite definition layers.
