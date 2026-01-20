#!/bin/bash
# =============================================================================
# sync-validator hook
# sync.yaml 파일 검증 (PostToolUse 또는 Stop hook으로 사용)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# stdin 읽기 (hook input)
input=$(cat)

# PostToolUse hook인 경우: sync.yaml 수정 시에만 검증
if [[ -n "$input" ]]; then
    file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")

    # sync.yaml 파일이 아니면 패스
    if [[ -n "$file_path" && "$file_path" != *"sync.yaml" ]]; then
        echo "$input"
        exit 0
    fi
fi

# 검증 실행
if [[ -f "$ROOT_DIR/scripts/validate.sh" ]]; then
    result=$("$ROOT_DIR/scripts/validate.sh" --quiet 2>&1) || {
        echo "[sync-validator] 검증 실패:" >&2
        echo "$result" >&2
    }
fi

# 원본 input 반환 (hook chain 유지)
if [[ -n "$input" ]]; then
    echo "$input"
fi
