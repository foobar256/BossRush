# Repository Guidelines

## Project Structure & Module Organization
This is a modern Godot project for a topdown shooter that uses 3D models. The root
contains the engine config and project assets.
- `project.godot` is the project entry and engine settings (edit via the Godot editor UI).
- `icon.svg` and `icon.svg.import` are the default project icon and its import metadata.
As the project grows, keep game scenes in `scenes/`, scripts in `scripts/`, and reusable assets in `assets/` (e.g., `assets/sprites/`, `assets/audio/`).

## Build, Test, and Development Commands
Godot projects are typically run via the editor.
- Prefer headless load (print errors, then quit): `godot --headless --quit`
- Open in editor: `godot --editor` (or use the Godot launcher UI).
- Run the project: `godot`
After code changes, run the headless load command and fix any reported issues.
Never ask to verify; just verify by running the headless load command.
Optional linting (third-party): `gdlint scripts/ scenes/`
Optional formatting (third-party): `gdformat scripts/ scenes/`
Lint/format tooling: https://github.com/Scony/godot-gdscript-toolkit
Shared git hook (optional): copy `scripts/git-hooks/pre-commit` to `.git/hooks/pre-commit` and `chmod +x` it.

## Coding Style & Naming Conventions
Use GDScript conventions throughout:
- Indent with 4 spaces; keep lines under ~100 chars when practical.
- Use `snake_case` for files, variables, and functions; `PascalCase` for classes/scenes (e.g., `player_controller.gd`, `PlayerController.tscn`).
- Prefer composition over inheritance; keep scripts small and attach to single-purpose scenes.
- Use typed GDScript, `@export` for editor-facing values, and `@onready` for node refs.
- Favor `NodePath`-free refs by using named child nodes and `get_node()` only at setup time.
- Group input actions in `project.godot` and reference by action name, not raw key codes.
- Keep Godot settings changes in `project.godot` and prefer editor-driven changes to avoid config drift.

## Testing Guidelines
This project now has automated tests in the `tests/` directory. The test framework includes:

- **Test Runner**: `tests/test_runner.tscn` - Scene for running tests in Godot
- **Test Script**: `tests/run_tests.gd` - Main test runner script
- **Test Suite**: `tests/test_game_over_window.gd` - Example test suite with 6 test categories
- **Documentation**: `tests/README.md` - Complete testing documentation

### Running Tests
- **Headless mode**: `godot --headless --quit tests/test_runner.tscn` (Always use `--quit` to avoid stalling)
- **Pre-commit hook**: Tests run automatically when committing (see `scripts/git-hooks/pre-commit`)

### When to Write Tests
**Always create automated tests when making changes if it's a good idea to do so.** This includes:
- New features or functionality
- Bug fixes (add regression tests)
- UI components and window systems
- Game state management
- Signal connections and event handling
- Integration points between systems

### Writing Tests
- Use descriptive test names that mirror scene or script names
- Follow the pattern in `tests/test_game_over_window.gd` as a template
- Document the framework in this file when adding new test categories
- Ensure tests can run in headless mode for CI/CD

## Commit & Pull Request Guidelines
Use clear, imperative commit messages (e.g., "Add player movement").
For pull requests:
- Include a short summary, testing notes (manual or automated), and screenshots or short clips for visual changes.
- Link relevant issues or design notes when applicable.

## Configuration Tips
Keep `project.godot` changes minimal and reviewed. Avoid hand-editing `icon.svg.import` unless you know the Godot import pipeline implications.
