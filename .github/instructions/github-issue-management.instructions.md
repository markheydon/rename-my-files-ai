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

## Issue Hierarchy Framework

This section defines **what** Milestones, Epics, Stories, and Tasks are, **when** to create them, and **how** they map to GitHub features.

### Definitions and GitHub Mapping

| Concept | Purpose | GitHub Feature | Example |
|---------|---------|----------------|---------|
| **Milestone** | Timeline/delivery grouping. Answers: "WHEN is this being delivered?" | GitHub Milestone | "Phase 6: Enhanced Content Extraction" |
| **Epic** | Large feature set requiring multiple stories. Answers: "WHAT cohesive capability?" | GitHub Issue with `epic` label | "PDF Text Extraction Support" (if 3+ related stories) |
| **Story** | User-facing deliverable. Answers: "What can users DO now?" Maps to one PR/branch. | GitHub Issue with `story` label | "Add image OCR support for .jpg, .png files" |
| **Task** | Implementation step within a story. Not shipped independently. | Checklist item in story's acceptance criteria | "Research Azure AI Vision API", "Implement error handling" |

### When to Create Each Type

#### Milestones (Always Create)

✅ **Create one milestone per phase** from `plan/IMPLEMENTATION_PLAN.md`  
✅ Every phase gets a milestone, even if it has only one story  
✅ Milestone tracks delivery timeline, not feature grouping

#### Epics (Only When Necessary)

✅ **Create an epic only if:**
- There are **3+ related stories** that form a cohesive capability
- The stories are tightly related (same feature area, same technology)
- Grouping provides meaningful organisation beyond the milestone

❌ **Do NOT create an epic if:**
- The phase has fewer than 3 stories
- The epic title/description would duplicate the milestone
- It's a 1:1 epic-to-milestone mapping
- Stories are too diverse to form a logical group

**Decision rule:** If you can't explain why the epic is different from the milestone without just repeating the phase name, **don't create the epic**.

#### Stories (Default Unit of Work)

✅ **Create a story for each user-facing deliverable:**
- One story = one PR = one merged branch
- Completable in one sitting (or 2-3 max)
- Delivers testable user value
- Can be demonstrated to stakeholders

❌ **Do NOT split stories into:**
- Separate "research" and "implement" stories (research is a task within the story)
- Separate "documentation" or "testing" stories (these are tasks within acceptance criteria)
- Artificially small chunks that don't deliver independent value

**Story = Feature that ships to users**

#### Tasks (Implementation Details)

✅ **Tasks are checklist items within a story's acceptance criteria:**
- Research/spike work
- Implementation steps
- Testing activities
- Documentation updates
- Code review items

❌ **Tasks are NOT separate GitHub Issues**

### Examples

#### ✅ CORRECT: Phase with Multiple Related Stories (Epic Justified)

**Scenario:** Phase has 6 stories for PDF, Image, and Office extraction

```
Milestone: Enhanced Content Extraction
  ├─ Epic: PDF Text Extraction
  │    ├─ Story: Extract text from simple PDFs
  │    └─ Story: Handle complex PDF layouts
  ├─ Epic: Image OCR Support
  │    ├─ Story: Add OCR for scanned documents
  │    └─ Story: Add OCR for photos with text
  └─ Epic: Office Document Extraction
       ├─ Story: Extract text from .docx files
       └─ Story: Extract text from .xlsx and .pptx files
```

#### ✅ CORRECT: Phase with Few Stories (No Epic Needed)

**Scenario:** Phase has 2 unrelated stories

```
Milestone: Enhanced Content Extraction
  ├─ Story: Add image OCR support for .jpg, .png files
  │    └─ Tasks (in acceptance criteria):
  │         - [ ] Research and select OCR library (Azure AI Vision vs alternatives)
  │         - [ ] Implement text extraction in Rename-MyFiles.ps1
  │         - [ ] Add error handling for unsupported image formats
  │         - [ ] Test with sample images (scanned docs, photos)
  │         - [ ] Update README with OCR prerequisites
  │
  └─ Story: Add Office document text extraction (.docx, .xlsx, .pptx)
       └─ Tasks (in acceptance criteria):
            - [ ] Research and select extraction library
            - [ ] Implement extraction in Rename-MyFiles.ps1
            - [ ] Handle unsupported Office formats gracefully
            - [ ] Test with sample Office files
            - [ ] Document known limitations
```

#### ❌ WRONG: Artificially Split Stories

**Don't do this:**
```
Story: Research image OCR approach
Story: Implement image OCR
Story: Test image OCR
Story: Document image OCR
```

**Do this instead:**
```
Story: Add image OCR support for .jpg, .png files
  - [ ] Research and select OCR method (task)
  - [ ] Implement text extraction (task)
  - [ ] Test with sample images (task)
  - [ ] Update documentation (task)
```

#### ❌ WRONG: Epic Duplicating Milestone

**Don't do this:**
```
Milestone: Validation and Release
  └─ Epic: Validation and Release Readiness  ← This is just the milestone again!
       └─ Story: Finalize release package
```

**Do this instead:**
```
Milestone: Validation and Release
  └─ Story: Prepare and validate v1.0 release package
       - [ ] Cross-platform testing (Windows, Linux, macOS)
       - [ ] Finalize README and user documentation
       - [ ] Create release artifacts
       - [ ] Validate installation on clean systems
```

### Story-to-PR Mapping

**Mental model:** One story = one branch = one pull request

- Each story should result in a single merged PR to `main`
- Multiple commits are fine (research findings, implementation, test fixes, code review changes)
- But ultimately, the story ships as one cohesive unit of user value
- If you find yourself creating multiple PRs for sub-tasks, you've probably split the story too far

## Issue Description Templates

### Story Issue Template (Most Common)

```markdown
## Description
[What user-facing capability this delivers — derive from IMPLEMENTATION_PLAN.md]

As a user, I can [user goal/benefit].

## Acceptance Criteria and Tasks
- [ ] Research and select approach ([decision criteria])
- [ ] Implement [feature] in `scripts/Rename-MyFiles.ps1`
- [ ] Add error handling for [edge cases]
- [ ] Test with [sample scenarios]
- [ ] Update README/documentation with [new capability]
- [ ] Passes PSScriptAnalyzer with no errors

## Related Files
- `scripts/Rename-MyFiles.ps1`
- `plan/IMPLEMENTATION_PLAN.md#phase-x`

## Parent Epic (if applicable)
See parent epic #[number]
```

### Epic Issue Template (Rarely Needed)

**Only create if there are 3+ related stories that need grouping.**

```markdown
## Objective
[High-level goal for this epic — derive from plan/IMPLEMENTATION_PLAN.md]

This epic groups related stories for [cohesive capability area].

## Rationale
[Why this grouping matters — must be different from milestone description]

## Scope
- [ ] Story 1: [user-facing deliverable]
- [ ] Story 2: [user-facing deliverable]
- [ ] Story 3: [user-facing deliverable]

## Related Documentation
- `plan/IMPLEMENTATION_PLAN.md#phase-x`
- `plan/SCOPE.md`

## Child Issues
[These will auto-populate when parent/child relationships are established in GitHub UI]
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

### Mark's Personal Project Board Assignment

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

**Automation note:** While issue creation/labelling/milestone assignment can be fully automated via `gh` CLI, **project board addition is best done manually** (via web UI) during the `mat-plan` workflow. The `gh project` commands work but require knowing the numeric project ID, and manual addition ensures you review which active tasks actually belong on your board (respecting the `out-of-scope` exclusion rule).

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
