# Copilot Instructions for Rename My Files

## Single Purpose — Non-Negotiable

The **only** purpose of this repository is:

> To read file contents in a folder and automatically rename those files in a helpful, descriptive way using AI.

No other features or functionalities should be introduced unless they **directly** support this core purpose. If you are unsure whether a change is in scope, it is not.

---

## Allowed Actions

Code in this repository may:

- Read file contents (text, PDF, and other supported formats).
- Call Azure AI services to generate better, descriptive filenames.
- Rename files on disk, preserving the original file extension.
- Log and report what was renamed, skipped, or failed.

Code in this repository must **not**:

- Modify the content of any file.
- Perform unrelated data processing or transformations.
- Implement features that are not directly tied to the file-renaming workflow.
- Introduce new dependencies or integrations unless they are necessary for reading files or calling Azure AI.

---

## Documentation Constraints

Documentation should:

- Describe what the code **currently does**, not speculative or planned future features.
- Be kept aligned with the actual codebase at all times.
- Only include planning notes or implementation notes where they are clearly marked (e.g. a `# TODO:` comment) and tightly scoped.
- **Use UK English spelling and terminology** (e.g. "organise", "behaviour", "colour", "optimise").

Documentation must **not**:

- Over-promise capabilities that are not yet implemented.
- Add generic boilerplate that is not directly relevant to the current implementation.
- Describe features outside the single purpose stated above.
- Use US English spelling (e.g. "organize", "behavior", "color", "optimize").

---

## Code Quality Rules

- Use **approved PowerShell verbs** for all functions and script names (e.g. `Get-`, `Set-`, `Invoke-`, `Remove-`, `Deploy-`).
- Use `[CmdletBinding()]` on advanced functions.
- Include comment-based help (`<# .SYNOPSIS ... #>`) on all scripts and public functions.
- Use parameter validation attributes (`[ValidateNotNullOrEmpty()]`, `[ValidateScript()]`, etc.).
- Handle errors gracefully — a single bad file must never stop the entire batch.
- Keep Azure AI interaction separated into its own function(s) for testability.
- **Pass PSScriptAnalyzer with no errors** — run `Invoke-ScriptAnalyzer -Path .\scripts -Settings .\PSScriptAnalyzerSettings.psd1 -Recurse` before committing.

---

## Security & Privacy

- Only the **minimum necessary** file content should be sent to Azure AI to generate a filename.
- Do **not** introduce additional data flows that send file content or metadata to third parties.
- Do **not** hardcode API keys, secrets, or subscription IDs in source code. Use environment variables or secure parameter passing.
- Respect Azure OpenAI's data-handling policies; do not store or cache file content unnecessarily.
- Future Copilot suggestions must respect this constrained, privacy-conscious design.

---

## Summary Checklist for Copilot

Before suggesting or generating any code, ask yourself:

1. Does this change directly support renaming files based on their content using AI? If not, do not suggest it.
2. Does this change modify file content? If yes, do not suggest it.
3. Does this change introduce a new external service or dependency? If yes, is it strictly necessary for reading files or calling Azure AI?
4. Is the documentation accurate and scoped to what the code currently does?
5. Are secrets and keys handled safely (environment variables, not hardcoded)?

---

## Workflow and Quality Gates

- Keep changes small and scoped to the rename workflow.
- Prefer updating docs alongside code changes.
- Validation gates:
	- Tests: none yet (do not invent). If tests are added later, run them by default.
	- PowerShell linting: PSScriptAnalyzer runs on all PRs to `main` (errors fail the build, warnings inform).
	- Bicep validation: `az bicep build` runs on all PRs to `main` (syntax errors fail the build).
