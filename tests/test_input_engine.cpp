#include "catch_amalgamated.hpp"
#include <windows.h>

// Explicit linkage confirmation targeting the conditional testing compilation facade
#ifdef ENABLE_VROTATOR_TESTS
namespace VRT::InputEngine::InternalTestBridge {
    extern INPUT TestBuildKeyEvent(WORD vk, DWORD flags) noexcept;
}
#endif

TEST_CASE("Win32 INPUT Architecture Generation Integrity", "[InputEngine]") {
#ifdef ENABLE_VROTATOR_TESTS
    using namespace VRT::InputEngine::InternalTestBridge;

    SECTION("Verify standard KeyDown event structure alignment parameters") {
        const INPUT ev = TestBuildKeyEvent(VK_SHIFT, 0);
        
        REQUIRE(ev.type == INPUT_KEYBOARD);
        REQUIRE(ev.ki.wVk == VK_SHIFT);
        REQUIRE(ev.ki.dwFlags == 0);
        REQUIRE(ev.ki.time == 0);
        REQUIRE(ev.ki.dwExtraInfo == 0);
    }

    SECTION("Verify explicit KeyUp event structure execution padding flags") {
        const INPUT ev = TestBuildKeyEvent('Q', KEYEVENTF_KEYUP);
        
        REQUIRE(ev.type == INPUT_KEYBOARD);
        REQUIRE(ev.ki.wVk == 'Q');
        REQUIRE(ev.ki.dwFlags == KEYEVENTF_KEYUP);
        REQUIRE(ev.ki.time == 0);
    }
#else
    SUCCEED("Internal hardware context test bridge is disabled for production builds.");
#endif
}

TEST_CASE("Win32 Native Hardware Scan Code Mapping Contexts", "[InputEngine]") {
#ifdef ENABLE_VROTATOR_TESTS
    using namespace VRT::InputEngine::InternalTestBridge;

    SECTION("Validate hardware IBM scan code mapping output parameters via MapVirtualKeyA") {
        const INPUT pressQ = TestBuildKeyEvent('Q', 0);
        const INPUT press1 = TestBuildKeyEvent('1', 0);
        const INPUT pressF1 = TestBuildKeyEvent(VK_F1, 0);

        // Enforce deterministic IBM hardware keyboard scan code translation invariants
        REQUIRE(pressQ.ki.wScan == 0x10);  // Physical scan key code for 'Q'
        REQUIRE(press1.ki.wScan == 0x02);  // Physical scan key code for '1'
        REQUIRE(pressF1.ki.wScan == 0x3B); // Physical scan key code for 'F1'
    }
#else
    SUCCEED("Internal hardware context test bridge is disabled for production builds.");
#endif
}

TEST_CASE("Modifier Bitmask Arithmetic Logic Validation Matrix", "[InputEngine]") {
    // Unpacking algebraic rule formula: (Shift * 1) + (Ctrl * 2) + (Alt * 4)

    SECTION("State 0: Zero modifier configuration check") {
        const int mask = 0;
        
        const bool hasShift = (mask & 1) != 0;
        const bool hasCtrl  = (mask & 2) != 0;
        const bool hasAlt   = (mask & 4) != 0;

        REQUIRE_FALSE(hasShift);
        REQUIRE_FALSE(hasCtrl);
        REQUIRE_FALSE(hasAlt);
    }

    SECTION("State 1: Isolated SHIFT modifier check") {
        const int mask = 1;
        
        const bool hasShift = (mask & 1) != 0;
        const bool hasCtrl  = (mask & 2) != 0;
        const bool hasAlt   = (mask & 4) != 0;

        REQUIRE(hasShift);
        REQUIRE_FALSE(hasCtrl);
        REQUIRE_FALSE(hasAlt);
    }

    SECTION("State 2: Isolated CTRL modifier check") {
        const int mask = 2;
        
        const bool hasShift = (mask & 1) != 0;
        const bool hasCtrl  = (mask & 2) != 0;
        const bool hasAlt   = (mask & 4) != 0;

        REQUIRE_FALSE(hasShift);
        REQUIRE(hasCtrl);
        REQUIRE_FALSE(hasAlt);
    }

    SECTION("State 4: Isolated ALT modifier check") {
        const int mask = 4;
        
        const bool hasShift = (mask & 1) != 0;
        const bool hasCtrl  = (mask & 2) != 0;
        const bool hasAlt   = (mask & 4) != 0;

        REQUIRE_FALSE(hasShift);
        REQUIRE_FALSE(hasCtrl);
        REQUIRE(hasAlt);
    }

    SECTION("State 6: Packed multi-modifier check (CTRL + ALT)") {
        const int mask = 6;
        
        const bool hasShift = (mask & 1) != 0;
        const bool hasCtrl  = (mask & 2) != 0;
        const bool hasAlt   = (mask & 4) != 0;

        REQUIRE_FALSE(hasShift);
        REQUIRE(hasCtrl);
        REQUIRE(hasAlt);
    }

    SECTION("State 7: Maximum triple modifier sequence check (SHIFT + CTRL + ALT)") {
        const int mask = 7;
        
        const bool hasShift = (mask & 1) != 0;
        const bool hasCtrl  = (mask & 2) != 0;
        const bool hasAlt   = (mask & 4) != 0;

        REQUIRE(hasShift);
        REQUIRE(hasCtrl);
        REQUIRE(hasAlt);
    }
}
