BUILD_DIR = build
TARGET = vrotator_clicker.exe
TEST_TARGET = vrotator_tests.exe

all: run

build:
	@if [ ! -d "$(BUILD_DIR)" ]; then cmake -B $(BUILD_DIR); fi
	cmake --build $(BUILD_DIR) --config Release

run: build
	$(BUILD_DIR)/Release/$(TARGET)

# Forces a total clean, builds, and instructs Catch2 to expand and list every test case name explicitly
test: clean
	cmake -B $(BUILD_DIR)
	cmake --build $(BUILD_DIR) --config Release
	$(BUILD_DIR)/Release/$(TEST_TARGET)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all build run test clean
