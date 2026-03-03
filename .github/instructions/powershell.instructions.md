---
name: PowerShell Implementation Instructions
description: PowerShell implementation rules for Rename My Files.
applyTo: "**/*.ps1,**/*.psm1"
---

# PowerShell Rules

## Scope

- Changes must only support the file-renaming workflow.
- Do not modify file contents; only read and rename.

## Script Standards

- Use approved PowerShell verbs in function and script names.
- Use `[CmdletBinding()]` for advanced functions.
- Include comment-based help on scripts and public functions.
- Use parameter validation attributes (e.g., `[ValidateNotNullOrEmpty()]`).
- Handle errors per-file so one failure does not stop the batch.
- Keep Azure AI calls in dedicated functions for testability.

## Security

- Never hardcode secrets; use environment variables or parameters.
- Send only minimum necessary content to Azure AI.
- Do not add new external services unless required for file reading or Azure AI.
