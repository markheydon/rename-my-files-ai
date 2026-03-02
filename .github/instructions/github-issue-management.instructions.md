---
name: GitHub Issue Management Instructions
description: Repository-specific GitHub Issue management conventions for the rename-my-files project. Defines HOW to create and manage issues, not WHAT work is planned (see plan/IMPLEMENTATION_PLAN.md for planning content).
applyTo: "plan/*.md"
---

# GitHub Issue Management Instructions for rename-my-files

This file contains repository-specific GitHub Issue management **conventions and process** for the **rename-my-files** project. For universal GitHub Issue management guidelines, see the `.github/skills/github-issue-management/SKILL.md`.

## Repository Context

- **Repository:** markheydon/rename-my-files-ai
- **Planning Documents (source of truth):** `plan/SCOPE.md`, `plan/IMPLEMENTATION_PLAN.md`, `plan/RUNBOOK.md`
- **Management Approach:** Phase-based development with milestones tracking progress

## Milestone Conventions

### How Milestones Map to Phases

- Each phase in `plan/IMPLEMENTATION_PLAN.md` corresponds to **one GitHub milestone**
- Milestone **title** = Phase name (e.g., "Enhanced Content Extraction" for Phase 6)
- Milestone **description** = Brief summary of phase objective (1-2 sentences)
- Milestone **status**:
  - **Closed** = Phase complete (all tasks finished)
  - **Open** = Phase active or pending

### Milestone Assignment Rules

- **All issues** (epics and tasks) must be assigned to exactly one milestone
- Milestone assignment derived from phase location in `plan/IMPLEMENTATION_PLAN.md`
- **Out-of-scope work** (deferred features) gets milestone assignment + `out-of-scope` label

## Issue Description Templates

### Epic Issue Template

```markdown
## Objective
[High-level goal for this epic — derive from plan/IMPLEMENTATION_PLAN.md]

## Rationale
[Why this epic is important — link to SCOPE.md or IMPLEMENTATION_PLAN.md context]

## Scope
- [ ] [Sub-task 1 — pull from phase task breakdown in IMPLEMENTATION_PLAN.md]
- [ ] [Sub-task 2]
- [ ] [Sub-task 3]

## Related Documentation
- `plan/IMPLEMENTATION_PLAN.md#phase-x`.
- `plan/SCOPE.md`.

## Child Issues
[These will auto-populate when parent/child relationships are established in GitHub UI]
```

### Task Issue Template

```markdown
## Description
[What needs to be done — derive from IMPLEMENTATION_PLAN.md task checklist]

## Acceptance Criteria
- [ ] [Criterion 1 — pull from IMPLEMENTATION_PLAN.md validation steps]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Parent Epic
See parent epic #[number]

## Related Files
- `scripts/[relevant-script].ps1`
- `plan/IMPLEMENTATION_PLAN.md`
```

**Note:** Template content placeholders should be populated from `plan/IMPLEMENTATION_PLAN.md`, which is the source of truth for task breakdown, objectives, and acceptance criteria.


## References in Issue Descriptions

When creating issues, use these link patterns:

- **Parent epics:** `See parent epic [#11](https://github.com/markheydon/rename-my-files-ai/issues/11)`
- **Related issues:** `Blocked by #[number]` or `Depends on #[number]`
- **Code files:** `scripts/Rename-MyFiles.ps1` (relative path from repo root)

## Label Usage Conventions and Assignment Rules

Apply labels according to the `.github/skills/github-issue-management/SKILL.md` in the SKILL instructions.

**Remove any labels that are NOT in the official label list.** Ensure consistency by only using approved labels.

## Workflow Integration

### AI Agent Prompts

- **mat-plan**: Reads `plan/IMPLEMENTATION_PLAN.md`, creates/updates GitHub Issues (epics and tasks), assigns milestones, applies labels
- **mat-next-task**: Selects smallest next task from open issues, considering milestone priorities and dependencies

### Manual Steps Required

- **Parent/child linking**: GitHub CLI does not support automated parent/child relationships. After creating epic and task issues:
  1. Open child issue in GitHub web UI
  2. Click "Link issue" → "Add parent"
  3. Enter parent epic issue number
  4. Save

### Synchronisation Workflow

1. Update `plan/IMPLEMENTATION_PLAN.md` with new phases, tasks, or status changes (source of truth).
2. Run `mat-plan` agent to sync GitHub Issues with updated plan.
3. Manually link parent/child relationships in GitHub UI.
4. Close milestones when all issues in that phase are complete.
5. Periodically review and clean up legacy labels.

## Best Practices

- **Single source of truth:** `plan/IMPLEMENTATION_PLAN.md` is authoritative for all planning content (phases, tasks, objectives, acceptance criteria).
- **GitHub Issues mirror the plan:** Issues should reflect `IMPLEMENTATION_PLAN.md` structure, not introduce new planning details.
- **Milestones = Phases:** Use milestones for phase organisation instead of phase-specific labels.
- **Minimal labels:** Apply *ONLY* official labels as defined in the SKILL instructions; remove any non-standard labels immediately.
- **Regular sync:** Update GitHub Issues after any `IMPLEMENTATION_PLAN.md` changes to maintain alignment.
