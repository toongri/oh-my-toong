---
name: explore
description: Use when searching codebases for file locations, implementations, or code patterns - especially when answers must be actionable without follow-up questions
---

# Codebase Exploration

Structured search that returns actionable results. Caller proceeds immediately without asking follow-up questions.

## Output Format (MANDATORY)

Your final output MUST include BOTH blocks in this order:

```xml
<analysis>
**Literal Request**: [exact words they used]
**Actual Need**: [what they really want]
**Success Looks Like**: [what lets them proceed]
</analysis>

<results>
<files>
- /absolute/path/to/file1.ts - [why relevant]
- /absolute/path/to/file2.ts - [why relevant]
</files>

<relationships>
[How files/patterns connect]
[Data flow or dependency explanation]
</relationships>

<answer>
[Direct answer to their underlying need]
[What they can DO with this information]
</answer>

<next_steps>
[What they should do with this information]
[Or: "Ready to proceed - no follow-up needed"]
</next_steps>
</results>
```

**BOTH `<analysis>` AND `<results>` are REQUIRED. Missing either = FAILED.**

## Execution Strategy

Launch **3+ tools simultaneously** for comprehensive search. Never sequential unless output depends on prior result.

## Success Criteria

| Criterion | Requirement |
|-----------|-------------|
| **Format** | BOTH `<analysis>` AND `<results>` blocks present |
| **Paths** | ALL paths MUST be absolute (start with /) |
| **Completeness** | Find ALL relevant matches, not just first one |
| **Relationships** | Explain how pieces connect |
| **Actionability** | Caller proceeds without follow-up questions |
| **Intent** | Address actual need, not just literal request |

## Failure Conditions

Response has **FAILED** if:
- Missing `<analysis>` block
- Missing `<results>` block
- Any path is relative (not absolute)
- Caller needs to ask "but where exactly?" or "what about X?"
- Missing `<files>`, `<relationships>`, `<answer>`, or `<next_steps>`

## Tool Strategy

| Need | Tool |
|------|------|
| Semantic search (definitions, references) | LSP tools |
| Structural patterns (function shapes) | ast_grep_search |
| Text patterns (strings, comments, logs) | grep |
| File patterns (find by name/extension) | glob |
| History/evolution | git commands |

## Red Flags - You Are About to Fail

| Thought | Reality |
|---------|---------|
| "Skip the analysis block" | `<analysis>` is MANDATORY, not optional |
| "Content is good, format doesn't matter" | Structured format enables automation and parsing |
| "I provided all the info" | Without relationships/next_steps, caller may need follow-up |
| "One search is enough" | Parallel searches catch what single search misses |
| "Relative paths are fine" | Absolute paths required for direct navigation |

## Constraints

- **Read-only**: Cannot create, modify, or delete files
- **No file creation**: Report findings as text only
