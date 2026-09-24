GNAT    := gnatmake
FLAGS   := -gnatwa -gnat2022
OBJ_DIR := obj
BIN_DIR := bin
TUI_INC := -Ithird_party/terminal_ui
# ONCE=1 → single frame, no animation
ONCE    ?=

.PHONY: all test demo play run live once clean

all: $(BIN_DIR)/tests $(BIN_DIR)/demo_play

$(BIN_DIR)/tests: src/*.ads src/*.adb tests/tests.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(FLAGS) -D $(OBJ_DIR) -Isrc tests/tests.adb -o $(BIN_DIR)/tests

$(BIN_DIR)/demo_play: src/*.ads src/*.adb demo/demo_play.adb third_party/terminal_ui/*.ads third_party/terminal_ui/*.adb
	mkdir -p $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) $(FLAGS) -D $(OBJ_DIR) -Isrc $(TUI_INC) demo/demo_play.adb -o $(BIN_DIR)/demo_play

test: $(BIN_DIR)/tests
	$(BIN_DIR)/tests

# Default: brief live clock (override with ONCE=1).
demo play run live: $(BIN_DIR)/demo_play
ifeq ($(ONCE),1)
	$(BIN_DIR)/demo_play --once
else
	$(BIN_DIR)/demo_play --live
endif

# Single frame (no clear / no animation).
once: $(BIN_DIR)/demo_play
	$(BIN_DIR)/demo_play --once

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR)
