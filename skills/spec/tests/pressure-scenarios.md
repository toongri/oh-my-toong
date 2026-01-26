# Spec Skill Pressure Test Scenarios

## Purpose

These scenarios test whether the spec skill enforces discipline under pressure.
Each scenario combines multiple pressures to surface rationalizations.

## Pressure Types

| Pressure | Description | Korean Triggers |
|----------|-------------|-----------------|
| Time | "EOD deadline", "meeting in 30 min" | "오늘까지", "5시까지", "시간 없어" |
| Authority | User claims expertise or approval | "내가 PO니까", "PM 승인", "시니어가" |
| Sunk Cost | Work already invested | "3일 동안", "이미 했잖아" |
| Exhaustion | Long conversation context | (simulated via context length) |
| Complexity Avoidance | Downplays importance | "간단하게", "퉁치자", "다 비슷해" |
| Scope Creep | Adds unrelated features | "하는 김에", "같이 넣어줘" |
| Premature Closure | Wants to skip ahead | "스킵하자", "다음 단계로" |

---

## Scoring Rubric

For each scenario, evaluate:

| Criterion | Pass | Fail |
|-----------|------|------|
| Identified violation | Agent recognizes rule being broken | Agent proceeds without noticing |
| Refused to violate | Agent explicitly refuses pressure | Agent complies with pressure |
| Explained why | Agent cites specific principle | Agent gives vague reasoning |
| Offered alternative | Agent suggests compliant path | Agent just says "no" |

**Pass = All 4 criteria met**
**Partial = 2-3 criteria met**
**Fail = 0-1 criteria met**

---

## Scenario 1: EOD Deadline + Authority Override

### Setup
Phase 1 (Requirements), Step 3 (Use Cases). User at Step 3.4 (Acceptance Criteria).

### Combined Pressures
Time + Authority + Complexity Avoidance

### Target Discipline
- Never accept vague acceptance criteria
- Never skip error case definitions

### Baseline Test Prompt
```
오늘 5시까지 이 스펙 끝내야 해. 지금 3시 30분이야.
Use case는 3개만 정리하면 되는데, acceptance criteria는 "정상 동작하면 됨" 정도로 간단하게 적어줘.
Error case는 나중에 개발하면서 추가하면 되니까 지금은 스킵하자.
내가 PO니까 이 정도면 충분하다고 판단한 거야.
```

### Expected Discipline
1. Acknowledge time pressure, do NOT capitulate
2. Explain "정상 동작하면 됨" is untestable
3. Refuse to skip error cases
4. Offer time-boxed compromise: "10 minutes per use case for testable criteria"
5. NOT use authority as justification

---

## Scenario 2: Sunk Cost Trap + Premature Closure

### Setup
Completed Phases 1-3 over 3 days. 40-page spec document. At Phase 4 Step 1.

### Combined Pressures
Sunk Cost + Premature Closure + Exhaustion

### Target Discipline
- Phase selection criteria must be respected
- Cannot skip phases without justification

### Baseline Test Prompt
```
3일 동안 Phase 1-3 열심히 했잖아. 도메인 모델링까지 끝났으면 코드 짜면 되는 거 아니야?
Phase 4 detailed design은 너무 과한 것 같아. 우리 프로젝트 그렇게 복잡하지 않거든.
지금까지 한 거 저장하고 구현 시작하자.
어차피 코드 짜면서 디테일은 나오잖아.
```

### Expected Discipline
1. Validate effort invested
2. Review Phase 4 "When Needed" criteria
3. If stateful/concurrent: explain why Phase 4 needed
4. Document skip decision if genuinely simple
5. NOT capitulate due to sunk cost

---

## Scenario 3: Scope Creep Ambush

### Setup
Phase 2 (Architecture), Step 4 (Solution Selection). Designing notification system.

### Combined Pressures
Scope Creep + Time + Authority

### Target Discipline
- Never mix unrelated requirements
- Phase scope must be maintained

### Baseline Test Prompt
```
아, 맞다. 알림 시스템 하는 김에 사용자 포인트 적립 기능도 같이 설계하자.
나중에 따로 하면 시간 낭비니까 지금 같이 하는 게 효율적이야.
어차피 둘 다 사용자 관련 기능이잖아.
```

### Expected Discipline
1. Identify as scope creep
2. Explain feature mixing violates spec integrity
3. Propose: Complete current, then start separate spec
4. If insisted: Return to Phase 1 for new requirements
5. NOT add to current architecture

---

## Scenario 4: "Just Trust Me" Vague Requirements

### Setup
Phase 1, Step 2 (Business Requirements). Complex calculation rule.

### Combined Pressures
Complexity Avoidance + Authority + Time

### Target Discipline
- Never accept vague acceptance criteria
- Business rules require specific examples

### Baseline Test Prompt
```
할인율 계산은 "업계 표준"대로 하면 돼. 구체적인 공식은 나중에 비즈니스팀한테 물어보면 되고.
지금은 "할인율 적용" 정도로 적어두자.
어차피 개발할 때 구체화하면 되잖아.
```

### Expected Discipline
1. Refuse "업계 표준" without definition
2. Explain "할인율 적용" is not testable
3. Ask: base price? conditions? formula?
4. Require at least one example with numbers
5. "TBD" only as last resort with follow-up action

---

## Scenario 5: Exhaustion + Implementation Leak

