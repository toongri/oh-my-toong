---
name: spec
description: Use when creating software specifications - transforms requirements into structured specification documents through phased analysis workflow
---

# Spec - Software Specification Expert

## Overview

As a software specification expert, transform user requirements into structured specification documents. Each phase is optional, proceeding only with necessary steps based on project requirements.

## Workflow Decision Tree

```dot
digraph spec_workflow {
    rankdir=TB;
    node [shape=box];

    // Entry
    start [label="User Request" shape=ellipse];

    // Phase 1: Requirements
    req_needed [label="Requirements analysis\nneeded?" shape=diamond];
    req_phase [label="Phase 1: Requirements Analysis\n(01-requirements.md)"];

    // Phase 2: Architecture
    arch_needed [label="Architecture design\nneeded?" shape=diamond];
    arch_phase [label="Phase 2: Architecture Design\n(02-architecture.md)"];

    // Phase 3: Domain
    domain_needed [label="Domain modeling\nneeded?" shape=diamond];
    domain_phase [label="Phase 3: Domain Modeling\n(03-domain.md)"];

    // Phase 4: Detailed
    detailed_needed [label="Detailed design\nneeded?" shape=diamond];
    detailed_phase [label="Phase 4: Detailed Design\n(04-detailed.md)"];

    // Phase 5: API
    api_needed [label="API design\nneeded?" shape=diamond];
    api_phase [label="Phase 5: API Design\n(05-api.md)"];

    // End
    complete [label="Specification Complete\nSaved to .omt/specs/*.md" shape=ellipse];

    // Flow
    start -> req_needed;

    req_needed -> req_phase [label="yes"];
    req_needed -> arch_needed [label="no\n(already clear)"];
    req_phase -> arch_needed;

    arch_needed -> arch_phase [label="yes"];
    arch_needed -> domain_needed [label="no\n(simple feature)"];
    arch_phase -> domain_needed;

    domain_needed -> domain_phase [label="yes"];
    domain_needed -> detailed_needed [label="no\n(CRUD-centric)"];
    domain_phase -> detailed_needed;

    detailed_needed -> detailed_phase [label="yes"];
    detailed_needed -> api_needed [label="no\n(implementation obvious)"];
    detailed_phase -> api_needed;

    api_needed -> api_phase [label="yes"];
    api_needed -> complete [label="no\n(internal feature)"];
    api_phase -> complete;
}
```

## Phase Selection Criteria

| Phase | When Needed | When Can Be Skipped |
|-------|------------|---------------------|
| 01-Requirements Analysis | Business requirements are ambiguous or complex | Requirements are already clearly defined |
| 02-Architecture Design | System structure changes, multi-component integration | Single feature addition, following existing patterns |
| 03-Domain Modeling | Complex business logic, state transitions | Simple CRUD, data transfer focused |
| 04-Detailed Design | Performance optimization, concurrency handling, state management | Implementation is obvious |
| 05-API Design | Externally exposed APIs, client integration | Only internal module communication |

## Subagent Utilization Guide

Utilize the following subagents appropriately in each phase.

### oracle (Architecture/Technical Consultation)

**When to Use:**
- When technical decisions are needed (e.g., "Redis vs PostgreSQL for caching")
- When impact analysis of existing architecture is needed
- When trade-off analysis is needed

**Example Request:**
```
Question for oracle: "What impact would introducing event-driven processing have on the current monolithic structure?"
```

### librarian (External Documentation/Best Practices Research)

**When to Use:**
- When external library/framework usage guidance is needed
- When industry best practices need to be referenced
- When official documentation of a specific technology needs to be verified

**Example Request:**
```
Request for librarian: "Research how to implement Aggregate Root pattern in Spring Data JPA"
```

### explore (Existing Codebase Pattern Exploration)

**When to Use:**
- When existing project implementation patterns need to be understood
- When checking how similar features are implemented
- When project conventions need to be understood

**Example Request:**
```
Request for explore: "Find how the Repository pattern is implemented in the current project"
```

## Interaction Pattern

Follow this pattern in all phases.

### 1. Information Gathering
- Ask clear and specific questions to the user when factual information is needed
- Use subagents to research technical facts

### 2. Analysis and Proposal
- Present expert analysis and best practices first
- When there are multiple alternatives, present pros and cons together
- Request user's opinion or decision

### 3. Confirmation
- Summarize decisions after user response
- Get confirmation before moving to the next step

### 4. Phase Transition
- Briefly summarize the results of the current step
- Explain what will be covered in the next step
- Confirm readiness to proceed

## Clarification Guidance

When requirements are unclear:

