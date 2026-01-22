---
name: code-review
description: Use when reviewing code, providing PR feedback, or writing review comments. Triggers include code review, PR review, review feedback.
---

# Code Review

## Overview

Senior-level code review agent. Evaluates code quality, security, and maintainability with severity-based feedback.

**Core Principle:** Specification compliance takes precedence over code quality. Both stages operate as iterative loops.

## Two-Stage Mandatory Review

```dot
digraph review_stages {
    rankdir=TB;

    start [label="Start Review" shape=ellipse];
    diff [label="Identify changes via git diff"];
    stage1 [label="Stage 1: Spec Compliance" shape=box style=filled fillcolor=lightblue];
    spec_pass [label="Meets spec?" shape=diamond];
    stage2 [label="Stage 2: Code Quality" shape=box style=filled fillcolor=lightgreen];
    quality_pass [label="Quality pass?" shape=diamond];
    approve [label="APPROVE" shape=ellipse style=filled fillcolor=green fontcolor=white];
    fix [label="FIX → RE-REVIEW" shape=box style=filled fillcolor=red fontcolor=white];

    start -> diff -> stage1 -> spec_pass;
    spec_pass -> fix [label="NO"];
    spec_pass -> stage2 [label="YES"];
    fix -> stage1 [style=dashed];
    stage2 -> quality_pass;
    quality_pass -> fix [label="NO"];
    quality_pass -> approve [label="YES"];
}
```

### Fast-Path Exception

Single-line edits, obvious typos, or changes with no functional behavior modification skip Stage 1 and receive only a brief Stage 2 quality check.

---

## Stage 1: Specification Compliance (Required First)

Before any code quality analysis, verify:

| Check | Question |
|-------|----------|
| ✓ | Does the implementation address **ALL** requirements? |
| ✓ | Does it solve the **correct** problem? |
| ✓ | Are any requested features **missing**? |
| ✓ | Is there any **unrequested** functionality? |
| ✓ | Would the requester **recognize** their request? |

**Outcome:** Pass → Stage 2 / Fail → FIX → RE-REVIEW loop

---

## Stage 2: Code Quality (After Stage 1 Passes)

### Security (CRITICAL)

| Item | Description |
|------|-------------|
| Hardcoded Credentials | API keys, passwords, tokens directly in code |
| SQL Injection | User input directly interpolated into queries |
| Command Injection | User input passed to system commands |
| Path Traversal | `../` enables filesystem navigation |
| SSRF | Server makes requests to user-provided URLs |
| Insecure Deserialization | Deserializing untrusted data |
| Auth Bypass | Authentication/authorization logic can be circumvented |
| Sensitive Data Exposure | Sensitive info leaked in logs or responses |

### Data Integrity (CRITICAL)

| Item | Description |
|------|-------------|
| Race Condition | Data inconsistency under concurrent access |
| Missing Transaction | Multiple DB operations not atomic |
| Null Dereference | Accessing without null check |
| Resource Leak | Connection, Stream not released |
| Deadlock Potential | Lock ordering inconsistency |

### Architecture & Design (HIGH)

| Principle | Violation | Example |
|-----------|-----------|---------|
| **Single Responsibility** | Class/function does multiple unrelated things | `UserService` handles auth, email, payment |
| **Dependency Inversion** | High-level depends on low-level concrete | Domain imports Infrastructure directly |
| **Layer Boundary** | Cross-layer dependency violation | Controller calls Repository directly |
| **Circular Dependency** | A→B→C→A cycle | Service A imports Service B which imports A |
| **God Class** | One class knows/does too much | 20+ dependencies, 30+ public methods |
| **Feature Envy** | Method uses another class more than its own | Getter chains, logic in wrong place |
| **Leaky Abstraction** | Implementation details exposed | DB entity returned from API |

### Clean Architecture (HIGH)

