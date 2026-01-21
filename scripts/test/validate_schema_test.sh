#!/bin/bash
# =============================================================================
# Validate Schema Tests - Platforms Field Validation
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
VALIDATE_SCHEMA="$ROOT_DIR/validate-schema.sh"

# Test utilities
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

setup_test_env() {
    TEST_TMP_DIR=$(mktemp -d)
}

teardown_test_env() {
    if [[ -d "$TEST_TMP_DIR" ]]; then
        rm -rf "$TEST_TMP_DIR"
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
# Tests: platforms Field (Top Level - replaces default_targets)
# =============================================================================

test_platforms_valid_single_value() {
    # Create sync.yaml with valid platforms
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
platforms:
  - claude
EOF

    # Run validation - should pass (exit 0)
    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        return 0
    else
        echo "Validation should pass for valid platforms"
        return 1
    fi
}

test_platforms_valid_multiple_values() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
platforms:
  - claude
  - gemini
  - codex
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        return 0
    else
        echo "Validation should pass for multiple valid platforms"
        return 1
    fi
}

test_platforms_invalid_value() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
platforms:
  - invalid_target
EOF

    # Run validation - should fail (exit 1)
    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        echo "Validation should fail for invalid platforms value"
        return 1
    else
        return 0
    fi
}

test_platforms_mixed_valid_invalid() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
platforms:
  - claude
  - unknown
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        echo "Validation should fail when any platforms value is invalid"
        return 1
    else
        return 0
    fi
}

test_platforms_empty_array_valid() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
platforms: []
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        return 0
    else
        echo "Validation should pass for empty platforms array"
        return 1
    fi
}

# =============================================================================
# Tests: platforms Field in Agents (replaces targets)
# =============================================================================

test_agent_platforms_valid() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
agents:
  items:
    - component: oracle
      platforms:
        - claude
        - gemini
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        return 0
    else
        echo "Validation should pass for valid agent platforms"
        return 1
    fi
}

test_agent_platforms_invalid() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
agents:
  items:
    - component: oracle
      platforms:
        - bard
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        echo "Validation should fail for invalid agent platforms"
        return 1
    else
        return 0
    fi
}

test_agent_without_platforms_valid() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
agents:
  items:
    - oracle
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        return 0
    else
        echo "Validation should pass for agent without platforms (uses top-level default)"
        return 1
    fi
}

# =============================================================================
# Tests: platforms Field in Commands
# =============================================================================

test_command_platforms_valid() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
commands:
  items:
    - component: git-commit
      platforms:
        - codex
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        return 0
    else
        echo "Validation should pass for valid command platforms"
        return 1
    fi
}

test_command_platforms_invalid() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
commands:
  items:
    - component: git-commit
      platforms:
        - chatgpt
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        echo "Validation should fail for invalid command platforms"
        return 1
    else
        return 0
    fi
}

# =============================================================================
# Tests: platforms Field in Hooks
# =============================================================================

test_hook_platforms_valid() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
hooks:
  items:
    - component: test-hook
      event: PreToolUse
      platforms:
        - claude
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        return 0
    else
        echo "Validation should pass for valid hook platforms"
        return 1
    fi
}

test_hook_platforms_invalid() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
hooks:
  items:
    - component: test-hook
      event: PreToolUse
      platforms:
        - gpt4
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        echo "Validation should fail for invalid hook platforms"
        return 1
    else
        return 0
    fi
}

# =============================================================================
# Tests: platforms Field in Skills
# =============================================================================

test_skill_platforms_valid() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
skills:
  items:
    - component: tdd
      platforms:
        - gemini
        - codex
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        return 0
    else
        echo "Validation should pass for valid skill platforms"
        return 1
    fi
}

test_skill_platforms_invalid() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
skills:
  items:
    - component: tdd
      platforms:
        - anthropic
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        echo "Validation should fail for invalid skill platforms"
        return 1
    else
        return 0
    fi
}

# =============================================================================
# Tests: CLI-Specific Limitation Warnings
# =============================================================================

test_warns_gemini_agents_fallback() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
agents:
  items:
    - component: oracle
      platforms:
        - gemini
