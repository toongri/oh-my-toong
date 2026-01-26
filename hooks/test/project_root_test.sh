#!/bin/bash
# =============================================================================
# Project Root Detection Tests
# Tests for get_project_root function and state file migration
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOKS_DIR="$(dirname "$SCRIPT_DIR")"

# Test utilities
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

setup_test_env() {
    TEST_TMP_DIR=$(mktemp -d)

    # Store original HOME
    ORIGINAL_HOME="$HOME"

    # Create temporary home directory for isolated tests
    TEST_HOME=$(mktemp -d)
    mkdir -p "$TEST_HOME/.claude"
    export HOME="$TEST_HOME"
}

teardown_test_env() {
    # Restore original HOME
    export HOME="$ORIGINAL_HOME"

    if [[ -d "$TEST_TMP_DIR" ]]; then
        rm -rf "$TEST_TMP_DIR"
    fi
    if [[ -d "$TEST_HOME" ]]; then
        rm -rf "$TEST_HOME"
    fi
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-}"

    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $msg"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local msg="${2:-File should exist: $file}"

    if [[ -f "$file" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $msg"
        return 1
    fi
}

assert_file_not_exists() {
    local file="$1"
    local msg="${2:-File should not exist: $file}"

    if [[ ! -f "$file" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $msg"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local msg="${2:-Directory should exist: $dir}"

    if [[ -d "$dir" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $msg"
        return 1
    fi
}

run_test() {
    local test_name="$1"
    CURRENT_TEST="$test_name"

    setup_test_env

    if "$test_name"; then
        echo "[PASS] $test_name"
        ((TESTS_PASSED++)) || true
    else
        echo "[FAIL] $test_name"
        ((TESTS_FAILED++)) || true
    fi

    teardown_test_env
}

# =============================================================================
# Tests: get_project_root function existence
# =============================================================================

test_get_project_root_function_exists_in_persistent_mode() {
    # persistent-mode.sh should define get_project_root function
    if grep -E '^get_project_root\(\)' "$HOOKS_DIR/persistent-mode.sh" >/dev/null 2>&1; then
        return 0
    else
        echo "ASSERTION FAILED: get_project_root() should be defined in persistent-mode.sh"
        return 1
    fi
}

test_get_project_root_function_exists_in_keyword_detector() {
    # keyword-detector.sh should define get_project_root function
    if grep -E '^get_project_root\(\)' "$HOOKS_DIR/keyword-detector.sh" >/dev/null 2>&1; then
        return 0
    else
        echo "ASSERTION FAILED: get_project_root() should be defined in keyword-detector.sh"
        return 1
    fi
}

test_get_project_root_function_exists_in_session_start() {
    # session-start.sh should define get_project_root function
    if grep -E '^get_project_root\(\)' "$HOOKS_DIR/session-start.sh" >/dev/null 2>&1; then
        return 0
    else
        echo "ASSERTION FAILED: get_project_root() should be defined in session-start.sh"
        return 1
    fi
}

# =============================================================================
# Tests: get_project_root strips nested paths
# =============================================================================

test_get_project_root_strips_claude_sisyphus_suffix() {
    # get_project_root should strip .omt suffix from path
    if grep -A 10 '^get_project_root\(\)' "$HOOKS_DIR/persistent-mode.sh" | grep -q '.omt'; then
        return 0
    else
        echo "ASSERTION FAILED: get_project_root should handle .omt suffix"
        return 1
    fi
}

test_get_project_root_strips_claude_suffix() {
    # get_project_root should strip .claude suffix from path
    if grep -A 10 '^get_project_root\(\)' "$HOOKS_DIR/persistent-mode.sh" | grep -q 'dir="\${dir%/\.claude}"'; then
        return 0
    else
        echo "ASSERTION FAILED: get_project_root should strip .claude suffix"
        return 1
    fi
}

# =============================================================================
# Tests: get_project_root finds markers
# =============================================================================

test_get_project_root_checks_git_marker() {
    # get_project_root should check for .git directory
    if grep -A 20 '^get_project_root\(\)' "$HOOKS_DIR/persistent-mode.sh" | grep -q '\.git'; then
        return 0
    else
        echo "ASSERTION FAILED: get_project_root should check for .git marker"
        return 1
    fi
}

test_get_project_root_checks_claude_md_marker() {
    # get_project_root should check for CLAUDE.md file
    if grep -A 20 '^get_project_root\(\)' "$HOOKS_DIR/persistent-mode.sh" | grep -q 'CLAUDE\.md'; then
        return 0
    else
        echo "ASSERTION FAILED: get_project_root should check for CLAUDE.md marker"
        return 1
    fi
}

test_get_project_root_checks_package_json_marker() {
    # get_project_root should check for package.json file
    if grep -A 20 '^get_project_root\(\)' "$HOOKS_DIR/persistent-mode.sh" | grep -q 'package\.json'; then
        return 0
    else
        echo "ASSERTION FAILED: get_project_root should check for package.json marker"
        return 1
    fi
}

# =============================================================================
# Tests: PROJECT_ROOT variable usage
# =============================================================================

test_persistent_mode_uses_project_root_variable() {
    # persistent-mode.sh should set and use PROJECT_ROOT variable
    if grep -q 'PROJECT_ROOT=.*get_project_root' "$HOOKS_DIR/persistent-mode.sh"; then
        return 0
    else
        echo "ASSERTION FAILED: persistent-mode.sh should set PROJECT_ROOT from get_project_root"
        return 1
    fi
}

test_keyword_detector_uses_project_root_variable() {
    # keyword-detector.sh should set and use PROJECT_ROOT variable
    if grep -q 'PROJECT_ROOT=.*get_project_root' "$HOOKS_DIR/keyword-detector.sh"; then
        return 0
    else
        echo "ASSERTION FAILED: keyword-detector.sh should set PROJECT_ROOT from get_project_root"
        return 1
    fi
}

test_session_start_uses_project_root_variable() {
    # session-start.sh should set and use PROJECT_ROOT variable
    if grep -q 'PROJECT_ROOT=.*get_project_root' "$HOOKS_DIR/session-start.sh"; then
        return 0
    else
        echo "ASSERTION FAILED: session-start.sh should set PROJECT_ROOT from get_project_root"
        return 1
    fi
}

# =============================================================================
# Tests: State files in project-local directory
# =============================================================================

test_persistent_mode_state_dir_is_local() {
    # persistent-mode.sh should use STATE_DIR in $PROJECT_ROOT/.omt/state/
    if grep -q 'STATE_DIR=.*PROJECT_ROOT.*sisyphus/state' "$HOOKS_DIR/persistent-mode.sh"; then
        return 0
    else
        echo "ASSERTION FAILED: persistent-mode.sh should use STATE_DIR in project-local location"
        return 1
    fi
}

test_persistent_mode_attempt_file_not_in_tmp() {
    # ATTEMPT_FILE should NOT be in /tmp/
    if grep 'ATTEMPT_FILE=' "$HOOKS_DIR/persistent-mode.sh" | grep -q '/tmp/'; then
        echo "ASSERTION FAILED: ATTEMPT_FILE should not be in /tmp/"
        return 1
    fi
    return 0
}

test_persistent_mode_todo_count_file_not_in_tmp() {
    # TODO_COUNT_FILE should NOT be in /tmp/
    if grep 'TODO_COUNT_FILE=' "$HOOKS_DIR/persistent-mode.sh" | grep -q '/tmp/'; then
        echo "ASSERTION FAILED: TODO_COUNT_FILE should not be in /tmp/"
        return 1
    fi
    return 0
}

test_persistent_mode_creates_state_dir() {
    # persistent-mode.sh should create STATE_DIR
    if grep -q 'mkdir -p.*STATE_DIR' "$HOOKS_DIR/persistent-mode.sh"; then
        return 0
    else
        echo "ASSERTION FAILED: persistent-mode.sh should create STATE_DIR"
        return 1
    fi
}

# =============================================================================
# Tests: Behavior verification via script execution
# =============================================================================

test_get_project_root_behavior_with_nested_path() {
    # Setup: Create project structure with .git
    mkdir -p "$TEST_TMP_DIR/myproject/.git"
    mkdir -p "$TEST_TMP_DIR/myproject/.omt"

    # Create a ralph state file to trigger the hook
    cat > "$TEST_TMP_DIR/myproject/.omt/ralph-state.json" << 'EOF'
{
  "active": true,
  "iteration": 1,
  "max_iterations": 10,
  "completion_promise": "DONE",
  "prompt": "test task"
}
EOF

    # Run the persistent-mode.sh with cwd set to nested directory
    local nested_dir="$TEST_TMP_DIR/myproject/.omt"
    local output
    output=$(echo "{\"cwd\": \"$nested_dir\"}" | "$HOOKS_DIR/persistent-mode.sh" 2>&1) || true

    # State files should be created in the project root, not nested
    if [[ -d "$TEST_TMP_DIR/myproject/.omt/state" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: State directory should be created in project root"
        echo "  Expected: $TEST_TMP_DIR/myproject/.omt/state/"
        echo "  Nested dir tested: $nested_dir"
        ls -la "$TEST_TMP_DIR/myproject/.omt/" 2>/dev/null || true
        return 1
    fi
}

test_state_files_created_in_project_local_dir() {
    # Setup: Create project structure
    mkdir -p "$TEST_TMP_DIR/myproject/.git"
    mkdir -p "$TEST_TMP_DIR/myproject/.omt"

    # Create ultrawork state to trigger the hook with incomplete todos
    cat > "$TEST_TMP_DIR/myproject/.omt/ultrawork-state.json" << 'EOF'
{
  "active": true,
  "started_at": "2024-01-01T00:00:00",
  "original_prompt": "test task",
  "reinforcement_count": 0,
  "last_checked_at": "2024-01-01T00:00:00"
}
EOF

    # Create todos to trigger continuation
    mkdir -p "$HOME/.claude/todos"
    echo '[{"status": "pending", "text": "test"}]' > "$HOME/.claude/todos/test.json"

    # Record timestamp before running the script
    local before_timestamp
    before_timestamp=$(date +%s)
    sleep 1  # Ensure time passes

    # Run persistent-mode.sh
    local output
    output=$(echo "{\"cwd\": \"$TEST_TMP_DIR/myproject\"}" | "$HOOKS_DIR/persistent-mode.sh" 2>&1) || true

    # Verify NEW state files are NOT created in /tmp (check modification time)
    local found_new_tmp_file=false
    for f in /tmp/oh-my-toong-todo-*; do
        if [[ -f "$f" ]]; then
            local file_mtime
            # Get modification time in seconds since epoch (macOS compatible)
            file_mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo "0")
            if [[ "$file_mtime" -gt "$before_timestamp" ]]; then
                found_new_tmp_file=true
                echo "ASSERTION FAILED: New state file created in /tmp/: $f"
            fi
        fi
    done

    if [[ "$found_new_tmp_file" == "true" ]]; then
        return 1
    fi

    # Verify state files ARE in project-local directory
    if [[ -d "$TEST_TMP_DIR/myproject/.omt/state" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: State directory should be created in project"
        return 1
    fi
}

# =============================================================================
# Main Test Runner
# =============================================================================

main() {
    echo "=========================================="
    echo "Project Root Detection Tests"
    echo "=========================================="

    # Function existence tests
    run_test test_get_project_root_function_exists_in_persistent_mode
    run_test test_get_project_root_function_exists_in_keyword_detector
    run_test test_get_project_root_function_exists_in_session_start

    # Path stripping tests
    run_test test_get_project_root_strips_claude_sisyphus_suffix
    run_test test_get_project_root_strips_claude_suffix

    # Marker detection tests
    run_test test_get_project_root_checks_git_marker
    run_test test_get_project_root_checks_claude_md_marker
    run_test test_get_project_root_checks_package_json_marker

    # PROJECT_ROOT variable usage tests
    run_test test_persistent_mode_uses_project_root_variable
    run_test test_keyword_detector_uses_project_root_variable
    run_test test_session_start_uses_project_root_variable

    # State file location tests
    run_test test_persistent_mode_state_dir_is_local
    run_test test_persistent_mode_attempt_file_not_in_tmp
    run_test test_persistent_mode_todo_count_file_not_in_tmp
    run_test test_persistent_mode_creates_state_dir

    # Behavior verification tests
    run_test test_get_project_root_behavior_with_nested_path
    run_test test_state_files_created_in_project_local_dir

    echo "=========================================="
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    echo "=========================================="

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