```
Allowed Dependencies (outer → inner only):
┌─────────────────────────────────────┐
│ Frameworks & Drivers (DB, Web, UI)  │
│  ┌─────────────────────────────┐    │
│  │ Interface Adapters          │    │
│  │  ┌─────────────────────┐    │    │
│  │  │ Application/UseCase │    │    │
│  │  │  ┌─────────────┐    │    │    │
│  │  │  │   Domain    │    │    │    │
│  │  │  └─────────────┘    │    │    │
│  │  └─────────────────────┘    │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

| Check | Violation |
|-------|-----------|
| Domain → Infrastructure | Domain entity imports JPA annotation |
| Domain → Application | Entity imports UseCase |
| UseCase → Framework | Service imports Spring Controller |
| DTO as Domain | Request/Response DTO used in business logic |

### Performance (MEDIUM)

| Item | Description |
|------|-------------|
| N+1 Query | Query execution inside loops |
| Missing Index Hint | Large table scan without index consideration |
| Inefficient Algorithm | O(n²) when O(n) is achievable |
| Blocking I/O | Blocking calls in async/reactive context |
| Memory Inefficiency | Loading large dataset into memory |
| Connection Pool Exhaustion | Connections not returned, infinite waits |

### Maintainability (MEDIUM)

| Item | Description |
|------|-------------|
| Missing Error Handling | Empty catch blocks, swallowed exceptions |
| Unclear Intent | Code requires comments to understand |
| Duplicated Logic | Same logic in multiple places (DRY violation) |
| Hard to Test | Tight coupling prevents unit testing |
| Magic Values | Unexplained literals without named constants |

### Test Quality (MEDIUM)

| Check | Description |
|-------|-------------|
| Business Logic Untested | Core domain rules have no tests |
| Test Verifies Implementation | Tests break on refactor (brittle) |
| Missing Edge Cases | Happy path only, no error scenarios |
| Test Naming Unclear | Can't understand what's being tested |

**Note:** Data classes (DTO, Entity with no logic) don't require tests.

---

## Signal Quality (Important)

### Only Flag If

- Code will **fail to compile/parse**
- Code will **definitely produce wrong results**
- **Clear** violation of documented architecture/design principles

### Never Flag

| Item | Reason |
|------|--------|
| Pre-existing issues | Not introduced by this PR |
| Linter-catchable problems | Let tools handle these |
| Style preferences | Don't flag without documented standard |
| Code not touched by this PR | Out of scope |
| "Could be better" | Don't flag without concrete problem |

### When Uncertain

**Do NOT flag.** False positives erode trust faster than missed issues.

---

## Validation (Before Posting)

For each issue found:

| Check | Question |
|-------|----------|
| ✓ | Can you **quote** the specific line? |
| ✓ | Can you **explain** why it's wrong? |
| ✓ | Can you **demonstrate** the failure case? |
| ✓ | Have you **confirmed** it's not intentional? |

**If ANY answer is NO, do NOT post that comment.**

---

## Severity Classification

| Level | Nature | Response |
|-------|--------|----------|
| **CRITICAL** | Security/data-loss risk | Must resolve before merge |
| **HIGH** | Architecture/design violation | Should resolve before merge |
| **MEDIUM** | Performance/maintainability | Address when feasible |
| **LOW** | Style/suggestions | Optional consideration |

---

## Conventional Comments

Format: `<label> [decorations]: <subject>`

### Labels

| Label | Purpose | Example |
|-------|---------|---------|
| **praise:** | Highlight good work | `praise: Clean dependency inversion here` |
| **issue:** | Problem requiring fix | `issue (blocking): Circular dependency detected` |
| **suggestion:** | Propose improvement | `suggestion: Extract to separate bounded context` |
| **question:** | Seek clarification | `question: Is this layer violation intentional?` |
| **nitpick:** | Minor style preference | `nitpick (non-blocking): Consider renaming for clarity` |
| **thought:** | Share observation | `thought: This pattern exists in other services` |
| **note:** | Provide context | `note: This API will change in v2` |

### Decorations

| Decoration | Meaning |
|------------|---------|
| **(blocking)** | Must fix before merge |
| **(non-blocking)** | Optional, author decides |
| **(if-minor)** | Fix only if making other changes |

### Example

```
issue (blocking): Circular dependency between services

OrderService → PaymentService → OrderService creates a cycle.
This makes testing difficult and indicates unclear boundaries.

// Current
class PaymentService {
    constructor(private orderService: OrderService) {}  // ❌
}

// Suggested: Use event or extract shared interface
class PaymentService {
    constructor(private orderRepository: OrderRepository) {}  // ✓
}
```

---

## Output Format

```markdown
## Summary
| Metric | Count |
|--------|-------|
| Critical | N |
| High | N |
| Medium | N |
| Low | N |
| Praise | N |

## Critical Issues
[issue (blocking): ... for each]

## High Priority
[issue (blocking): ... for each]

## Medium Priority
[suggestion: ... for each]

## Low Priority
[nitpick (non-blocking): ... for each]

## Good Practices
[praise: ... for each - REQUIRED section]

## Verdict
[APPROVE / REQUEST_CHANGES / COMMENT]
```

---

## Approval Decision

| Condition | Verdict |
|-----------|---------|
| CRITICAL or HIGH found | **REQUEST_CHANGES** |
| MEDIUM only | **COMMENT** (conditional merge approval) |
| LOW only or no issues | **APPROVE** |

---

## Red Flags - STOP

| Excuse | Reality |
|--------|---------|
| "Security is another team's concern" | Every developer owns security |
| "Architecture can be fixed later" | Violations spread and compound |
| "It works, so it's fine" | Working ≠ maintainable |
| "Tests will catch it" | Catching at review is cheapest |
| "Not sure but flag anyway" | False positives erode trust |
| "No time for praise" | Balance builds collaborative culture |

---

## Quick Reference

```
Stage 1: Spec Compliance → Stage 2: Code Quality

CRITICAL: Security, Data Integrity
HIGH: Architecture, Design Principles (SRP, DI, Clean Architecture)
MEDIUM: Performance, Maintainability, Test Quality
LOW: Style, Suggestions

Key Design Checks:
- Dependency direction (outer → inner only)
- No circular dependencies
- Single responsibility per class/function
- Layer boundaries respected
- Domain free from framework concerns
```

**Tone check:** Replace commands with questions.
- "Should be X" → "What about X?"
- "Wrong" → "question: Is this intentional?"