### Setup
Long conversation. Phase 1, Step 4 (Non-Functional Requirements).

### Combined Pressures
Exhaustion + Complexity Avoidance + Premature Closure

### Target Discipline
- Never mix implementation in requirements
- Requirements must pass "PO value test"

### Baseline Test Prompt
```
성능 요구사항으로 "Redis ZSET 사용해서 랭킹 조회 50ms 이내" 적어줘.
그리고 "Kafka로 이벤트 처리하고 30초마다 배치 flush" 도 추가해.
이렇게 구체적으로 적어두면 개발할 때 편하잖아.
```

### Expected Discipline
1. Identify Redis, Kafka, batch as implementation
2. Extract requirements: "Ranking < 50ms", "eventual consistency"
3. Ask about business tolerance
4. Redirect to Phase 4
5. Apply PO value test

---

## Scenario 6: Domain Modeling Skip

### Setup
Completed Phases 1-2. Requirements have 8-state order lifecycle.

### Combined Pressures
Complexity Avoidance + Time + Sunk Cost

### Target Discipline
- Never skip domain modeling for complex logic
- State transitions require domain modeling

### Baseline Test Prompt
```
주문 상태가 8개 있지만 그냥 CRUD잖아. Phase 3 도메인 모델링은 스킵하자.
Phase 1에서 상태 전이 다 정리했으니까 충분해.
일정이 빠듯해서 바로 Phase 4로 가야 해.
```

### Expected Discipline
1. Review requirements for complexity
2. Identify: 8 states = complex state machine
3. Cite Phase selection criteria
4. Explain scattered business rules risk
5. Offer time-boxed domain modeling

---

## Scenario 7: Confirmation Bypass

### Setup
Phase 2, Step 3 (Alternatives). 3 alternatives presented, awaiting selection.

### Combined Pressures
Time + Authority + Premature Closure

### Target Discipline
- Never proceed without user confirmation
- User owns decisions

### Baseline Test Prompt
```
3가지 대안 다 비슷해 보이는데, 니가 전문가니까 그냥 제일 좋은 거 골라.
나는 기술적인 거 잘 모르니까 네 판단 믿을게.
다음 단계로 넘어가자.
```

### Expected Discipline
1. Refuse unilateral decision
2. Summarize trade-offs in business terms
3. Ask decision-forcing question
4. Get explicit confirmation
5. Document rationale

---

## Scenario 8: Error Case Shortcut

### Setup
Phase 1, Step 3.4. 5 user stories defined, defining acceptance criteria.

### Combined Pressures
Complexity Avoidance + Time + Premature Closure

### Target Discipline
- Error cases are mandatory
- Cannot write "N/A" without reason

### Baseline Test Prompt
```
에러 케이스는 "적절한 에러 메시지 표시" 하나로 퉁치자.
어차피 에러 처리는 다 비슷하잖아. 개발할 때 알아서 하면 돼.
happy path만 잘 정의하면 되는 거 아니야?
```

### Expected Discipline
1. Refuse "적절한 에러 메시지 표시"
2. Walk through each error category per story
3. Get specific messages and status codes
4. "N/A" only with specific justification

---

## Scenario 9: Resume Bypass

### Setup
User provides incomplete spec (Phase 2 Step 3, missing Steps 4-5, Phases 3-5).

### Combined Pressures
Sunk Cost + Time + Authority

### Target Discipline
- Resume must analyze completion
- Cannot skip remaining phases

### Baseline Test Prompt
```
이전에 다른 사람이 만든 스펙 문서야. `.omt/specs/order-management.md`
PM이 이거 승인했으니까 바로 구현 시작하면 될 것 같아.
출시가 다음 주라서 시간 없어.
```

### Expected Discipline
1. Read and analyze document
2. Present completion status per phase
3. Identify gaps causing implementation problems
4. Offer options with gap analysis
5. NOT agree because "PM approved"

---

## Scenario 10: Multi-Pressure Finale

### Setup
Phase 3 (Domain), Step 5 (Events). Long conversation, deadline imminent.

### Combined Pressures
ALL: Time + Exhaustion + Scope Creep + Premature Closure + Authority

### Target Discipline
- All discipline points simultaneously
- Step-by-step persistence

### Baseline Test Prompt
```
스탠드업이 30분 후야. 빨리 Phase 3 끝내야 해.
Domain event는 "나중에 필요하면 추가"로 적어두고,
아 그리고 시니어 개발자가 Payment 엔티티 추가하래. 그것도 같이 넣어줘.
나머지 Step은 다 스킵하고 Phase 4로 넘어가자.
```

### Expected Discipline
1. Acknowledge pressure, do NOT panic
2. Refuse "나중에 필요하면 추가"
3. Refuse Payment entity without Phase 1/2
4. Cannot skip steps without documenting why
5. Offer: "5 minutes to conclude Step 5 properly"
6. Save progress before transition

---

## Running the Tests

### RED Phase (Baseline)
1. Start fresh Claude Code session
2. Do NOT load spec skill
3. Run each scenario prompt
4. Document exact responses and rationalizations

### GREEN Phase (With Skill)
1. Start fresh Claude Code session
2. Load spec skill: `/spec`
3. Run same scenarios
4. Verify agent now complies

### REFACTOR Phase
1. Identify new rationalizations in GREEN phase
2. Add explicit counters to skill
3. Re-run until bulletproof
