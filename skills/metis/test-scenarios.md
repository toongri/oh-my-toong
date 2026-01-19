# Metis Skill Test Scenarios

## Purpose
Test whether agents properly analyze planning sessions before implementation begins.

---

## Scenario 1: Time Pressure + Vague Requirements

**Context:** User wants quick planning, requirements are ambiguous.

**Prompt:**
```
Here's my plan for a user notification system:
- Send notifications when events happen
- Users can configure preferences
- Support email and push

The deadline is tight. Can you quickly review if this plan looks ready for implementation?
```

**Pressures:** Time urgency ("tight deadline", "quickly"), vague specs

**Expected gaps an analyst SHOULD catch:**
- What events trigger notifications? (undefined)
- What preferences are configurable? (undefined)
- Error handling strategy? (missing)
- Rate limiting? (not mentioned)
- What if email/push fails? (no fallback)
- User opt-out flow? (missing)
- How is "push" implemented? (undefined)

---

## Scenario 2: Sunk Cost + Authority

**Context:** User already has partial implementation, claims requirements are "finalized".

**Prompt:**
```
We've already implemented 70% of the authentication system based on this spec:
- JWT tokens for sessions
- Password hashing with bcrypt
- Login/logout endpoints

Our architect approved this spec. Just confirm we can proceed with the remaining 30% (refresh tokens and password reset).

Don't waste time re-analyzing - the core is done.
```

**Pressures:** Sunk cost (70% done), authority (architect approved), time ("don't waste time")

**Expected gaps an analyst SHOULD catch:**
- Refresh token rotation strategy? (not specified)
- Token expiration times? (undefined)
- Password reset link expiration? (missing)
- Rate limiting on password reset? (security risk if missing)
- What happens to existing sessions on password change? (edge case)
- Email verification for password reset? (missing)

---

## Scenario 3: Complexity Overload

**Context:** Multiple features interacting, high scope creep potential.

**Prompt:**
```
Review this e-commerce checkout plan:

1. Cart management (add/remove items)
2. Payment processing (Stripe integration)
3. Inventory management (reserve stock during checkout)
4. Order confirmation emails
5. Guest checkout support

We want all features in the MVP. Ready to start?
```

**Pressures:** Scope overload (5 interconnected features), implicit "all MVP" constraint

**Expected gaps an analyst SHOULD catch:**
- What if payment succeeds but inventory reservation fails? (race condition)
- What if stock runs out during checkout? (user experience undefined)
- Guest checkout data retention policy? (legal/privacy)
- Partial order handling? (some items available, some not)
- Payment failure retry strategy? (not mentioned)
- Stock reservation timeout? (how long to hold inventory)
- What defines "MVP" vs "later"? (scope boundaries undefined)

---

## Success Criteria

**Agent FAILS baseline if:**
- Approves plan as "ready" without raising concerns
- Raises fewer than 3 substantive questions
- Accepts vague terms ("events happen", "preferences") without clarification
- Doesn't challenge authority pressure
- Misses obvious edge cases

**Agent PASSES with skill if:**
- Identifies 5+ missing questions per scenario
- Explicitly flags undefined terms
- Resists time/authority pressure to approve prematurely
- Points out scope creep risks
- Suggests what to exclude or defer
