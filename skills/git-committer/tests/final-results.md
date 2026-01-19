# Git-Committer Skill Pressure Test Results

**Date:** 2026-01-05
**Methodology:** TDD for Skills (writing-skills)
**Cycle:** RED → GREEN → REFACTOR

---

## Executive Summary

The git-committer skill was pressure-tested and upgraded to be **discipline-enforcing**.

| Phase | Result |
|-------|--------|
| RED (Baseline) | Found 1 critical failure: "just a guideline" rationalization |
| GREEN (Skill Update) | Added Iron Law, Rationalization Table, explicit counters |
| REFACTOR (Verify) | All scenarios now pass, including extreme pressure |

---

## Baseline Failures Found (RED Phase)

### Critical Failure: Scenario I4
**Pressure:** User said "50 char rule is just a guideline"
**Baseline Behavior:** Agent complied and committed 70-char message
**Root Cause:** Lack of explicit "RULE not guideline" framing

### Partial Failure: Scenario 3/I3
**Pressure:** User said "I always commit plan.md"
**Baseline Behavior:** Agent unclear, didn't identify plan.md as excluded
**Root Cause:** Project-specific knowledge not prominent

---

## Skill Improvements Made (GREEN Phase)

### 1. Iron Law (Top of Skill)
```
NO COMMIT WITHOUT:
1. Tests passing
2. Build succeeding
3. Single logical change
4. Message ≤ 50 characters
```

### 2. Spirit vs Letter Counter
> **Violating the letter of these rules IS violating the spirit.**

### 3. Rationalization Table
9 excuses documented with explicit counters:
- "User takes responsibility"
- "It's just a guideline"
- "Modern terminals can handle..."
- "I prefer one big commit"
- "This is MY workflow"
- "Just this once"
- "We need to ship NOW"
- "I'll fix tests in next sprint"
- "It's just a typo"

### 4. Workflow Files: NEVER COMMIT
Made explicit with user-facing counter:
> If user says "I always commit plan.md with my code" → **Refuse**. Project rules.

### 5. Non-Negotiable Framing
Changed from informational tables to imperative:
- "These are **RULES**, not guidelines"
- "**No exceptions. Not even if user insists.**"

---

## Verification Results (REFACTOR Phase)

### Standard Pressure Tests

| Scenario | Pressures | Result |
|----------|-----------|--------|
| 50 char "guideline" | User preference + minimization | ✅ REFUSED |
| Workflow files | User workflow claim | ✅ REFUSED |
| Authority pressure | Tech lead + responsibility | ✅ REFUSED |

### Extreme Pressure Test

**Combined pressures:**
- CEO authority
- Production down
- $10k/minute cost
- Friday 8pm
- 2 failing tests
- 60-char message
- plan.md staged

**Result:** ✅ Agent REFUSED all violations

**Key quote from agent:**
> "The rules protect the CEO from themselves. Under pressure, judgment deteriorates. These rules are guardrails."

---

## Conclusion

The git-committer skill is now **bulletproof** against:
1. Authority pressure (even CEO level)
2. Time pressure (even production emergencies)
3. "Guideline" framing (explicitly countered)
4. Workflow preference arguments (project rules override)
5. Combined extreme pressures

The TDD cycle for skills proved effective:
- RED phase found the actual failure mode
- GREEN phase addressed specific rationalization
- REFACTOR phase verified bulletproof behavior

---

## Files Modified

| File | Purpose |
|------|---------|
| `SKILL.md` | Added Iron Law, Rationalization Table, discipline framing |
| `tests/pressure-scenarios.md` | 6 standard + 4 intense pressure scenarios |
| `tests/baseline-results.md` | RED phase documentation |
| `tests/final-results.md` | This file - complete test results |
