---
name: github-issue-management
description: Manage GitHub Issues for project and product management workflows. Search for existing issues, create new issues for tasks/epics/stories, update status and comments, link related issues, and close completed work. Use for automating project tracking.
---

# GitHub Issue Management Skill

## Overview

This skill provides universal GitHub Issue management conventions for AI-powered project and product management workflows. For repository-specific configurations (milestone names, epic mappings, etc.), see your repository's `.github/instructions/github-issue-management.instructions.md` file.

## Core Practices

- Search for existing issues before creating new ones.
- Create issues for tasks, epics, stories, bugs, and spikes.
- Update issues with status, comments, and links to PRs.
- Close issues when tasks are completed.
- Use parent/child issue linking (GitHub's native feature) to connect tasks to epic parents.
- Apply labels consistently using the `.github/skills/github-issue-management/SKILL.md` skill.
- Follow repository-specific conventions documented in `.github/instructions/github-issue-management.instructions.md`.

## Label Strategy

Labels are organised into four categories. See `.github/skills/github-issue-management/references/LABELS.md` for complete definitions, colours, and usage matrix.

### Issue Type (Required)
Apply **exactly one** to every issue:
- `epic` — Epic issue; parent of child tasks.
- `story` — User story; typically child of epic.
- `bug` — Bug fix.
- `spike` — Research or investigation task (time-boxed).

### Change Type (Optional)
Apply **zero or one** based on what's being changed:
- `improvement` — Feature enhancement or new capability.
- `feature` — Feature request from users or stakeholders.
- `technical` — Internal debt, refactoring, or maintenance.

### Workflow Status (As Needed)
Apply to indicate workflow state or blockers:
- `dependency` — Has a dependency on one or more other issues.
- `feedback required` — Blocked waiting for clarification or user feedback.
- `waiting for details` — Incomplete issue; waiting for reporter to provide more information.

### Governance (As Needed)
Apply for project management and prioritization:
- `out-of-scope` — Intentionally deferred beyond current release.
- `priority-high` — High-priority work (omit medium/low to reduce noise).
- `not-started` — Epic that hasn't started active work yet.

**Important:** Do not use phase labels (e.g., `phase-6a`, `phase-6b`). Use Milestones instead (see below).

## Milestone Strategy

**Milestones organise work by phase or release**, replacing scattered phase labels. 

**When to use:**
- Assign all issues (epics and tasks) to exactly one milestone.
- Milestones group work into releases, sprints, or planning horizons.
- Use GitHub's Milestone view for roadmap and progress tracking.
- Mark completed milestones as "closed" in GitHub to keep active milestone list clean.

**Naming conventions:**
- Use clear, version-based names: `v1.0`, `v1.1`, `v2.0`.
- Or phase-based names: `Phase 1: Foundation`, `Phase 2: Enhancement`.
- Or time-based names: `2026 Q1`, `March Sprint`.
- See your repository's `.github/instructions/` files for repository-specific naming guidelines.

**Best practices:**
- Keep milestone count manageable (5-10 active at once).
- Close milestones promptly when all issues complete.
- Don't create milestones too far in advance (creates noise).

## Parent/Child Issue Linking

**When to use parent linking:**
- Epic → Task relationships.
- User story → Sub-task relationships.
- Any hierarchical work breakdown structure.

**How to link (manual UI approach):**
1. Create parent issue first (epic with `epic` label).
2. Create child issue (task with appropriate labels and milestone).
3. In child issue UI, click "Link issue" in the Relationships section.
4. Select "Add parent" and enter parent issue number.
5. GitHub will display the parent/child relationship natively in both issues.

**Automation limitation:**
- GitHub CLI (`gh`) does not currently support parent/child linking via command line.
- GitHub GraphQL API supports this via issue relationship mutations, but requires additional setup.
- For now, parent/child relationships must be established manually through the GitHub web UI.
- Automated workflows can create the issues and assign labels/milestones, but parent linking is a manual step.

**Benefits:**
- Native GitHub parent/child UI shows hierarchy clearly.
- Appears in parent epic's "Child issues" section.
- Better UX than text-only "related issue" links.
- Reduces issue description clutter.

## Issue Title Conventions

**Do:**
- Use clear, descriptive titles without prefixes.
- Keep titles action-oriented and specific.
- Examples:
  - "Add user authentication with OAuth 2.0".
  - "Fix memory leak in file processor".
  - "Validate cross-platform functionality on macOS and Linux".

**Do not:**
- Prefix with type: ❌ `[Improvement] Add user authentication`.
- Prefix with status: ❌ `[TODO] Implement oauth`.
- Prefix with phase/sprint: ❌ `Phase 2 — Add authentication`.
- Use vague titles: ❌ `Fix stuff`, ❌ `Work on Phase 6`.

**Rationale:** Labels and milestones handle categorization; keep titles clean and readable.

## Status Tracking

### For Epics
- Apply `not-started` label on new epics (indicates epic is not yet active).
- Remove `not-started` once work begins.
- Use GitHub's native OPEN/CLOSED state for completion.

### For Regular Issues
- Use GitHub's native OPEN/CLOSED state only (no status labels needed).
- Milestone shows which phase/release issue belongs to.
- Assignees and draft PRs indicate current work in progress.

### For Blocked Work
- Use `dependency` label when blocked by another issue.
- Use `feedback required` or `waiting for details` labels when blocked on external input.
- Add blocking issue reference in description: `Blocked by #123`.

## When to Create Issues

✅ **Create issues for:**
- Epics (from planning documents or high-level work streams).
- Stories and tasks (broken down from epics).
- Bugs reported by users or during testing.
- Spikes (research/investigation, time-boxed).
- Improvements identified during review.
- Technical debt and refactoring work.

❌ **Do not create issues for:**
- Planning notes or brainstorm sessions (keep in planning docs).
- Day-to-day micro-tasks (keep in milestone/epic descriptions or PR descriptions).
- Questions that can be answered in chat/email.

## Label Reference

For complete label definitions, colours, usage guidelines, and the Label Usage Matrix, see `.github/skills/github-issue-management/references/LABELS.md`.

Quick reference for label creation commands is also available in that file.

## Notes

- Regularly review and update issues to reflect current status of tasks.
- Close issues once merged/released.
- Use parent linking to maintain epic-to-task visibility.
- For repository-specific milestone naming conventions, see `.github/instructions/github-issue-management.instructions.md`.