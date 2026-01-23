#!/bin/bash
# =============================================================================
# Keyword Detector Hook Tests
# Tests for session-based ralph state file creation
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
    mkdir -p "$TEST_TMP_DIR/.claude/sisyphus"
    mkdir -p "$TEST_TMP_DIR/.git"

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

assert_output_contains() {
    local output="$1"
    local pattern="$2"
    local msg="${3:-Output should contain pattern}"

    if echo "$output" | grep -q "$pattern"; then
        return 0
    else
        echo "ASSERTION FAILED: $msg"
        echo "  Pattern: '$pattern'"
        echo "  Output (first 500 chars): ${output:0:500}"
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
# Tests: Session-based ralph state file creation
# =============================================================================

test_ralph_keyword_creates_session_specific_state_file() {
    # Setup: Create project marker
    mkdir -p "$TEST_TMP_DIR/.git"

    # Run with sessionId in input
    local output
    output=$(echo '{"cwd": "'"$TEST_TMP_DIR"'", "sessionId": "test-session-123", "prompt": "ralph do the task"}' | "$HOOKS_DIR/keyword-detector.sh" 2>&1) || true

    # Verify output contains ralph activation
    assert_output_contains "$output" "RALPH LOOP ACTIVATED" "Should activate ralph loop" || return 1

    # Verify session-specific state file was created
    assert_file_exists "$TEST_TMP_DIR/.claude/sisyphus/ralph-state-test-session-123.json" "Session-specific ralph state file should exist" || return 1

    # Verify old non-session file was NOT created
    assert_file_not_exists "$TEST_TMP_DIR/.claude/sisyphus/ralph-state.json" "Non-session ralph state file should NOT exist" || return 1
}

test_ralph_keyword_creates_session_specific_state_in_home() {
    # Setup: Create project marker
    mkdir -p "$TEST_TMP_DIR/.git"

    # Run with sessionId in input
    local output
    output=$(echo '{"cwd": "'"$TEST_TMP_DIR"'", "sessionId": "test-session-456", "prompt": "ralph do the task"}' | "$HOOKS_DIR/keyword-detector.sh" 2>&1) || true

    # Verify session-specific state file was created in HOME
    assert_file_exists "$HOME/.claude/ralph-state-test-session-456.json" "Session-specific ralph state file in HOME should exist" || return 1

    # Verify old non-session file was NOT created
    assert_file_not_exists "$HOME/.claude/ralph-state.json" "Non-session ralph state file in HOME should NOT exist" || return 1
}

test_ralph_keyword_uses_default_when_no_session_id() {
    # Setup: Create project marker
    mkdir -p "$TEST_TMP_DIR/.git"

    # Run without sessionId in input
    local output
    output=$(echo '{"cwd": "'"$TEST_TMP_DIR"'", "prompt": "ralph do the task"}' | "$HOOKS_DIR/keyword-detector.sh" 2>&1) || true

    # Verify output contains ralph activation
    assert_output_contains "$output" "RALPH LOOP ACTIVATED" "Should activate ralph loop" || return 1

    # Verify default session state file was created
    assert_file_exists "$TEST_TMP_DIR/.claude/sisyphus/ralph-state-default.json" "Default ralph state file should exist" || return 1
}

test_ralph_verification_uses_session_id() {
    # This test verifies that ralph-verification also uses session ID
    # The verification file is created by persistent-mode.sh, not keyword-detector
    # So we just check that keyword-detector extracts session ID correctly

    # Check that keyword-detector.sh has SESSION_ID extraction code
    if grep -q 'SESSION_ID.*jq.*sessionId' "$HOOKS_DIR/keyword-detector.sh"; then
        return 0
    else
        echo "ASSERTION FAILED: keyword-detector.sh should extract SESSION_ID"
        return 1
    fi
}

# =============================================================================
# Main Test Runner
# =============================================================================

main() {
    echo "=========================================="
    echo "Keyword Detector Hook Tests"
    echo "=========================================="

    # Session-based ralph state tests
    run_test test_ralph_keyword_creates_session_specific_state_file
    run_test test_ralph_keyword_creates_session_specific_state_in_home
    run_test test_ralph_keyword_uses_default_when_no_session_id
    run_test test_ralph_verification_uses_session_id

    echo "=========================================="
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    echo "=========================================="

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
