---
description: Orchestrate complex tasks with Ralph Loop (oracle-verified completion)
---

ralph

## MANDATORY FIRST ACTION

**YOU MUST CALL `Skill(skill: "sisyphus")` AS YOUR VERY FIRST ACTION.**

```
Skill(skill: "sisyphus")
```

**DO NOT:**
- Start analyzing the task yourself
- Use any tools (Grep, Read, Glob, Task, etc.) before loading sisyphus
- Delegate to agents before loading sisyphus
- Interpret what the user wants before loading sisyphus

**THE ONLY VALID FIRST ACTION IS:**
```
Skill(skill: "sisyphus")
```

After sisyphus skill is loaded, follow its workflow with ralph loop enabled for this task:

$ARGUMENTS
