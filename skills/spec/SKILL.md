---
name: spec
description: Use when creating software specifications. Triggers include "spec", "specification", "design doc", "PRD", "requirements analysis", "architecture design", "domain modeling", "API design", "technical spec"
---

# Spec - Software Specification Expert

Transform user requirements into structured specification documents. Each phase is optional, proceeding only with necessary steps.

## The Iron Law

```
NO PHASE COMPLETION WITHOUT:
1. User confirmation of understanding
2. All acceptance criteria testable
3. No "TBD" or vague placeholders remaining
4. Document saved to .omt/specs/
```

**Violating the letter of these rules IS violating the spirit.** No exceptions.

## Red Flags - STOP

- User says "skip requirements" -> Document everything first
- Acceptance criteria uses "properly", "gracefully" -> Get specifics
- User rushes "just document what I said" -> Verify understanding
- User wants to skip Phase 3 for system with 3+ states -> Domain modeling needed
- Error cases marked "N/A" without reason -> All use cases need error cases
- Implementation details in requirements (Redis, Kafka) -> Move to Phase 4

## Rationalization Table

| Excuse | Response |
|--------|----------|
| "I know my requirements" | Document everything |
| "We'll clarify during implementation" | Clarify now |
| "This is obvious" | If not written, it doesn't exist |
| "PM approved" | Approval is not completeness |
| "You're the expert, decide" | Get explicit confirmation |

## Non-Negotiable Rules

| Rule | Why |
|------|-----|
| Testable acceptance criteria | Untestable = unverifiable |
| Error cases defined | Happy path only = production incidents |
| User confirmation at checkpoints | Agent decisions = user blamed |
| Phase skip requires evidence | "Simple" hides complexity |

## Phase Selection

| Phase | When Needed | Skip When |
|-------|-------------|-----------|
| 01-Requirements | Ambiguous requirements | Already defined |
| 02-Architecture | System structure changes | Existing patterns |
| 03-Domain | 3+ states, business rules | Simple CRUD |
| 04-Detailed | Performance, concurrency | Implementation obvious |
| 05-API | External API exposure | Internal only |
| 06-Wrapup | Records to preserve | Nothing to preserve |

## Phase Entry Criteria

| Phase | Entry Criteria |
|-------|---------------|
| 1 | Request received, scope understood |
| 2 | Phase 1 complete OR requirements documented |
| 3 | Architecture decided; 3+ states |
| 4 | Domain model OR simple CRUD confirmed |
| 5 | External API needed |
| 6 | Spec concluding; records exist |

## Subagent Selection

| Need | Agent |
|------|-------|
| Technical decisions, trade-offs | oracle |
| External documentation | librarian |
| Existing codebase patterns | explore |

## Context Brokering

**NEVER burden the user with questions the codebase can answer.** Use explore/oracle for codebase questions, ask user for preferences only.

## Language

- Communication: Korean / Documents: English / Code terms: Original English

## References

- **Phase details**: See `phases/` directory (01-06)
- **Protocols**: See `references/protocols.md` (Checkpoint, Record, Resume)
- **Output templates**: See `templates/`
