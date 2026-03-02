# Runbook

## Purpose

Explain how to run, validate, and maintain the Rename My Files scripts.

## Prerequisites

- PowerShell 7.2 or later
- Azure subscription with rights to create resources
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) (includes built-in Bicep support)

## ⚠️ Data Residency Notice

This tool processes file contents using Azure OpenAI with **GlobalStandard deployment**, which means file data may be processed in any Azure region where the model is available — not restricted to your specified region.

**For strict data residency requirements** (EU/US only, single-region processing), see [ADR-0003](DECISIONS/ADR-0003-globalstandard-deployment-type.md) for alternative deployment options (DataZoneStandard or Regional Standard).

## Repository Layout

This repository is organised as follows:

- `scripts/` — operational PowerShell scripts (`Rename-MyFiles.ps1`, deploy, and remove)
- `infra/` — Azure infrastructure as code (`main.bicep`)
- `docs/` — end-user documentation only
- `plan/` — internal technical planning, runbook, and architecture decisions (ADRs)

## Setup

1. Deploy Azure resources (one-time):

   ```powershell
   .\scripts\Deploy-RenameMyFiles.ps1 -SubscriptionId "<your-subscription-id>"
   ```

2. Set environment variables for Azure OpenAI:

   ```powershell
   $env:AZURE_OPENAI_ENDPOINT = "https://your-resource.openai.azure.com/"
   $env:AZURE_OPENAI_KEY = "your-api-key-here"
   ```

## Run (Dry-Run)

```powershell
.\scripts\Rename-MyFiles.ps1 -FolderPath "C:\Documents\MyUnfiledFolder" -WhatIf
```

## Run (Rename)

```powershell
.\scripts\Rename-MyFiles.ps1 -FolderPath "C:\Documents\MyUnfiledFolder"
```

## Remove Azure Resources

```powershell
.\scripts\Remove-RenameMyFilesResources.ps1 -SubscriptionId "<your-subscription-id>"
```

## Troubleshooting

### Soft-Deleted Azure OpenAI Resource

**Problem:** Deployment fails with error `FlagMustBeSetForRestore` — a previously deleted Azure OpenAI resource is soft-deleted and blocking redeployment.

**Default Behaviour:** Deployment now runs in two steps automatically:
1. Tries normal deployment with `restoreOpenAI=false` (works for active resources and normal redeploys).
2. If Azure returns `FlagMustBeSetForRestore`, retries with `restoreOpenAI=true` to restore the soft-deleted resource.

This avoids `CanNotRestoreAnActiveResource` on active resources while still handling soft-deleted resources without manual intervention.

**Manual Purge (Edge Cases):** If you need to completely purge the soft-deleted resource (e.g., changing location or starting fresh), run:

```powershell
# List soft-deleted Cognitive Services accounts
az cognitiveservices account list-deleted `
  --query "[?name=='rmf-openai-<your-suffix>']" `
  --output table

# Purge the soft-deleted account (replace with your values)
az cognitiveservices account purge `
  --name "rmf-openai-<your-suffix>" `
  --resource-group "rg-rename-my-files" `
  --location "uksouth"

# Wait ~30 seconds, then retry deployment
.\scripts\Deploy-RenameMyFiles.ps1 -SubscriptionId "<your-subscription-id>"
```

**Note:** Soft-delete retention is typically 48 hours. After this period, the name becomes available without purging.

## Validation Gates

- Tests: none yet. If tests are added, run them by default.
- Manual check: run a dry-run on a small folder and confirm the summary.
