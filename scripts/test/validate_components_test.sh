#!/bin/bash
# =============================================================================
# Validate Components Tests - CLI Project File Validation
# Tests for CLI project file existence verification
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Test utilities
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_TEST=""

# Save the actual root directory (before sourcing overwrites it)
ACTUAL_ROOT_DIR="$ROOT_DIR"

# Source the script to test its functions (but don't run main)
# We need to extract functions without running main
extract_functions_from_script() {
    # Create a temporary file with functions only (without main call)
    local tmp_script
    tmp_script=$(mktemp)

    # Copy script and remove the last line (main "$@")
    # macOS compatible approach
    local line_count
    line_count=$(wc -l < "$ACTUAL_ROOT_DIR/validate-components.sh" | tr -d ' ')
    local lines_to_keep=$((line_count - 1))

    head -n "$lines_to_keep" "$ACTUAL_ROOT_DIR/validate-components.sh" > "$tmp_script"

    # Source the functions (this will redefine SCRIPT_DIR and ROOT_DIR but we override them)
    source "$tmp_script"
    rm -f "$tmp_script"

    # Restore ROOT_DIR after sourcing
    ROOT_DIR="$ACTUAL_ROOT_DIR"
}

setup_test_env() {
    TEST_TMP_DIR=$(mktemp -d)

    # Create source structure mimicking oh-my-toong
    mkdir -p "$TEST_TMP_DIR/agents"
    mkdir -p "$TEST_TMP_DIR/commands"
    mkdir -p "$TEST_TMP_DIR/skills/tdd"
    mkdir -p "$TEST_TMP_DIR/hooks"
    mkdir -p "$TEST_TMP_DIR/projects"

    # Create sample source files
    echo "# Oracle Agent" > "$TEST_TMP_DIR/agents/oracle.md"
    echo "# Git Commit Command" > "$TEST_TMP_DIR/commands/git-commit.md"
    echo "# TDD Skill" > "$TEST_TMP_DIR/skills/tdd/SKILL.md"
    echo "#!/bin/bash" > "$TEST_TMP_DIR/hooks/test-hook"

    # Create target directory
    mkdir -p "$TEST_TMP_DIR/target"

    # Override ROOT_DIR for testing
    ROOT_DIR="$TEST_TMP_DIR"

    # Reset counters
    ERROR_COUNT=0
    WARN_COUNT=0

    # Extract and source functions
    extract_functions_from_script
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
# Tests: get_cli_project_file function
# =============================================================================

test_get_cli_project_file_claude() {
    local result=$(get_cli_project_file "claude")
    if [[ "$result" == "CLAUDE.md" ]]; then
        return 0
    else
        echo "Expected CLAUDE.md, got: $result"
        return 1
    fi
}

test_get_cli_project_file_gemini() {
    local result=$(get_cli_project_file "gemini")
    if [[ "$result" == "GEMINI.md" ]]; then
        return 0
    else
        echo "Expected GEMINI.md, got: $result"
        return 1
    fi
}

test_get_cli_project_file_codex() {
    local result=$(get_cli_project_file "codex")
    if [[ "$result" == "AGENTS.md" ]]; then
        return 0
    else
        echo "Expected AGENTS.md, got: $result"
        return 1
    fi
}

test_get_cli_project_file_unknown() {
    local result=$(get_cli_project_file "unknown")
    if [[ "$result" == "" ]]; then
        return 0
    else
        echo "Expected empty string for unknown CLI, got: $result"
        return 1
    fi
}

# =============================================================================
# Tests: CLI Project File Validation - Claude Target
# =============================================================================

test_claude_target_missing_claude_md_fails() {
    # Create sync.yaml with claude target but NO CLAUDE.md in target path
    cat > "$TEST_TMP_DIR/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - claude
agents:
  items:
    - oracle
EOF

    # Target path does NOT have CLAUDE.md
    rm -f "$TEST_TMP_DIR/target/CLAUDE.md"

    # Reset error count
    ERROR_COUNT=0

    # Run validation, capture output to temp file (not subshell)
    local output_file="$TEST_TMP_DIR/output.txt"
    validate_cli_project_files "$TEST_TMP_DIR/sync.yaml" "$TEST_TMP_DIR/target" > "$output_file" 2>&1

    # Should have errors
    if [[ $ERROR_COUNT -gt 0 ]]; then
        # Check error message contains CLAUDE.md
        if grep -q "CLAUDE.md" "$output_file"; then
            return 0
        else
            echo "Error message should mention CLAUDE.md, got: $(cat "$output_file")"
            return 1
        fi
    else
        echo "Validation should fail when CLAUDE.md is missing for claude target"
        return 1
    fi
}

test_claude_target_with_claude_md_passes() {
    # Create sync.yaml with claude target AND CLAUDE.md exists
    cat > "$TEST_TMP_DIR/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - claude
agents:
  items:
    - oracle
EOF

    # Create CLAUDE.md in target path
    echo "# CLAUDE.md" > "$TEST_TMP_DIR/target/CLAUDE.md"

    # Reset error count
    ERROR_COUNT=0

    # Run validation
    validate_cli_project_files "$TEST_TMP_DIR/sync.yaml" "$TEST_TMP_DIR/target" 2>/dev/null

    # Should have no errors
    if [[ $ERROR_COUNT -eq 0 ]]; then
        return 0
    else
        echo "Validation should pass when CLAUDE.md exists for claude target"
        return 1
    fi
}

# =============================================================================
# Tests: CLI Project File Validation - Gemini Target
# =============================================================================

test_gemini_target_missing_gemini_md_fails() {
    # Create sync.yaml with gemini target but NO GEMINI.md in target path
    cat > "$TEST_TMP_DIR/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - gemini
agents:
  items:
    - oracle
EOF

    # Target path does NOT have GEMINI.md
    rm -f "$TEST_TMP_DIR/target/GEMINI.md"

    # Reset error count
    ERROR_COUNT=0

    # Run validation, capture output to temp file (not subshell)
    local output_file="$TEST_TMP_DIR/output.txt"
    validate_cli_project_files "$TEST_TMP_DIR/sync.yaml" "$TEST_TMP_DIR/target" > "$output_file" 2>&1

    # Should have errors
    if [[ $ERROR_COUNT -gt 0 ]]; then
        if grep -q "GEMINI.md" "$output_file"; then
            return 0
        else
            echo "Error message should mention GEMINI.md, got: $(cat "$output_file")"
            return 1
        fi
    else
        echo "Validation should fail when GEMINI.md is missing for gemini target"
        return 1
    fi
}

test_gemini_target_with_gemini_md_passes() {
    # Create sync.yaml with gemini target AND GEMINI.md exists
    cat > "$TEST_TMP_DIR/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - gemini
agents:
  items:
    - oracle
EOF

    # Create GEMINI.md in target path
    echo "# GEMINI.md" > "$TEST_TMP_DIR/target/GEMINI.md"

    # Reset error count
    ERROR_COUNT=0

    # Run validation
    validate_cli_project_files "$TEST_TMP_DIR/sync.yaml" "$TEST_TMP_DIR/target" 2>/dev/null

    # Should have no errors
    if [[ $ERROR_COUNT -eq 0 ]]; then
        return 0
    else
        echo "Validation should pass when GEMINI.md exists for gemini target"
        return 1
    fi
}

# =============================================================================
# Tests: CLI Project File Validation - Codex Target
# =============================================================================

test_codex_target_missing_agents_md_fails() {
    # Create sync.yaml with codex target but NO AGENTS.md in target path
    cat > "$TEST_TMP_DIR/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - codex
agents:
  items:
    - oracle
EOF

    # Target path does NOT have AGENTS.md
    rm -f "$TEST_TMP_DIR/target/AGENTS.md"

    # Reset error count
    ERROR_COUNT=0

    # Run validation, capture output to temp file (not subshell)
    local output_file="$TEST_TMP_DIR/output.txt"
    validate_cli_project_files "$TEST_TMP_DIR/sync.yaml" "$TEST_TMP_DIR/target" > "$output_file" 2>&1

    # Should have errors
    if [[ $ERROR_COUNT -gt 0 ]]; then
        if grep -q "AGENTS.md" "$output_file"; then
            return 0
        else
            echo "Error message should mention AGENTS.md, got: $(cat "$output_file")"
            return 1
        fi
    else
        echo "Validation should fail when AGENTS.md is missing for codex target"
        return 1
    fi
}

test_codex_target_with_agents_md_passes() {
    # Create sync.yaml with codex target AND AGENTS.md exists
    cat > "$TEST_TMP_DIR/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - codex
agents:
  items:
    - oracle
EOF

    # Create AGENTS.md in target path
    echo "# AGENTS.md" > "$TEST_TMP_DIR/target/AGENTS.md"

    # Reset error count
    ERROR_COUNT=0

    # Run validation
    validate_cli_project_files "$TEST_TMP_DIR/sync.yaml" "$TEST_TMP_DIR/target" 2>/dev/null

    # Should have no errors
    if [[ $ERROR_COUNT -eq 0 ]]; then
        return 0
    else
        echo "Validation should pass when AGENTS.md exists for codex target"
        return 1
    fi
}

# =============================================================================
# Tests: CLI Project File Validation - Multiple Targets
# =============================================================================

test_multiple_targets_all_files_required() {
    # Create sync.yaml with multiple targets - all project files required
    cat > "$TEST_TMP_DIR/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - claude
  - gemini
  - codex
agents:
  items:
    - oracle
EOF

    # Target path only has CLAUDE.md (missing GEMINI.md and AGENTS.md)
    echo "# CLAUDE.md" > "$TEST_TMP_DIR/target/CLAUDE.md"
    rm -f "$TEST_TMP_DIR/target/GEMINI.md"
    rm -f "$TEST_TMP_DIR/target/AGENTS.md"

    # Reset error count
    ERROR_COUNT=0

    # Run validation
    validate_cli_project_files "$TEST_TMP_DIR/sync.yaml" "$TEST_TMP_DIR/target" 2>/dev/null

    # Should have 2 errors (GEMINI.md and AGENTS.md missing)
    if [[ $ERROR_COUNT -ge 2 ]]; then
        return 0
    else
        echo "Validation should report 2 errors for missing GEMINI.md and AGENTS.md, got: $ERROR_COUNT"
        return 1
    fi
}

test_multiple_targets_all_files_present_passes() {
    # Create sync.yaml with multiple targets - all project files present
    cat > "$TEST_TMP_DIR/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - claude
  - gemini
  - codex
agents:
  items:
    - oracle
EOF

    # Create all CLI project files
    echo "# CLAUDE.md" > "$TEST_TMP_DIR/target/CLAUDE.md"
    echo "# GEMINI.md" > "$TEST_TMP_DIR/target/GEMINI.md"
    echo "# AGENTS.md" > "$TEST_TMP_DIR/target/AGENTS.md"

    # Reset error count
    ERROR_COUNT=0

    # Run validation
    validate_cli_project_files "$TEST_TMP_DIR/sync.yaml" "$TEST_TMP_DIR/target" 2>/dev/null

    # Should have no errors
    if [[ $ERROR_COUNT -eq 0 ]]; then
        return 0
    else
        echo "Validation should pass when all CLI project files exist"
        return 1
    fi
}

# =============================================================================
# Tests: CLI Project File Validation - Component-level targets
# =============================================================================

test_component_targets_override_default() {
    # Create sync.yaml with component-level targets that add gemini
    cat > "$TEST_TMP_DIR/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - claude
agents:
  items:
    - component: oracle
      platforms:
        - gemini
EOF

    # Create only CLAUDE.md and GEMINI.md
    echo "# CLAUDE.md" > "$TEST_TMP_DIR/target/CLAUDE.md"
    echo "# GEMINI.md" > "$TEST_TMP_DIR/target/GEMINI.md"

    # Reset error count
    ERROR_COUNT=0

    # Run validation
    validate_cli_project_files "$TEST_TMP_DIR/sync.yaml" "$TEST_TMP_DIR/target" 2>/dev/null

    # Should pass - both claude (default) and gemini (component) files exist
    if [[ $ERROR_COUNT -eq 0 ]]; then
        return 0
    else
        echo "Validation should pass when both default and component target files exist"
        return 1
    fi
}

test_component_targets_adds_to_required_files() {
    # Create sync.yaml where component targets add additional required files
    cat > "$TEST_TMP_DIR/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - claude
agents:
  items:
    - component: oracle
      platforms:
        - gemini
commands:
  items:
    - git-commit
EOF

    # Target path only has CLAUDE.md (missing GEMINI.md for agent)
    echo "# CLAUDE.md" > "$TEST_TMP_DIR/target/CLAUDE.md"
    rm -f "$TEST_TMP_DIR/target/GEMINI.md"

    # Reset error count
    ERROR_COUNT=0

    # Run validation
    validate_cli_project_files "$TEST_TMP_DIR/sync.yaml" "$TEST_TMP_DIR/target" 2>/dev/null

    # Should have 1 error (GEMINI.md missing)
    if [[ $ERROR_COUNT -ge 1 ]]; then
        return 0
    else
        echo "Validation should fail when component target CLI file is missing"
        return 1
    fi
}

# =============================================================================
# Tests: Error Message Format
# =============================================================================

test_error_message_format() {
    # Create sync.yaml with claude target but NO CLAUDE.md
    cat > "$TEST_TMP_DIR/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - claude
agents:
  items:
    - oracle
EOF

    # Target path does NOT have CLAUDE.md
    rm -f "$TEST_TMP_DIR/target/CLAUDE.md"

    # Reset error count
    ERROR_COUNT=0

    # Run validation and capture output
    local output
    output=$(validate_cli_project_files "$TEST_TMP_DIR/sync.yaml" "$TEST_TMP_DIR/target" 2>&1)

    # Check error message format matches requirement:
    # [ERROR] CLI 프로젝트 파일 없음: CLAUDE.md (대상: /path/to/project)
    if echo "$output" | grep -qE "\[ERROR\].*CLI.*CLAUDE.md.*\(.*:.*\)"; then
        return 0
    else
        echo "Error message format does not match required format"
        echo "Expected: [ERROR] CLI 프로젝트 파일 없음: CLAUDE.md (대상: /path)"
        echo "Got: $output"
        return 1
    fi
}

test_error_suggests_init_command() {
    # Create sync.yaml with claude target but NO CLAUDE.md
    cat > "$TEST_TMP_DIR/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - claude
agents:
  items:
    - oracle
EOF

    # Target path does NOT have CLAUDE.md
    rm -f "$TEST_TMP_DIR/target/CLAUDE.md"

    # Reset error count
    ERROR_COUNT=0

    # Run validation and capture output
    local output
    output=$(validate_cli_project_files "$TEST_TMP_DIR/sync.yaml" "$TEST_TMP_DIR/target" 2>&1)

    # Check that error message suggests running init
    if echo "$output" | grep -q "init"; then
        return 0
    else
        echo "Error message should suggest running 'init'"
        echo "Got: $output"
        return 1
    fi
}

# =============================================================================
# Tests: Full Integration - validate_components function
# =============================================================================

test_validate_components_calls_cli_validation() {
    # Create sync.yaml with claude target but NO CLAUDE.md
    mkdir -p "$TEST_TMP_DIR/projects/test-proj"
    cat > "$TEST_TMP_DIR/projects/test-proj/sync.yaml" << EOF
name: test-project
path: $TEST_TMP_DIR/target
platforms:
  - claude
agents:
  items:
    - oracle
EOF

    # Target path does NOT have CLAUDE.md
    rm -f "$TEST_TMP_DIR/target/CLAUDE.md"

    # Reset error count
    ERROR_COUNT=0

    # Run full validate_components, capture output to temp file (not subshell)
    local output_file="$TEST_TMP_DIR/output.txt"
    validate_components "$TEST_TMP_DIR/projects/test-proj/sync.yaml" > "$output_file" 2>&1

    # Should have errors for missing CLAUDE.md
    if [[ $ERROR_COUNT -gt 0 ]]; then
        if grep -q "CLAUDE.md" "$output_file"; then
            return 0
        else
            echo "Error message should mention CLAUDE.md"
            return 1
        fi
    else
        echo "validate_components should call CLI project file validation"
        return 1
    fi
}

test_validate_components_skips_template_yaml() {
    # Create sync.yaml WITHOUT path (template state)
    mkdir -p "$TEST_TMP_DIR/projects/test-proj"
    cat > "$TEST_TMP_DIR/projects/test-proj/sync.yaml" << EOF
name: test-project
platforms:
  - claude
agents:
  items:
    - oracle
EOF

    # Reset counters
    ERROR_COUNT=0
    WARN_COUNT=0

    # Run full validate_components
    validate_components "$TEST_TMP_DIR/projects/test-proj/sync.yaml" 2>/dev/null

    # Should have no errors (template state should be skipped)
    if [[ $ERROR_COUNT -eq 0 ]]; then
        return 0
    else
        echo "validate_components should skip CLI validation for template YAML"
        return 1
    fi
}

# =============================================================================
# Main Test Runner
# =============================================================================

main() {
    echo "=========================================="
    echo "Validate Components Tests - CLI Project Files"
    echo "=========================================="

    # get_cli_project_file tests
    run_test test_get_cli_project_file_claude
    run_test test_get_cli_project_file_gemini
    run_test test_get_cli_project_file_codex
    run_test test_get_cli_project_file_unknown

    # Claude target tests
    run_test test_claude_target_missing_claude_md_fails
    run_test test_claude_target_with_claude_md_passes

    # Gemini target tests
    run_test test_gemini_target_missing_gemini_md_fails
    run_test test_gemini_target_with_gemini_md_passes

    # Codex target tests
    run_test test_codex_target_missing_agents_md_fails
    run_test test_codex_target_with_agents_md_passes

    # Multiple targets tests
    run_test test_multiple_targets_all_files_required
    run_test test_multiple_targets_all_files_present_passes

    # Component-level targets tests
    run_test test_component_targets_override_default
    run_test test_component_targets_adds_to_required_files

    # Error message format tests
    run_test test_error_message_format
    run_test test_error_suggests_init_command

    # Full integration tests
    run_test test_validate_components_calls_cli_validation
    run_test test_validate_components_skips_template_yaml

    echo "=========================================="
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    echo "=========================================="

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
