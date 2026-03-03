---
name: Bicep Implementation Instructions
description: Bicep implementation rules for Rename My Files.
applyTo: "**/*.bicep"
---

# Bicep Implementation

## Purpose

Use these instructions when implementing or updating Azure Bicep templates for infrastructure that directly supports AI-based filename generation in this repository.

## In Scope

- Bicep for Azure resources required by the rename workflow's AI integration.
- Parameters and outputs needed by PowerShell automation to call Azure AI.
- Secure configuration patterns that avoid hardcoded secrets.

## Out of Scope

- General platform infrastructure unrelated to file renaming.
- Broad CI/CD architecture changes not required for this workflow.
- Non-essential Azure services that do not directly support AI filename generation.

## Implementation Requirements

- Follow current Azure Bicep best practices.
- Keep templates focused and minimal for the rename workflow.
- Do not hardcode API keys, secrets, or subscription IDs.
- Use secure parameterisation and environment-based configuration where applicable.
- Keep documentation aligned with what templates currently deploy.

## Validation Checklist

Run before committing:

```bash
az bicep build --file infra/main.bicep
```

If multiple entry files exist, build each relevant entry file changed by the PR.

## Definition of Done

- Bicep changes directly support AI-based file renaming.
- Templates compile successfully (`az bicep build` exits with no errors).
- No secrets are hardcoded.
- Documentation accurately reflects deployed resources and current behaviour.
