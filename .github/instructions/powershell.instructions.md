---
name: PowerShell Implementation Instructions
description: PowerShell implementation rules for Rename My Files.
applyTo: "**/*.ps1,**/*.psm1"
---

# PowerShell Implementation

## Purpose

Use these instructions when implementing or updating PowerShell code that supports this repository's single purpose:

> Read file contents and automatically rename files to descriptive names using AI.

## In Scope

- Reading supported file contents (for filename inference).
- Calling Azure AI helper functions to generate candidate filenames.
- Renaming files while preserving original extensions.
- Logging/reporting outcomes: renamed, skipped, failed.
- Handling per-file failures without stopping the batch.

## Out of Scope

- Modifying file contents.
- Unrelated processing, data transformation, or workflow orchestration.
- New dependencies not required for file reading or Azure AI calls.
- Any third-party data flow beyond required Azure AI interaction.

## Implementation Requirements

- Use approved PowerShell verbs for functions and script names.
- Use `[CmdletBinding()]` on advanced functions.
- Add comment-based help to scripts and public functions.
- Use parameter validation attributes (for example, `[ValidateNotNullOrEmpty()]`).
- Keep Azure AI interaction in dedicated function(s) for testability.
- Send only minimum necessary file content to Azure AI.
- Never hardcode secrets; use environment variables or secure parameter passing.
- Handle errors per-file so one failure does not stop the batch.

## Validation Checklist

Run before committing:

```powershell
Invoke-ScriptAnalyzer -Path .\scripts -Settings .\PSScriptAnalyzerSettings.psd1 -Recurse
```

If relevant to the change:

- Run a dry-run/safe validation against a small sample folder.
- Confirm extension preservation and accurate logging for renamed/skipped/failed files.
- Ensure per-file error handling prevents batch failures.

## Definition of Done

- Change directly supports AI-based file renaming.
- No file content is modified.
- Per-file error handling is present.
- PowerShell linting passes with no errors.
- Documentation reflects current behaviour only.
