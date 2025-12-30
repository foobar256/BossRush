# Game Over Window Tests

This directory contains automated tests for game over and cursor behavior.

## Test Files

- `test_game_over_window.gd` - Game over window test suite with 6 test categories
- `test_main_game_cursor.gd` - Main game cursor behavior tests
- `test_debug_menu_config.gd` - Debug menu boss config persistence tests
- `run_tests.gd` - Test runner script
- `test_runner.tscn` - Scene for running tests in Godot

## Running Tests

### Method 1: Headless Mode (Recommended for CI/CD)
```bash
godot --headless tests/test_runner.tscn
```

### Method 2: Via Pre-commit Hook
The pre-commit hook automatically runs these tests:
```bash
# Install the hook
cp scripts/git-hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit

# Tests run automatically on commit
git commit -m "Your commit message"
```

## Test Coverage

The test suite covers:

1. **Scene Structure Validation** - Ensures all required nodes exist
2. **Window Centering** - Verifies proper centering with correct anchor presets and offsets
3. **Button Functionality** - Confirms buttons exist and have correct text
4. **Process Mode Behavior** - Tests that window works while game is paused
5. **Signal Connections** - Validates signal emission from button presses
6. **Main Game Integration** - Ensures proper integration with main game scene
7. **Cursor Behavior** - Confirms game over shows the standard cursor and hides crosshair
8. **Debug Menu Config** - Verifies boss config saves and loads persisted values

## Fix Summary

The fixes address two main issues:

1. **Centering**: Updated `game_over_window.tscn` with proper anchor presets and offset values
2. **Button Functionality**: Added `process_mode = Node.PROCESS_MODE_ALWAYS` to allow input when game is paused
3. **Cursor Behavior**: Show standard cursor and hide crosshair on game over

## Files Modified

- `scenes/windows/game_over_window.tscn` - Fixed centering and layout
- `scenes/windows/game_over_window.gd` - Added process mode and safety checks
- `scripts/main_game.gd` - Added process mode handling and visibility management
- `scripts/git-hooks/pre-commit` - Added automated test execution
- `tests/test_main_game_cursor.gd` - Added cursor behavior tests
- `tests/run_tests.gd` - Added cursor tests to the runner
