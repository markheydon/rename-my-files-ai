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

Apply labels according to the universal guidance in `.github/skills/github-issue-management/SKILL.md`.

Use **only** official labels defined in `.github/skills/github-issue-management/references/LABELS.md`. Remove any non-standard labels immediately.

## Prerequisites for Automation

**GitHub CLI Setup Required**

All GitHub Issue automation in this repository uses GitHub CLI (`gh`) rather than MCP-based approaches because:
- ✅ Simpler setup (just `gh auth login` once)
- ✅ No additional MCP server dependencies
- ✅ Direct access to your existing GitHub authentication
- ✅ Works seamlessly with PowerShell automation scripts

**Setup:**
```bash
# Install GitHub CLI: https://cli.github.com
gh auth login  # One-time setup
```

See [GitHub CLI documentation](https://cli.github.com) or [Awesome Copilot's gh-cli skill](https://github.com/github/awesome-copilot/tree/main/skills/gh-cli) for comprehensive reference.

## Project Board Integration

### Personal Project Board Assignment

Non-epic issues in **active (current phase) milestones** should be added to your personal project board at [github.com/users/markheydon/projects/6](https://github.com/users/markheydon/projects/6).

**Rules:**
- ✅ **Add to board:** Any task, story, bug, or spike in an **active milestone** (e.g., the current phase you're working on) that **does not have the `out-of-scope` label**
- ❌ **Do not add:** 
  - Epics (parent issues) — keep in GitHub Issues only
  - Any issue with `out-of-scope` label — regardless of milestone
  - Issues in future/inactive milestones
  - Issues marked as deferred or blocked indefinitely
- ✅ **Update status:** Use the project board's status field to track progress (e.g., "In Progress", "Done")
- ✅ **Remove when done:** Close the issue → remove from board

**Rationale:** The project board provides personal task visibility and workflow tracking for **actively working** items only. Out-of-scope work stays in GitHub Issues for roadmap/archive purposes. Epics remain structured in GitHub Issues for high-level planning; individual work items are tracked on your board.

## Workflow Integration

### AI Agent Prompts

- **mat-plan**: Reads `plan/IMPLEMENTATION_PLAN.md`, creates/updates GitHub Issues (epics and tasks), assigns milestones, applies labels
- **mat-next-task**: Selects smallest next task from open issues, considering milestone priorities and dependencies

### GitHub CLI Project Board Integration

To add issues to your personal project board via `gh` CLI:

```powershell
# Add issue to project board (requires project board ID)
gh project item-add PROJECT_ID --owner markheydon --repo rename-my-files-ai --issue ISSUE_NUMBER

# Example:
gh project item-add 6 --owner markheydon --repo rename-my-files-ai --issue 123
```

**Automation note:** While issue creation/labeling/milestone assignment can be fully automated via `gh` CLI, **project board addition is best done manually** (via web UI) during the `mat-plan` workflow. The `gh project` commands work but require knowing the numeric project ID, and manual addition ensures you review which active tasks actually belong on your board (respecting the `out-of-scope` exclusion rule).

### Manual Steps Required

- **Parent/child linking**: GitHub CLI does not support automated parent/child relationships. After creating epic and task issues:
  1. Open child issue in GitHub web UI
  2. Click "Link issue" → "Add parent"
  3. Enter parent epic issue number
  4. Save

- **Project board addition**: Non-epic issues in active milestones (excluding `out-of-scope`) should be manually added to your personal project board during the `mat-plan` workflow or as work becomes active.

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