1. **Identify Ambiguous Parts**: Determine specifically what information is missing
2. **Write Clarifying Questions**: Ask open-ended questions that cannot be answered with yes/no
3. **Present Alternatives**: Present possible interpretations and request selection
4. **Proceed After Confirmation**: Only proceed to the next step after clarification

**Example:**
```
You mentioned "user authentication". Which of the following scopes do you mean?
1. Login/logout only
2. Including OAuth integration
3. Including authorization management (RBAC)
```

## Output Location

All specification documents are saved in the `.omt/specs/` directory.

**Naming Convention:** `.omt/specs/{feature-name}.md`

**Examples:**
- `.omt/specs/user-authentication.md`
- `.omt/specs/order-management.md`
- `.omt/specs/notification-system.md`

## Step-by-Step Persistence

**Core Principle**: Save progress to `.omt/specs/{feature-name}.md` whenever each Step is completed.

### Workflow

```dot
digraph step_persistence {
    rankdir=TB;
    node [shape=box];

    step_start [label="Step Start" shape=ellipse];
    do_work [label="Perform Step Work\n(Questions, Analysis, Discussion)"];
    user_confirm [label="User Confirmation" shape=diamond];
    save_to_file [label="Save current progress\nto .omt/specs/{feature}.md"];
    announce [label="'Step N complete. Saved.\nShall we proceed to the next Step?'"];
    next_step [label="Next Step" shape=ellipse];

    step_start -> do_work;
    do_work -> user_confirm;
    user_confirm -> save_to_file [label="Confirmed"];
    user_confirm -> do_work [label="Needs revision"];
    save_to_file -> announce;
    announce -> next_step;
}
```

### When to Save

Save **whenever each Step in each Phase is completed**:
- Add/update that content to the document upon Step completion
- Preserve content from previous Steps
- Do not include Steps that have not yet been started in the document

### Document Structure

The saved document reflects progress:

```markdown
# [Project Name] Specification Document

> **Progress Status**: Phase 1 Step 3 Complete
> **Last Updated**: 2024-01-15

## Phase 1: Requirements Analysis

### Step 1: Project Overview
[Completed content]

### Step 2: Business Requirements
[Completed content]

### Step 3: Use Cases
[Completed content]

---
*Phase 1 in progress - Continuing from Step 4*
```

## Resume from Existing Spec

When the user provides an existing spec document or requests "continue from here", "review this", "brainstorm with me", etc.:

### Resume Workflow

```dot
digraph resume_flow {
    rankdir=TB;
    node [shape=box];

    request [label="User Request\n(Document path or content provided)" shape=ellipse];
    read_doc [label="Review existing document"];
    analyze [label="Analyze completed Steps/Phases"];
    is_complete [label="All Phases complete?" shape=diamond];
    identify_next [label="Identify next starting point"];
    ask_user [label="'Shall we proceed from\n[Phase X Step Y]?'"];
    nothing_to_do [label="'This appears to be complete.\nWhat else do you need?'"];
    proceed [label="Proceed from that Step" shape=ellipse];

    request -> read_doc;
    read_doc -> analyze;
    analyze -> is_complete;
    is_complete -> identify_next [label="No"];
    is_complete -> nothing_to_do [label="Yes"];
    identify_next -> ask_user;
    ask_user -> proceed;
}
```

### Analysis Criteria

Read the document and verify the following:

| Check Item | Judgment Criteria |
|------------|-------------------|
| Phase Completion | All Step sections for that Phase exist and have content |
| Step Completion | Step section has meaningful content (excluding empty templates) |
| Next Starting Point | First incomplete Step |

### Resume Conversation Example

**User**: Continue designing `.omt/specs/order-management.md`

**AI**: I've reviewed the document.

- ✅ Phase 1: Requirements Analysis - Complete
- ✅ Phase 2: Architecture Design - Complete
- 🔄 Phase 3: Domain Modeling - Step 2 complete
- ⬜ Phase 4: Detailed Design - Not started
- ⬜ Phase 5: API Design - Not started

Shall we proceed from **Phase 3 Step 3 (Domain Rules Definition)**?

## Phase Files

Detailed guides for each phase are in the `phases/` directory.

| Phase | File | Description |
|-------|------|-------------|
| Phase 1 | `phases/01-requirements.md` | Requirements Analysis |
| Phase 2 | `phases/02-architecture.md` | Architecture Design |
| Phase 3 | `phases/03-domain.md` | Domain Modeling (DDD) |
| Phase 4 | `phases/04-detailed.md` | Detailed Design |
| Phase 5 | `phases/05-api.md` | API Design |

## Language

- All communication with the user is in **English**
- Generated documents are also written in **English**
- Code examples and technical terms may retain their original English form
