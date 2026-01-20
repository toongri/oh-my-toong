#!/bin/bash
set -euo pipefail

# =============================================================================
# oh-my-toong Validate Tool
# sync.yaml 파일들의 유효성 검증
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# 색상
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 에러 카운터
ERROR_COUNT=0
WARN_COUNT=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((WARN_COUNT++)) || true
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((ERROR_COUNT++)) || true
}

# =============================================================================
# 의존성 확인
# =============================================================================

check_dependencies() {
    local missing=()

    if ! command -v yq &> /dev/null; then
        missing+=("yq")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "다음 의존성이 필요합니다: ${missing[*]}"
        exit 1
    fi
}

# =============================================================================
# 소스 경로 해석 (sync.sh와 동일)
# =============================================================================

resolve_source_path() {
    local category="$1"
    local name="$2"
    local extension="$3"

    if [[ "$name" == *:* ]]; then
        local project=$(echo "$name" | cut -d: -f1)
        local item=$(echo "$name" | cut -d: -f2-)
        SOURCE_PATH="$ROOT_DIR/projects/$project/$category/${item}${extension}"
        DISPLAY_NAME="$item"
    else
        SOURCE_PATH="$ROOT_DIR/$category/${name}${extension}"
        DISPLAY_NAME="$name"
    fi
}

# =============================================================================
# YAML 검증
# =============================================================================

validate_yaml_syntax() {
    local yaml_file="$1"

    if ! yq '.' "$yaml_file" > /dev/null 2>&1; then
        log_error "YAML 문법 오류: $yaml_file"
        return 1
    fi
    return 0
}

validate_yaml_file() {
    local yaml_file="$1"
    local yaml_name=$(basename "$(dirname "$yaml_file")")/$(basename "$yaml_file")

    log_info "검증 중: $yaml_name"

    # YAML 문법 검증
    if ! validate_yaml_syntax "$yaml_file"; then
        return 1
    fi

    # path 필드 검증
    local target_path=$(yq '.path // ""' "$yaml_file")
    if [[ -z "$target_path" || "$target_path" == "null" ]]; then
        log_warn "path가 정의되지 않음: $yaml_name (템플릿 상태)"
        return 0
    fi

    # agents 검증
    local agent_count=$(yq '.agents | length // 0' "$yaml_file")
    for i in $(seq 0 $((agent_count - 1))); do
        local component=$(yq ".agents[$i].component // \"\"" "$yaml_file")
        if [[ -z "$component" || "$component" == "null" ]]; then
            log_error "agents[$i].component가 정의되지 않음: $yaml_name"
            continue
        fi
        resolve_source_path "agents" "$component" ".md"
        if [[ ! -f "$SOURCE_PATH" ]]; then
            log_error "Agent 파일 없음: $component -> $SOURCE_PATH"
        fi

        # add-skills 검증 (있는 경우에만)
        # skills 섹션에 정의되어 있거나, 소스 디렉토리가 존재하면 OK
        local has_add_skills=$(yq ".agents[$i].add-skills // null" "$yaml_file")
        if [[ "$has_add_skills" != "null" ]]; then
            local skills_count=$(yq ".agents[$i].add-skills | length" "$yaml_file")
            for j in $(seq 0 $((skills_count - 1))); do
                local skill=$(yq ".agents[$i].add-skills[$j]" "$yaml_file")
                if [[ -n "$skill" && "$skill" != "null" ]]; then
                    # skills 섹션에서 해당 스킬이 정의되어 있는지 확인 (정확히 일치하거나 :skill로 끝나는 경우)
                    local in_skills=$(yq ".skills[].component" "$yaml_file" 2>/dev/null | grep -E "(^${skill}$|:${skill}$)" | head -1)
                    if [[ -z "$in_skills" ]]; then
                        # skills 섹션에 없으면 소스 디렉토리 확인
                        resolve_source_path "skills" "$skill" ""
                        if [[ ! -d "$SOURCE_PATH" ]]; then
                            log_warn "Agent add-skills '$skill'가 skills 섹션에 없고 소스 디렉토리도 없음"
                        fi
                    fi
                fi
            done
        fi
    done

    # commands 검증
    local cmd_count=$(yq '.commands | length // 0' "$yaml_file")
    for i in $(seq 0 $((cmd_count - 1))); do
        local component=$(yq ".commands[$i].component // \"\"" "$yaml_file")
        if [[ -z "$component" || "$component" == "null" ]]; then
            log_error "commands[$i].component가 정의되지 않음: $yaml_name"
            continue
        fi
        resolve_source_path "commands" "$component" ".md"
        if [[ ! -f "$SOURCE_PATH" ]]; then
            log_error "Command 파일 없음: $component -> $SOURCE_PATH"
        fi
    done

    # hooks 검증
    local hook_count=$(yq '.hooks | length // 0' "$yaml_file")
    for i in $(seq 0 $((hook_count - 1))); do
        local component=$(yq ".hooks[$i].component // \"\"" "$yaml_file")
        local event=$(yq ".hooks[$i].event // \"\"" "$yaml_file")
        local hook_type=$(yq ".hooks[$i].type // \"command\"" "$yaml_file")
        local command=$(yq ".hooks[$i].command // \"\"" "$yaml_file")
        local prompt=$(yq ".hooks[$i].prompt // \"\"" "$yaml_file")

        # event 필수
        if [[ -z "$event" || "$event" == "null" ]]; then
            log_error "hooks[$i].event가 정의되지 않음: $yaml_name"
            continue
        fi

        # event 값 검증
        case "$event" in
            SessionStart|UserPromptSubmit|PreToolUse|PostToolUse|Stop)
                ;;
            *)
                log_error "hooks[$i].event 값이 올바르지 않음: $event (허용: SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop)"
                ;;
        esac

        # component가 있으면 파일 존재 확인
        if [[ -n "$component" && "$component" != "null" ]]; then
            resolve_source_path "hooks" "$component" ""
            if [[ ! -f "$SOURCE_PATH" ]]; then
                log_error "Hook 파일 없음: $component -> $SOURCE_PATH"
            fi
        fi

        # type에 따른 필수 필드 검증
        if [[ "$hook_type" == "prompt" ]]; then
            if [[ -z "$prompt" || "$prompt" == "null" ]]; then
                log_error "hooks[$i]: type=prompt이지만 prompt 필드가 없음"
            fi
        else
            # type: command
            if [[ -z "$component" || "$component" == "null" ]] && [[ -z "$command" || "$command" == "null" ]]; then
                log_error "hooks[$i]: component 또는 command 중 하나는 필수"
            fi
        fi
    done

    # skills 검증
    local skill_count=$(yq '.skills | length // 0' "$yaml_file")
    for i in $(seq 0 $((skill_count - 1))); do
        local component=$(yq ".skills[$i].component // \"\"" "$yaml_file")
        if [[ -z "$component" || "$component" == "null" ]]; then
            log_error "skills[$i].component가 정의되지 않음: $yaml_name"
            continue
        fi
        resolve_source_path "skills" "$component" ""
        if [[ ! -d "$SOURCE_PATH" ]]; then
            log_error "Skill 디렉토리 없음: $component -> $SOURCE_PATH"
        fi
    done

    return 0
}

