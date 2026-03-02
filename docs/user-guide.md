# User Guide

This guide walks you through everything you need to use **Rename My Files** — a tool that automatically renames files with clear, descriptive names using AI.

---

## Prerequisites

Before you begin, you will need:

1. **PowerShell 7.2 or later** installed on your computer.
   - [Download PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell)
2. **An Azure account** (free to create at [azure.microsoft.com](https://azure.microsoft.com/free/)).
3. **Azure CLI** installed:
   - [Install Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
   - Bicep support is built-in (no separate installation needed)

---

## ⚠️ Important: Data Residency and Processing Locations

**Before you deploy, understand where your file data is processed:**

This tool uses Azure OpenAI with **GlobalStandard** deployment type, which means:

| Aspect | What Happens |
|--------|-------------|
| **File content at rest** | Stays in your Azure region (e.g., UK South) |
| **File content during AI processing** | **May be sent to any Azure region** where the model is available |
| **Processing duration** | Only milliseconds (during the API call) |
| **Data storage** | Not stored after processing completes |
| **Third parties** | Not shared; remains within Azure infrastructure |

### Is This Right for You?

✅ **Use Rename My Files if:**
- You're comfortable with your data being processed across Azure's global infrastructure
- Your organisation has no strict geographic data residency requirements
- You value cost efficiency and broad region availability

⚠️ **Talk to your IT or compliance team if:**
- Your organisation requires all data processing to stay within EU member nations
- Your organisation requires all data processing to stay within the United States
- Your organisation requires data processing in a single specific region
- You handle sensitive data with geographic compliance requirements

If you need strict geographic processing requirements, speak with your Azure administrator before using this tool.

---

## Step 1 — Deploy Azure Resources

You only need to do this **once**. It creates the Azure AI service that powers the renaming.

### Supported Regions

This tool works in most Azure regions. uksouth is fully supported. For a complete list of supported regions, see the [Azure OpenAI model availability documentation](https://learn.microsoft.com/en-us/azure/ai-foundry/foundry-models/concepts/models-sold-directly-by-azure?view=foundry-classic&tabs=global-standard-aoai%2Cglobal-standard&pivots=azure-openai#global-standard-model-availability).

### Deployment Steps

1. Open a PowerShell 7 terminal.
2. Navigate to the folder where you downloaded the Rename My Files scripts.
3. Run:

   ```powershell
   .\scripts\Deploy-RenameMyFiles.ps1 -SubscriptionId "<your-azure-subscription-id>"
   ```

   Replace `<your-azure-subscription-id>` with your Azure subscription ID.  
   (You can find this in the [Azure Portal](https://portal.azure.com) under **Subscriptions**.)

4. When prompted, sign in to your Azure account.
5. Wait for the deployment to finish (usually 2–5 minutes).
6. At the end, the script will print instructions to retrieve your **API key** and **endpoint URL**.
   Follow those instructions and note down the values.

> **Tip:** If your organisation manages Azure, ask your IT administrator to run the deployment script on your behalf and provide you with the endpoint and API key.

---

## Step 2 — Configure Your API Key and Endpoint

Set these as environment variables so the rename script can use them:

```powershell
$env:AZURE_OPENAI_ENDPOINT = "https://your-resource.openai.azure.com/"
$env:AZURE_OPENAI_KEY      = "your-api-key-here"
```

> **Security note:** Do not share your API key or store it in a plain text file. Set it as an environment variable each session, or use a secure secrets manager.

---

## Step 3 — Preview Before Renaming (Recommended)

Before renaming any real files, do a **dry run** to see what the tool would do:

```powershell
.\scripts\Rename-MyFiles.ps1 -FolderPath "C:\Documents\MyUnfiledFolder" -WhatIf
```

This will show you proposed renames **without actually changing anything**. Review the output and make sure it looks sensible.

> **Safety tip:** Always test on a **small sample folder** first (e.g. copy 5–10 files to a test folder). Once you are confident, run on your full folder.

---

## Existing-name handling

The tool sends the current filename and document content to Azure AI. If the current filename is already clear and useful, Azure AI can return it unchanged.

### Example Skip Reasons

| File | Reason | Called AI? |
|------|--------|-----------|
| `Invoice - 2025-02-15.pdf` | Filename unchanged | ✅ Yes |
| `scan0042.pdf` | Renamed | ✅ Yes |
| `Document (3).docx` | Renamed | ✅ Yes |

### Force Rename Everything

If you want Azure AI to always suggest a new name, use `-Force`:

```powershell
.\scripts\Rename-MyFiles.ps1 -FolderPath "C:\Documents\MyUnfiledFolder" -Force
```

This tells the tool to ask Azure AI for an improved name even when the current filename already looks good. Useful if you want stricter naming consistency across your collection.

---

## Step 4 — Rename Your Files

Once you are happy with the preview:

```powershell
.\scripts\Rename-MyFiles.ps1 -FolderPath "C:\Documents\MyUnfiledFolder"
```

The script will:
- Read each supported file.
- Ask Azure AI to suggest a descriptive name.
- Rename the file, keeping the same extension.
- Show a summary at the end.

Example output:

```
Scanning folder: C:\Documents\MyUnfiledFolder
Found 8 file(s). Processing...

   SKIPPED  Invoice - 2025-02-15.pdf -- filename unchanged
   RENAMED  scan0042.pdf  ->  Acme Ltd Invoice - January 2025.pdf
   RENAMED  Document (3).docx  ->  HMRC Self Assessment Tax Return 2024-25.docx
   SKIPPED  photo.jpg -- Unsupported or unreadable file type
   RENAMED  letter.txt  ->  Dr Smith Referral Letter - John Doe.txt

-------------------------------------
 Summary
-------------------------------------
 Files scanned    : 8
 Files renamed    : 3
 Files skipped    : 5

 Skip breakdown:
   - Filename unchanged   : 1
-------------------------------------
```

---

## Limitations and Caveats

| Situation | What happens |
|-----------|-------------|
| Image files (`.jpg`, `.png`, etc.) | Skipped — the tool only reads text content |
| PDF files with text content (PdfPig installed) | Supported — text is extracted and used for naming |
| PDF files (PdfPig not installed) | Skipped with a message explaining how to install PdfPig |
| Scanned PDF files (image-based) | Skipped — no text to extract |
| Password-protected or encrypted PDF files | Skipped — decryption not supported |
| Office documents (`.docx`, `.xlsx`, `.pptx`, etc.) | Limited — the tool currently uses filename context only, so names may be generic |
| Corrupted or unreadable plain-text files | Skipped — the file cannot be read |
| Very short or empty files | The AI may produce a generic or imperfect name |
| File with the same proposed name already exists | A numeric suffix is added (e.g. `-1`, `-2`) |
| Proposed filename exceeds Windows limit (255 chars) | Name is truncated to fit the limit |
| Proposed filename contains control characters, tabs, or newlines | These characters are removed entirely |
| Proposed filename matches a Windows reserved device name (e.g. CON, PRN, NUL, COM1) | Name is made safe by appending _file |
| Excess spaces | Multiple spaces are collapsed to a single space |
| Azure API rate limit exceeded | File is skipped. Script retries automatically and already uses low-cost defaults (conservative pacing + reduced prompt size). If this still happens, wait a few minutes and try again, or increase Azure OpenAI quota. |

- **AI names are suggestions.** The AI does its best but may occasionally produce imperfect names. Review the dry-run output before renaming important files.
- **Only the filename changes.** The tool never modifies the content of any file.
- **Only files in the top-level folder are processed.** Sub-folders are not scanned.
- **The summary reports renamed and skipped files.** Any file-level failure is recorded as skipped with a reason.

### Enabling PDF text extraction

PDF text extraction requires the PdfPig library. To enable it:

1. Open a PowerShell 7 terminal.
2. Navigate to the folder where you have the Rename My Files scripts.
3. Run the installation script:
   ```powershell
   .\scripts\Install-Dependencies.ps1
   ```
4. The script will download PdfPig from NuGet.org and install it automatically.
5. Run the rename script:
   ```powershell
   .\scripts\Rename-MyFiles.ps1 -FolderPath "C:\Documents\MyFolder"
   ```

**What happens if PdfPig is not installed?**
- PDF files are skipped with a clear `⚠️ WARNING` message at the start of the script.
- The message tells you exactly how to install it (run `Install-Dependencies.ps1`).
- Once you install PdfPig, run the rename script again — no configuration needed.

**Verify PdfPig is loaded:** Run the rename script with `-Verbose`:
```powershell
.\scripts\Rename-MyFiles.ps1 -FolderPath "C:\Documents\MyFolder" -Verbose
```
Look for: `"Successfully loaded PdfPig from: ..."` in the output.

**Requirements:** PowerShell 7.2+ and an internet connection. No .NET SDK required.

---

## Cost

> ⚠️ **Estimates only** — actual costs depend on file size and current Azure pricing. For the latest rates, see [Azure OpenAI Pricing](https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/).

**Deployment uses GlobalStandard pricing:**
- **Input:** $0.15 per 1M tokens
- **Output:** $0.60 per 1M tokens
- **Idle cost:** $0.00 (pay-as-you-go, no standing charges)

| Usage | Estimated Cost |
|-------|----------------|
| Per typical document (500–1,000 words) | **~$0.0001** (~0.01¢) |
| 10 documents | **~$0.001** |
| 100 documents | **~$0.015** |
| 1,000 documents | **~$0.15** |
| 10,000 documents | **~$1.50** |

**Key points:**
- You are only charged when you run the rename script — there is no cost when idle.
- Larger documents consume more tokens and cost slightly more.
- These estimates assume typical business documents (letters, invoices, reports).

---

## Removing Azure Resources

If you no longer need the tool and want to stop any future costs:

```powershell
.\scripts\Remove-RenameMyFilesResources.ps1 -SubscriptionId "<your-azure-subscription-id>"
```

This permanently deletes the Azure resource group and everything in it. You will be asked to confirm before anything is deleted.

---

## Getting Help

- Open a [GitHub Issue](https://github.com/markheydon/rename-my-files/issues) if you encounter a bug.
- For Azure-related problems, check the [Azure OpenAI documentation](https://learn.microsoft.com/azure/ai-services/openai/).
