# Commit Conventions

## Format

```
<type>: <title>

<body (optional)>
```

## Title Rules

| Rule         | Description                                 |
|--------------|---------------------------------------------|
| Language     | Korean (한국어)                                |
| Max Length   | 50 characters                               |
| Ending Style | 명사형 종결 (e.g., "추가", "수정", "삭제", "구현", "개선") |
| No Period    | Do not end with period                      |

## Types

| Type       | Usage          | Example                     |
|------------|----------------|-----------------------------|
| `feat`     | 새로운 기능         | feat: 쿠폰 발급 API 추가          |
| `fix`      | 버그 수정          | fix: 포인트 차감 동시성 오류 수정       |
| `refactor` | 기능 변경 없는 코드 개선 | refactor: 주문 검증 로직 서비스로 분리  |
| `docs`     | 문서 수정          | docs: API 명세서 엔드포인트 설명 보완   |
| `chore`    | 빌드, 패키지, 설정 등  | chore: Spring Boot 버전 업그레이드 |
| `style`    | 포맷팅, 세미콜론 등    | style: 코드 포맷팅 및 import 정리   |
| `perf`     | 성능 개선           | perf: 상품 조회 쿼리 최적화          |
| `test`     | 테스트 코드         | test: 쿠폰 만료 검증 테스트 추가       |

## Body Rules

| Rule        | Description                                     |
|-------------|-------------------------------------------------|
| When to Add | Only when 'Why' needs explanation               |
| Skip When   | Trivial or self-explanatory changes             |
| Language    | Korean                                          |
| Format      | Bullet points or short paragraphs               |
| Content     | Explain reasoning, not what (title covers what) |