# =============================================================================
# 메인
# =============================================================================

show_help() {
    echo "oh-my-toong Validate Tool"
    echo ""
    echo "사용법: $0 [옵션]"
    echo ""
    echo "옵션:"
    echo "  --help    이 도움말 표시"
    echo "  --quiet   에러만 출력"
    echo ""
}

main() {
    local quiet=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                show_help
                exit 0
                ;;
            --quiet)
                quiet=true
                shift
                ;;
            *)
                log_error "알 수 없는 옵션: $1"
                show_help
                exit 1
                ;;
        esac
    done

    check_dependencies

    if [[ "$quiet" != true ]]; then
        log_info "========== sync.yaml 검증 시작 =========="
    fi

    # projects/**/sync.yaml 검증
    if [[ -d "$ROOT_DIR/projects" ]]; then
        while IFS= read -r yaml_file; do
            if [[ -n "$yaml_file" ]]; then
                validate_yaml_file "$yaml_file"
            fi
        done < <(find "$ROOT_DIR/projects" -name "sync.yaml" 2>/dev/null || true)
    fi

    # 루트 sync.yaml 검증
    local root_yaml="$ROOT_DIR/sync.yaml"
    if [[ -f "$root_yaml" ]]; then
        validate_yaml_file "$root_yaml"
    fi

    # 결과 출력
    echo ""
    if [[ $ERROR_COUNT -gt 0 ]]; then
        log_error "검증 실패: $ERROR_COUNT 개 에러, $WARN_COUNT 개 경고"
        exit 1
    elif [[ $WARN_COUNT -gt 0 ]]; then
        log_warn "검증 완료: $WARN_COUNT 개 경고"
        exit 0
    else
        log_success "========== 검증 통과 =========="
        exit 0
    fi
}

main "$@"
