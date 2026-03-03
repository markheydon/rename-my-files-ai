---
description: Refresh the implementation plan for Rename My Files.
agent: MAT Orchestrator
argument-hint: "scope change or new behaviour"
model: Auto (copilot)
---

Use  `plan/SCOPE.md` and current code to update `plan/IMPLEMENTATION_PLAN.md`. Reference `.github/skills/plan-management/` for format consistency. Keep tasks small and testable. Note any assumptions.

For GitHub Issue management conventions, follow `.github/skills/github-issue-management/SKILL.md` and `.github/instructions/github-issue-management.instructions.md`.

## GitHub Epic/Story Management

### Creating Epics and Issues

**NOTE**: Only epics and stories should be created. Do not create bug or spike issues at this stage. And do not
create tasks such as "Documentation update" or "Testing" as these are not actionable work items. Focus on creating epics and stories that represent meaningful, testable work aligned with the implementation plan.

1. **Search first:** Check if issue already exists before creating new one.

2. **Create epic issues** for each major phase or work stream in IMPLEMENTATION_PLAN.md.
   - Title format: `[Descriptive Title]` (clean, no phase prefix)
   - Label: `epic`
   - Label: `not-started` (new epics; remove once work begins)
   - Assign to **Milestone:** corresponding phase (see `.github/instructions/github-issue-management.instructions.md` for milestone names)
   - Include objective, rationale, and links to IMPLEMENTATION_PLAN.md in description

3. **Create story issues** for breakdown tasks from epics.
   - Title format: Clean, no prefixes
   - Label (Issue Type): `story`, `bug`, or `spike` (pick one)
   - Label (Change Type): `improvement`, `feature`, or `technical` (pick zero or one)
   - Label (Workflow Status): `dependency`, `feedback required`, `waiting for details` (as needed)
   - Label (Governance): `out-of-scope` (if intentionally deferred), `priority-high` (if high priority)
   - Assign to **Milestone:** corresponding phase (see instructions file)
   - Link to parent epic using GitHub's **parent issue feature** (manual step; see note below)
   - Include acceptance criteria and task checklist in description

4. **Assign to Mark's Personal Project Board** if in an active milestone and not labeled `out-of-scope` (see instructions file for project board rules).

### Parent/Child Linking

- **Note:** GitHub CLI does not support automated parent/child linking
- After creating epic and task issues, parent linking must be done **manually** through GitHub web UI.
- In child issue UI, click "Link issue" → "Add parent" → enter parent epic number.
- This creates a native GitHub parent/child relationship (better than text-only linking).
- Child issues show in parent epic's "Child issues" section for clean hierarchy.

### Labels and Status

Refer to `.github/skills/github-issue-management/SKILL.md` for complete usage guidelines:
- **Issue Type** (epic, story, bug, spike): exactly one per issue.
- **Change Type** (improvement, feature, technical): zero or one per issue.
- **Workflow Status** (dependency, feedback required, waiting for details): as needed.
- **Governance** (out-of-scope, priority-high, not-started): as needed.
- **Milestone**: one per issue, matching phase/release name.

### Label Cleanup Policy

**Remove any labels that are NOT in the official label list.** This ensures consistency across the repository.

Official labels only:
- Issue Type: `epic`, `story`, `bug`, `spike`.
- Change Type: `improvement`, `feature`, `technical`.
- Workflow Status: `dependency`, `feedback required`, `waiting for details`.
- Governance: `out-of-scope`, `priority-high`, `not-started`.

Remove legacy or non-standard labels such as:
- Phase-specific labels: `phase-6`, `phase-6a`, `phase-6b`, etc.
- Priority variants: `priority-medium`, `priority-low`.
- Domain-specific labels not in the official list: `image-processing`, `office-documents`, `validation`, `release`.
- Any other custom labels not listed above.

Use milestones for phase organisation instead of phase labels.

### Project Management Sweep

Periodically review all open issues for label consistency and relevance. Remove any non-standard labels immediately to maintain a clean and consistent issue tracking system. Also, ensure all issues are assigned to the correct milestone and linked to their parent epic if applicable. Finally, check for any issues that may have been missed in the project board assignment and add them if they meet the criteria.

Updates required that the agent cannot perform automatically due to technical limitation, should be reported to the user for manual action. For example, if an issue is created without a parent link, the agent should log a message indicating that the parent link needs to be added manually in the GitHub UI. Note this only applies to known technical limitations; any other updates that are within the agent's capabilities should be performed automatically without user intervention as specified in the instructions.

### Repository-Specific Configuration

See `.github/instructions/github-issue-management.instructions.md` for:
- Milestone names and descriptions.
- Epic-to-task mapping.
- Issue description templates.
- Link patterns and references.