EOF

    # Run validation and capture stderr for warning message
    local output
    output=$("$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>&1) || true

    # Should contain warning about gemini agents fallback
    if echo "$output" | grep -q "Gemini.*agents.*fallback\|GEMINI.md"; then
        return 0
    else
        echo "Expected warning about Gemini agents fallback, got: $output"
        return 1
    fi
}

test_warns_codex_agents_fallback() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
agents:
  items:
    - component: oracle
      platforms:
        - codex
EOF

    local output
    output=$("$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>&1) || true

    # Should contain warning about codex agents fallback
    if echo "$output" | grep -q "Codex.*agents.*fallback\|AGENTS.md"; then
        return 0
    else
        echo "Expected warning about Codex agents fallback, got: $output"
        return 1
    fi
}

test_warns_codex_hooks_limited() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
hooks:
  items:
    - component: test-hook
      event: PreToolUse
      platforms:
        - codex
EOF

    local output
    output=$("$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>&1) || true

    # Should contain warning about codex hooks limitation
    if echo "$output" | grep -q "Codex.*Notification\|codex.*hook.*skip"; then
        return 0
    else
        echo "Expected warning about Codex hooks limitation, got: $output"
        return 1
    fi
}

test_warns_codex_commands_global() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
commands:
  items:
    - component: git-commit
      platforms:
        - codex
EOF

    local output
    output=$("$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>&1) || true

    # Should contain warning about codex commands being global
    if echo "$output" | grep -q "Codex.*commands.*global\|\.codex/prompts"; then
        return 0
    else
        echo "Expected warning about Codex commands global path, got: $output"
        return 1
    fi
}

test_no_warning_for_claude_native() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
agents:
  items:
    - component: oracle
      platforms:
        - claude
commands:
  items:
    - component: git-commit
      platforms:
        - claude
hooks:
  items:
    - component: test-hook
      event: PreToolUse
      platforms:
        - claude
skills:
  items:
    - component: tdd
      platforms:
        - claude
EOF

    local output
    output=$("$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>&1) || true

    # Should NOT contain any CLI limitation warnings for Claude
    if echo "$output" | grep -qi "fallback\|limited\|global\|skip"; then
        echo "Should not have any limitation warnings for claude-only platforms, got: $output"
        return 1
    else
        return 0
    fi
}

# =============================================================================
# Tests: Backward Compatibility
# =============================================================================

test_sync_yaml_without_platforms_valid() {
    cat > "$TEST_TMP_DIR/sync.yaml" << 'EOF'
name: test-project
path: /tmp/test
agents:
  items:
    - oracle
commands:
  items:
    - git-commit
hooks:
  items:
    - component: test-hook
      event: PreToolUse
skills:
  items:
    - tdd
EOF

    if "$VALIDATE_SCHEMA" "$TEST_TMP_DIR/sync.yaml" 2>/dev/null; then
        return 0
    else
        echo "Validation should pass for sync.yaml without any platforms fields"
        return 1
    fi
}

# =============================================================================
# Main Test Runner
# =============================================================================

main() {
    echo "=========================================="
    echo "Validate Schema Tests - Platforms Field"
    echo "=========================================="

    # Top-level platforms tests
    run_test test_platforms_valid_single_value
    run_test test_platforms_valid_multiple_values
    run_test test_platforms_invalid_value
    run_test test_platforms_mixed_valid_invalid
    run_test test_platforms_empty_array_valid

    # Agent platforms tests
    run_test test_agent_platforms_valid
    run_test test_agent_platforms_invalid
    run_test test_agent_without_platforms_valid

    # Command platforms tests
    run_test test_command_platforms_valid
    run_test test_command_platforms_invalid

    # Hook platforms tests
    run_test test_hook_platforms_valid
    run_test test_hook_platforms_invalid

    # Skill platforms tests
    run_test test_skill_platforms_valid
    run_test test_skill_platforms_invalid

    # CLI-Specific Limitation Warnings
    run_test test_warns_gemini_agents_fallback
    run_test test_warns_codex_agents_fallback
    run_test test_warns_codex_hooks_limited
    run_test test_warns_codex_commands_global
    run_test test_no_warning_for_claude_native

    # Backward compatibility
    run_test test_sync_yaml_without_platforms_valid

    echo "=========================================="
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    echo "=========================================="

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
