# GitHub Issue Label Reference

This document defines all standard labels for GitHub Issue management, organised by category.

## Label Categories

### Issue Type
Labels that define the fundamental type of work. Apply **exactly one** of these to every issue:

| Label | Description | Color |
|-------|-------------|-------|
| `epic` | Epic issue; parent of child tasks | `3E4B9E` |
| `story` | User story; typically child of epic | `0E8A16` |
| `bug` | Bug fix | `D73A4A` |
| `spike` | Research or investigation task (time-boxed) | `8B72C8` |

### Change Type
Labels that describe the nature of the change. Apply **zero or one** of these based on what's being changed:

| Label | Description | Color |
|-------|-------------|-------|
| `improvement` | Feature enhancement or new capability | `A2EEEF` |
| `feature` | Feature request from users or stakeholders | `FBCA04` |
| `technical` | Internal debt, refactoring, or maintenance | `D4C5F9` |

### Workflow Status
Labels that indicate workflow state or blockers. Apply **as needed** to show current status:

| Label | Description | Color |
|-------|-------------|-------|
| `dependency` | Has a dependency on one or more other issues | `CFD3D7` |
| `feedback required` | Blocked waiting for clarification or user feedback | `F9D0C4` |
| `waiting for details` | Incomplete issue; waiting for reporter to provide info | `EDEDED` |

### Governance
Labels for project management and prioritisation. Apply **as needed** for special handling:

| Label | Description | Color |
|-------|-------------|-------|
| `out-of-scope` | Intentionally deferred beyond current release | `E99695` |
| `priority-high` | High-priority work (omit medium/low to reduce noise) | `B60205` |
| `not-started` | Epic that hasn't started active work yet | `FBCA04` |

## Label Usage Matrix

This matrix shows when to apply each label based on issue type. ✅ = commonly used, 🔶 = occasionally used, — = not typically used.

| Label Category | Label | Epic | Story | Bug | Spike |
|----------------|-------|------|-------|-----|-------|
| **Issue Type** | `epic` | ✅ | — | — | — |
| | `story` | — | ✅ | — | — |
| | `bug` | — | — | ✅ | — |
| | `spike` | — | — | — | ✅ |
| **Change Type** | `improvement` | — | 🔶 | — | — |
| | `feature` | 🔶 | ✅ | — | — |
| | `technical` | — | 🔶 | — | — |
| **Workflow Status** | `dependency` | 🔶 | ✅ | ✅ | 🔶 |
| | `feedback required` | 🔶 | ✅ | ✅ | ✅ |
| | `waiting for details` | — | ✅ | ✅ | — |
| **Governance** | `out-of-scope` | ✅ | ✅ | 🔶 | 🔶 |
| | `priority-high` | 🔶 | ✅ | ✅ | 🔶 |
| | `not-started` | ✅ | — | — | — |

## Label Creation Commands

Use these GitHub CLI commands to create all standard labels with consistent colors:

```bash
# Issue Type Labels
gh label create "epic" --color "3E4B9E" --description "Epic issue; parent of child tasks" --force
gh label create "story" --color "0E8A16" --description "User story; typically child of epic" --force
gh label create "bug" --color "D73A4A" --description "Bug fix" --force
gh label create "spike" --color "8B72C8" --description "Research or investigation task (time-boxed)" --force

# Change Type Labels
gh label create "improvement" --color "A2EEEF" --description "Feature enhancement or new capability" --force
gh label create "feature" --color "FBCA04" --description "Feature request from users or stakeholders" --force
gh label create "technical" --color "D4C5F9" --description "Internal debt, refactoring, or maintenance" --force

# Workflow Status Labels
gh label create "dependency" --color "CFD3D7" --description "Has a dependency on one or more other issues" --force
gh label create "feedback required" --color "F9D0C4" --description "Blocked waiting for clarification or user feedback" --force
gh label create "waiting for details" --color "EDEDED" --description "Incomplete issue; waiting for reporter to provide info" --force

# Governance Labels
gh label create "out-of-scope" --color "E99695" --description "Intentionally deferred beyond current release" --force
gh label create "priority-high" --color "B60205" --description "High-priority work (omit medium/low to reduce noise)" --force
gh label create "not-started" --color "FBCA04" --description "Epic that hasn't started active work yet" --force
```

## Usage Guidelines

### Issue Type Labels (Required)
- **Every issue** must have exactly one: `epic`, `story`, `bug`, or `spike`
- Choose based on the fundamental nature of the work
- Do not combine multiple issue type labels

### Change Type Labels (Optional)
- Apply zero or one based on what aspect of the codebase is changing
- `improvement`: Enhancing existing functionality
- `feature`: Adding new user-facing capability
- `technical`: Internal work with no direct user impact
- Epics typically don't need change type labels
- Stories and tasks benefit from change type classification

### Workflow Status Labels (As Needed)
- Apply these to indicate blockers or special workflow needs
- `dependency`: Issue cannot proceed until another issue completes
- `feedback required`: Active work blocked waiting for input
- `waiting for details`: Issue description incomplete
- Remove these labels once the blocker is resolved

### Governance Labels (As Needed)
- `out-of-scope`: Explicitly marks work deferred to future releases
- `priority-high`: Use sparingly; only for genuinely critical work
- `not-started`: Only on epics to show they haven't begun active development
- Keep these labels selective to maintain their signal value
