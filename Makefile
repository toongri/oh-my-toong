.PHONY: sync sync-dry validate help

help:
	@echo "사용 가능한 명령어:"
	@echo "  make sync      - 모든 sync.yaml 파일 동기화 실행"
	@echo "  make sync-dry  - 동기화 미리보기 (실제 변경 없음)"
	@echo "  make validate  - sync.yaml 파일 검증"

sync: validate
	@./scripts/sync.sh

sync-dry: validate
	@./scripts/sync.sh --dry-run

validate:
	@./scripts/validate.sh
