---
description: Bootstrap a new repo with Copilot instructions, a minimal agent team, prompts, and baseline docs from a rough app idea.
agent: Repo Bootstrapper
argument-hint: "Describe the app idea + target stack + UI type (e.g., '.NET 10, Blazor Server') + MVP must-haves"
---

Using the user’s idea, initialise the repository for AI-assisted development.

Create/update:
- `.github/copilot-instructions.md`
- `.github/instructions/*.instructions.md`
- `.github/agents/*` (minimal team)
- `.github/prompts/*` (plan/next-task/implement/review/docs)
- `.github/skills/github-issue-management/SKILL.md` (GitHub Issue Management integration)
- `plan/SCOPE.md`
- `plan/IMPLEMENTATION_PLAN.md`
- `plan/RUNBOOK.md`
- `plan/DECISIONS/ADR-0001-architecture.md`
- `docs/` (user-facing documentation only: README, guides, etc.)

GitHub Integration:
- Agents and prompts must:
	- Search for existing GitHub Issues before starting work.
	- Create Issues for new tasks, epics, or user stories.
	- Update Issues with status, comments, and PR links.
	- Close Issues when tasks are completed.
	- Use labels (`epic`, `user-story`) and issue linking for hierarchy.

Rules:
- Keep it minimal (start with 4 agents unless strongly justified).
- Include build/test commands as gates.
- Write docs that match reality and label assumptions clearly.
- Default to .NET unless the user specifies otherwise.