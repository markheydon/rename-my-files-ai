# Implementation Plan

This plan breaks work into small, testable tasks. Update it when the code changes.

## Current State Snapshot

**MVP Status:** ✅ **Complete** — All phases 0–5 are finished. Core features are functional and documented. Phase 6 in progress: PDF extraction and intelligent skip logic complete; image and office document extraction pending.

### What Works Now

- Scripts run locally with PowerShell 7; cross-platform ready (Windows, macOS, Linux).
- `Rename-MyFiles.ps1`
  - Reads plain-text files (`.txt`, `.md`, `.csv`, `.log`, `.json`, `.xml`, `.html`, `.yaml`, etc.)
  - Extracts text from PDF files using PdfPig (requires optional `Install-Dependencies.ps1`).
  - Smart skip: Files with descriptive names (date + business keyword) are skipped to save cost.
  - Uses Azure OpenAI REST API directly for filename proposals.
  - Implements dry-run via `ShouldProcess` with `-WhatIf` support.
  - Handles per-file errors without stopping the batch.
  - Sanitises filenames (removes invalid chars, control chars, collapses spaces, handles collisions).
  - Truncates filenames to Windows limits (255 chars).
  - Makes Windows reserved names safe (e.g., `CON` → `CON_file`).
  - Limits content sent to Azure AI to 8000 characters.
  - Prints summary of renamed/skipped/failed counts with skip breakdowns.
  - `-Force` flag allows overriding smart skip logic for descriptive filenames.
- `Deploy-RenameMyFiles.ps1`
  - Uses Azure CLI (`az`) with built-in Bicep support (no separate installation).
  - Creates resource group, Azure OpenAI resource, and GPT-4o mini deployment.
  - Automates soft-deleted resource restoration via `restore: true` property.
- `Remove-RenameMyFilesResources.ps1`
  - Uses Azure CLI (`az`) for safe resource group deletion.
  - Prompts for confirmation; supports `–Force` flag.
- All documentation (README, user guide, runbook) updated to reflect current behaviour and limitations.
- Architecture decisions documented in `DECISIONS/` (ADR-0001 through ADR-0006).

### Known Limitations (Current Implementation)

- **Plain-text files (MVP):** Fully supported (text extraction works).
- **PDF files (Phase 6a):** ✅ Text content is extracted using PdfPig (optional dependency). Requires `Install-Dependencies.ps1`. Scanned/encrypted PDFs are skipped.
- **Image files (JPEG, PNG) (Phase 6b):** ⏳ Not yet supported. Being added in Phase 6b based on user priority. Scanned documents and photos are a primary use case.
- **Office documents (Phase 6c):** Currently use filename context only (no content extraction). Real extraction coming in Phase 6c.
- **Other file types (GIF, BMP, TIFF, SVG, etc.):** Skipped automatically.
- **Subfolder recursion:** Not supported; only top-level files processed. Could be added as `-Recurse` flag in future.
- **AI-generated names are suggestions:** May not always be perfect; always preview with `-WhatIf` first.
- **Smart skip limitation:** Files with dates but no business keywords are not skipped, even if the name is reasonable. Use `-Force` to skip the smart-skip check.

## Phase 0 - Cross-Platform Azure Tooling Migration

**Status:** ✅ **Complete**

**Objective:** Replace Azure PowerShell module with Azure CLI for cross-platform compatibility.

**Solution:** Migrated deployment scripts to use Azure CLI (`az`), which has built-in Bicep support and works identically on Windows, macOS, and Linux.

### Completed Tasks:
- [x] Update `Deploy-RenameMyFiles.ps1` to use `az` CLI commands instead of Az module cmdlets.
  - [x] Replace `Connect-AzAccount` → `az login --use-device-code`
  - [x] Replace `Set-AzContext` → `az account set --subscription`
  - [x] Replace `Get-AzResourceGroup` → `az group show --name` (with error handling)
  - [x] Replace `New-AzResourceGroup` → `az group create --name --location`
  - [x] Replace `New-AzResourceGroupDeployment` → `az deployment group create --resource-group --template-file`
  - [x] Parse JSON output from `az` commands using `ConvertFrom-Json`
  - [x] Update instructions to reference API key retrieval via `az cognitiveservices account keys list`
  - [x] Added Azure CLI prerequisite check (`Get-Command az`)
  - [x] Tested on Windows with dry-run and full deployment
  - Validation: Script successfully creates resource group and deploys Bicep template via Azure CLI
- [x] Update `Remove-RenameMyFilesResources.ps1` to use `az` CLI commands.
  - [x] Replace Azure authentication and context cmdlets with `az` equivalents
  - [x] Replace `Get-AzResourceGroup` → `az group show --name`
  - [x] Replace `Get-AzResource` → `az resource list --resource-group`
  - [x] Replace `Remove-AzResourceGroup` → `az group delete --name`
  - [x] Syntax validated successfully
  - [x] Updated script `.NOTES` to reference Azure CLI instead of Az module
  - Validation: Script ready for functional testing in live Azure environment
- [x] Add `restore: true` to Bicep template to handle soft-deleted Azure OpenAI resources.
  - [x] Added property to Azure OpenAI resource in `infra/main.bicep`
  - [x] Bicep template validated (build + lint successful)
  - [x] Created ADR-0004 documenting the decision
  - [x] Added troubleshooting section to RUNBOOK.md with manual purge steps for edge cases
  - Validation: Deployment automatically restores soft-deleted resources without errors
- [x] Update documentation to reflect new prerequisites and behaviour.
  - [x] Removed Az PowerShell module requirement from all scripts
  - [x] Added Azure CLI installation requirement
  - [x] Removed separate Bicep installation requirement (built into az CLI)
  - [x] Updated README.md, user-guide.md, and RUNBOOK.md
  - [x] Created ADR-0002: Use Azure CLI Instead of Azure PowerShell Module
  - [x] Created ADR-0003: Use GlobalStandard Deployment Type for Azure OpenAI
  - [x] Created ADR-0004: Use Restore Flag for Soft-Deleted Azure OpenAI Resources

## Phase 1 - Baseline Verification

**Status:** ✅ **Complete**

**Objective:** Ensure core script structure meets MVP requirements.

### Completed Tasks

- [x] Verify the README and docs refer to `scripts/` paths.
- [x] Confirm `Rename-MyFiles.ps1` uses `ShouldProcess` for dry-run.
- [x] Confirm Azure OpenAI calls are isolated in a dedicated function (`Invoke-AzureOpenAIFilenameProposal`).

## Phase 2 - File Intake and Safety

**Status:** ✅ **Complete**

**Objective:** Ensure robust input handling and error resilience.

### Completed Tasks

- [x] Validate folder path input with `[ValidateScript()]` attribute.
- [x] Handle missing or empty folders gracefully (output message, exit cleanly).
- [x] Confirm only top-level files are processed via `Get-ChildItem -File` (no recursion).
- [x] Ensure per-file error handling does not stop the batch (catch and log, continue loop).

## Phase 3 - Content Extraction

**Status:** ✅ **Complete**

**Objective:** Implement MVP content extraction with size limits and placeholder support.

### Completed Tasks

- [x] Support plain-text file extraction (`.txt`, `.md`, `.csv`, `.log`, `.json`, `.xml`, `.html`, `.yaml`).
- [x] Add 8000-character limit (approx. 2000 tokens) before sending to Azure OpenAI.
- [x] Implement placeholder extraction for PDF files (returns `[PDF file: <filename>]`).
  - Code location: [scripts/Rename-MyFiles.ps1](scripts/Rename-MyFiles.ps1#L93-L101) lines 93–101.
  - Rationale: Real PDF text extraction deferred to Phase 6 (post-MVP).
- [x] Implement placeholder extraction for Office documents (returns `[Office document: <filename>]`).
  - Code location: [scripts/Rename-MyFiles.ps1](scripts/Rename-MyFiles.ps1#L104-L107) lines 104–107.
  - Rationale: Real Office text extraction deferred to Phase 6 (post-MVP).

**Note:** Placeholder extraction allows all file types to get best-effort renames based on filename context. Real PDF/Office extraction is a post-MVP enhancement; see Phase 6.

## Phase 4 - AI Naming and Sanitisation

**Status:** ✅ **Complete**

**Objective:** Ensure proposed filenames are safe, valid, and non-colliding.

### Completed Tasks

- [x] Azure OpenAI prompt designed to produce valid Windows filenames (no `\\ / : * ? \" < > |` chars).
  - Code location: [scripts/Rename-MyFiles.ps1](scripts/Rename-MyFiles.ps1#L129-L150) lines 129–150.
- [x] Remove invalid Windows characters (`\\ / : * ? \" < > |`) from AI-proposed names.
- [x] Remove control characters (ASCII < 32) to prevent hidden/invalid bytes.
- [x] Normalise whitespace (collapse tabs, newlines, multiple spaces to single space).
- [x] Collapse consecutive dashes (e.g., `--` → `-`).
- [x] Trim leading/trailing spaces and dots.
- [x] Handle Windows reserved names (e.g., `CON`, `PRN`, `COM1`) by appending `_file`.
- [x] Truncate to 255 characters (Windows filename limit).
- [x] Resolve collisions without overwriting: append `-1`, `-2`, etc., until unique path found.
  - Code location: [scripts/Rename-MyFiles.ps1](scripts/Rename-MyFiles.ps1#L231-L248) lines 231–248 (Resolve-UniqueFilePath).

## Phase 5 - Reporting and Documentation

**Status:** ✅ **Complete**

**Objective:** Ensure comprehensive, accurate documentation aligned with implementation.

### Completed Tasks

#### Installation & Setup Documentation
- [x] Update README.md to list Azure CLI (not Az module) as prerequisite.
- [x] Update user-guide.md to list Azure CLI (not Az module) as prerequisite.
- [x] Update RUNBOOK.md to list Azure CLI (not Az module) as prerequisite.
- [x] Remove all references to separate Bicep installation (built into Azure CLI).

#### Deployment & Cost Documentation
- [x] Add GlobalStandard deployment explanation to README.md (data processing may occur in any region).
- [x] Add GlobalStandard deployment explanation to user-guide.md (with compliance considerations).
- [x] Add cost estimates to README.md (per-document and batch examples).
- [x] Add cost estimates to user-guide.md (with Azure OpenAI pricing link).
- [x] Clarify pricing structure: pay-as-you-go, no idle cost.

#### Limitations & Caveats Documentation
- [x] Clearly list plain-text file support (fully capable).
- [x] Clearly document PDF placeholder limitation (filename context only).
- [x] Clearly document Office placeholder limitation (filename context only).
- [x] Note that unsupported file types are skipped.
- [x] Note that only top-level files are processed (no recursion).

#### Architecture Decision Records (ADRs)
- [x] Create [DECISIONS/ADR-0002-azure-cli-over-az-module.md](DECISIONS/ADR-0002-azure-cli-over-az-module.md) — rationale for Azure CLI migration.
  - [x] Create [DECISIONS/ADR-0003-globalstandard-deployment-type.md](DECISIONS/ADR-0003-globalstandard-deployment-type.md) — data residency trade-offs and alternatives (DataZoneStandard, Regional Standard).
  - [x] Create [DECISIONS/ADR-0004-restore-soft-deleted-resources.md](DECISIONS/ADR-0004-restore-soft-deleted-resources.md) — soft-delete handling strategy and manual purge instructions.

#### Troubleshooting & Operational Guidance
- [x] Document soft-deleted resource troubleshooting in [RUNBOOK.md](RUNBOOK.md) (soft-delete retention, manual purge steps).
- [x] Document data residency and processing location implications in user-guide.md.

## Phase 6 - Enhanced Content Extraction

**Status:** ⏳ **Not Started** (Post-MVP Backlog)

**Objective:** Replace placeholder extraction logic with real text extraction for PDF and Office documents, improving AI-generated filename quality.

### Why Post-MVP?

- Current placeholder extraction (filename context) allows all file types to receive best-effort renames.
- Real text extraction requires new dependencies, cross-platform testing, and error handling.
- MVP scope ([SCOPE.md](SCOPE.md)) does not mandate PDF/Office text support; plain-text only is MVP.
- Deferring to Phase 6 allows MVP release with stable, minimal dependencies.

### Phase 6a - PDF Text Extraction

**Priority:** High (most common document type after plain text)

#### Task: Research & Select PDF Extraction Method
- [x] Investigate PDF extraction options:
  - **PdfPig** (.NET library, approx. 500 KB, MIT licensed, cross-platform via .NET Core/Framework).
  - **pdftotext** (external utility, requires installation and PATH setup).
  - **iTextSharp** (.NET library, commercial license considerations).
  - **Azure Document Intelligence** (cloud service, costs per page, adds dependency).
- [x] Evaluation criteria:
  - Cross-platform support (Windows, macOS, Linux).
  - Cross-platform installation ease (NuGet package preferred over external utilities).
  - Licensing (no proprietary/expensive licenses).
  - Error handling (malformed/encrypted PDFs fall back gracefully).
  - Size (minimal impact on script distribution).
- [x] Document recommendation and rationale in [DECISIONS/ADR-0005-pdf-text-extraction.md](DECISIONS/ADR-0005-pdf-text-extraction.md).
  - **Recommended Method:** PdfPig (UglyToad.PdfPig)
  - **Rationale:** MIT license, no external dependencies, cross-platform, robust error handling, minimal footprint.
  - **Not Recommended:** pdftotext (installation friction), iTextSharp (licensing risk), Azure Document Intelligence (cost + privacy concerns).

#### Task: Implement PDF Text Extraction
- [x] Modify `Get-FileTextContent` function in [scripts/Rename-MyFiles.ps1](scripts/Rename-MyFiles.ps1).
  - [x] Replaced placeholder logic with real PDF text extraction using PdfPig.
  - [x] Implemented `Get-PdfTextContent` helper function (lines 110–168).
  - [x] Added PdfPig assembly loading at script startup (lines 78–113).
  - [x] Extract up to 8000 characters (existing limit maintained).
  - [x] Handle unsupported/encrypted/malformed PDFs by catching errors and falling back gracefully.
  - [x] Return extracted text or $null on failure; never throws (dependency errors logged as warnings, file is skipped).
- [x] Critical fixes after initial implementation:
  - [x] **Removed fallback to filename context** (lines 188–203): PDFs now skipped (not degraded) if PdfPig unavailable.
  - [x] **Added RateLimitReached detection and exponential backoff** (lines 227–348): Detects HTTP 429 or "RateLimitReached" errors. Retries up to 3 times with exponential backoff. Provides explicit warning.
  - [x] **Improved rate limit handling with Retry-After headers** (lines 304–365): Reads `Retry-After` or `retry-after-ms` headers from Azure OpenAI responses (Microsoft recommended approach). Adds jitter (±25% random variation) to avoid thundering herd. Falls back to exponential backoff if headers unavailable. Better error messages distinguishing TPM vs RPM limits.
  - [x] **Added request throttling/pacing** (new parameter `RequestThrottleSeconds`, default 5s): Adds configurable delay between API calls to avoid bursting into Token-Per-Minute (TPM) limits. Prevents "first call succeeds, all others fail" pattern common with TPM quotas.
  - [x] **Added explicit PdfPig missing warning** (lines 104–111): Script warns users at startup if PdfPig not loaded.
  - [x] **Created Install-Dependencies.ps1 script**: Automates PdfPig installation. Fixed package name (PdfPig vs UglyToad.PdfPig), API version (v2 vs v3), and version (0.1.13).
  - [x] **Fixed Install-Dependencies.ps1 to install all transitive dependencies**: Now copies all 7 DLLs from NuGet package (not just main assembly). Fixed Split-Path parameter compatibility. Added file-locking error handling.
  - [x] **Fixed PdfPig API usage**: Changed from `.Pages` property to `.GetPages()` method (correct API for v0.1.13).
  - [x] **Fixed error reporting**: Dependency loading errors now throw with installation instructions instead of silently failing as "corrupted PDF".
- [x] Add new prerequisite documentation.
  - [x] Updated README.md with PdfPig optional dependency (UglyToad.PdfPig).
  - [x] Added "Optional: Install PdfPig for PDF text extraction" section to README.md with clear consequences.
  - [x] Updated prerequisites list with optional PdfPig package.
- [x] Test with realistic PDF samples (manual validation).
  - [x] Text-based PDF: extraction works; returns null on parsing errors.
  - [x] Scanned PDF: returns null; file skipped (not degraded to filename).
  - [x] Encrypted/password-protected PDF: parsing error caught; file skipped.
  - [x] Malformed/corrupted PDF: parsing error caught; file skipped.
  - [x] RateLimitReached error: detected, retried with backoff, explicitly reported if persistent.
  - [x] Error handling ensures no file halts batch processing.
- [x] Update user-guide.md and index.md to reflect PDF extraction support with caveats.
  - [x] Updated "Limitations and Caveats" table in user-guide.md (clearer rows for PDF states).
  - [x] Added Azure API rate limit row to limitations table with guidance.
  - [x] Updated "Enabling PDF text extraction" section with PdfPig installation and consequence documentation.
  - [x] Updated docs/index.md limitations section to accurately reflect PDF text support.

### Phase 6-Smart-Skip: Intelligent Skip Logic for Already-Descriptive Filenames

**Status:** ✅ **Complete**

**Priority:** High (improves UX by avoiding unnecessary/redundant renames)

**Objective:** Skip files that already have descriptive names or would result in no filename change, allowing users to focus AI processing on files that need renaming.

**Rationale:** Some files already have good names (e.g. `Acme Ltd Invoice - 2025-02-15.pdf`). Processing these through Azure AI is wasteful (cost + energy + quota). Users can optionally force renaming with `-Force` if needed.

#### Task: Add Smart Skip Logic
- [x] Implement `Test-FilenameIsDescriptive` helper function to detect if current filename looks "already good".
  - [x] Check for date patterns: YYYY-MM-DD, "Month Year", "Month YYYY", YYYY, MM/DD/YYYY, DD/MM/YYYY.
  - [x] Check for business keywords: Invoice, Receipt, Statement, Letter, Report, Agreement, Contract, Proposal, Quote, Order, Payment, Tax, Return, Refund, etc.
  - [x] Return `$true` if filename contains both a date pattern AND at least one business keyword.
  - [x] Return `$false` for generic filenames like `Document.docx`, `scan0042.pdf`, `File (3).txt`.
  - Code location: [scripts/Rename-MyFiles.ps1](scripts/Rename-MyFiles.ps1#L552-L598)
- [x] Add `-Force` parameter to `Rename-MyFiles.ps1`.
  - [x] Allow forcing rename of already-descriptive files (bypass smart skip logic).
  - [x] Update help text: "Force rename even if current filename appears already descriptive."
  - Code location: [scripts/Rename-MyFiles.ps1](scripts/Rename-MyFiles.ps1#L50-L52) and parameter block lines 91–93.
- [x] Modify main processing loop to check both conditions before renaming:
  - [x] If current filename is descriptive AND `-Force` not set: Skip before calling Azure AI (saves cost).
  - [x] If new filename == current filename (case-insensitive): Skip with reason "Filename unchanged".
  - [x] Otherwise: Proceed to rename.
  - Code location: [scripts/Rename-MyFiles.ps1](scripts/Rename-MyFiles.ps1#L620-L640) and [lines 667–675](scripts/Rename-MyFiles.ps1#L667-L675).
- [x] Update summary reporting.
  - [x] Count files skipped due to "already descriptive" separately.
  - [x] Count files skipped due to "unchanged" separately.
  - [x] Display both counts in summary output.
  - Code location: [scripts/Rename-MyFiles.ps1](scripts/Rename-MyFiles.ps1#L723-L736)
- [x] Update dry-run (`-WhatIf`) behavior.
  - [x] Show "SKIPPED (already descriptive)" for files with good names.
  - [x] Show "SKIPPED (filename unchanged)" for identical filenames.
  - [x] Show "PROPOSED" for files that would be renamed.

#### Task: Test Smart Skip Logic
- [x] Test with realistic file samples:
  - [x] File with date + business keyword already present (e.g. `Invoice - 2025-02-15.pdf`): should skip without -Force.
  - [x] File with `-Force` flag and good name: should rename anyway.
  - [x] File with unchanged proposal (e.g. AI suggests same name): should skip.
  - [x] Generic filename (`Document.docx`, `scan0042.pdf`): should always attempt rename.
  - [x] Mixed batch (some good, some generic): verify skip counts correct in summary.
- [x] Validate dry-run output shows correct skip reasons.

#### Acceptance Criteria
- [x] Script runs without errors (PSScriptAnalyzer passes).
- [x] `-Force` parameter is present and functional in script help.
- [x] Files with descriptive names (date + business keyword) are skipped by default.
- [x] Files with no keywords (generic names) are always processed.
- [x] Files with `RequestThrottleSeconds` and `-Force` allow forcing re-process.
- [x] Summary shows breakdown of skip reasons (already descriptive, unchanged, etc).
- [x] Dry-run correctly shows "SKIPPED" vs "PROPOSED" based on smart logic.

#### Validation Steps
1. **Dry-run with mixed filenames:**
   ```powershell
   $testDir = 'C:\temp\test-files'
   
   # Create test files
   @{
       'Invoice - 2025-02-15.pdf' = 'invoice content'
       'scan0042.pdf' = 'pdf content'
       'Document.docx' = 'doc content'
       'Tax Return 2024-25.xlsx' = 'tax doc'
   } | ForEach-Object {
       $path = Join-Path $testDir $_.Keys; 
       Set-Content -LiteralPath $path -Value $_.Values
   }
   
   # Run dry-run
   .\scripts\Rename-MyFiles.ps1 -FolderPath $testDir -WhatIf
   
   # Expect: Invoice skipped as "already descriptive", others proposed
   ```

2. **Test `-Force` flag:**
   ```powershell
   .\scripts\Rename-MyFiles.ps1 -FolderPath $testDir -Force -WhatIf
   
   # Expect: Even "Invoice" file now shows "PROPOSED" (not skipped)
   ```

3. **Test unchanged filename detection:**
   Run against a file where Azure AI would propose the same name as current. Script should skip it as "Filename unchanged".

4. **Check summary output:**
   ```powershell
   .\scripts\Rename-MyFiles.ps1 -FolderPath $testDir -WhatIf
   
   # Expect summary shows:
   # Files scanned: (total)
   # Files renamed: (would rename count)
   # Files skipped: (total skipped)
   # Skip breakdown:
   #   - Already descriptive: (count)  
   #   - Filename unchanged: (count)
   ```

### Phase 6b - Image Processing

**Status:** ⏳ **Not Started**

**Priority:** High (most common file type users scan and dump: scanned documents, receipts, photos)

**Objective:** Add support for image files (primarily JPEG, PNG) by using Optical Character Recognition (OCR) or vision-based AI to extract content and propose filenames.

**Rationale:** Users frequently scan documents (invoices, receipts, letters) as images and need them renamed. Images are likely the primary real-world use case after plain-text files. This phase brings image support previously considered out-of-scope into the active pipeline.

#### Task: Research & Select Image Processing Method
- [ ] Investigate image processing options:
  - **Azure Computer Vision (Read API):** Cloud service, provides OCR; costs per image; requires additional Azure SDK.
  - **Tesseract (CLI):** Free, open-source, cross-platform OCR; requires external tool installation and PATH setup.
  - **IronOCR (.NET library):** Commercial library, cross-platform; licensing restrictions.
  - **Azure OpenAI Vision:** Multimodal model (GPT-4V); send image pixels directly for filename proposals; may be cost-effective.
- [ ] Evaluation criteria:
  - Format coverage (.jpg, .jpeg, .png minimum; .gif, .bmp optional).
  - Cross-platform support (Windows, macOS, Linux).
  - Installation ease (NuGet preferred over external utilities).
  - Licensing (open source or permissive, no commercial restrictions).
  - Cost per image vs plain-text processing.
  - Privacy implications (sending image pixels to third parties vs OCR locally).
- [ ] Document recommendation and rationale in [DECISIONS/ADR-000X-image-processing.md](DECISIONS/) (future ADR).
  - Compare OCR + existing filename prompt vs direct vision model approach.
  - Calculate cost implications for typical batch (e.g., 100 scanned documents).

#### Task: Implement Image Processing
- [ ] Modify `Get-FileTextContent` function in [scripts/Rename-MyFiles.ps1](scripts/Rename-MyFiles.ps1).
  - [ ] Add support for `.jpg`, `.jpeg`, `.png` image formats.
  - [ ] Extract text via chosen method (OCR library or vision API).
  - [ ] Return extracted text up to 8000 characters (existing limit).
  - [ ] Handle unsupported/corrupted/unreadable images by catching errors and skipping gracefully.
  - [ ] Return $null only for truly unsupported formats.
- [ ] Add optional prerequisite documentation (if library requires installation).
  - [ ] Specify exact NuGet package/utility version and installation steps.
  - [ ] Document installation for Windows, macOS, and Linux.
- [ ] Test with realistic image samples:
  - [ ] Scanned PDF-as-image (JPEG of invoice).
  - [ ] Photo of receipt or letter.
  - [ ] Handwritten image (test OCR limits).
  - [ ] Corrupted/unreadable image.
  - [ ] Verify error handling does not stop batch processing.
- [ ] Update user-guide.md to document image support with caveats.
  - [ ] Note limitations (handwriting, very low resolution, non-text content like diagrams).
  - [ ] Clarify cost implications if using vision API.

#### Acceptance Criteria
- [ ] Script runs without errors when processing mixed batches (text + PDF + images).
- [ ] Images with readable text are processed; unreadable images are skipped with reason.
- [ ] Summary report includes image processing results.
- [ ] Documentation updated for end users.

### Phase 6c - Office Document Text Extraction

**Priority:** Medium (frequently renamed, multiple formats)

#### Task: Research & Select Office Extraction Method
- [ ] Investigate Office document extraction options:
  - **DocumentFormat.OpenXml** (.NET library, Microsoft-supported, cross-platform via .NET Core/Framework).
  - **OpenXML SDK** (similar to above, official Microsoft library).
  - **LibreOffice CLI** (`soffice` command-line, external utility, cross-platform).
  - **Azure Document Intelligence** (cloud service, costs per page, adds dependency).
- [ ] Evaluation criteria:
  - Format coverage (.docx, .xlsx, .pptx minimum; .doc, .xls, .ppt optional).
  - Cross-platform support (Windows, macOS, Linux).
  - Installation ease (NuGet preferred over external utilities).
  - Licensing (open source or permissive).
  - Error handling (corrupted/password-protected documents handled gracefully).
- [ ] Document recommendation and rationale in [DECISIONS/ADR-000X-office-extraction.md](DECISIONS/) (future ADR).

#### Task: Implement Office Document Text Extraction
- [ ] Modify `Get-FileTextContent` function in [scripts/Rename-MyFiles.ps1](scripts/Rename-MyFiles.ps1) (lines 104–107).
  - Replace placeholder logic returning `[Office document: <filename>]` with real extraction.
  - Support at minimum: `.docx`, `.xlsx`, `.pptx`.
  - Extract up to 8000 characters from first sheet/slide (existing limit).
  - Handle corrupted/password-protected/unsupported formats by catching errors and falling back to filename context.
  - Return extracted text or placeholder, never throw.
- [ ] Add new prerequisite documentation (if library requires installation).
  - Specify exact NuGet package version or external utility version.
  - Document installation steps for Windows, macOS, and Linux.
- [ ] Test with realistic Office document samples:
  - `.docx` file (modern Word format).
  - `.xlsx` file with multiple sheets (extract from first sheet).
  - `.pptx` file with multiple slides (extract from first slide).
  - Password-protected `.docx` (fallback to context).
  - Corrupted/malformed file (fallback to context).
- [ ] Update user-guide.md to list Office document extraction under supported file types.
  - Note format support (.docx, .xlsx, .pptx, etc.).
  - Note limitations (password-protected, corrupted, etc.).

### Phase 7 - Validation & Release

**Status:** ⏳ **Not Started**

**Objective:** Comprehensive final testing and validation before any official release or public announcement.

- [ ] Test cross-platform behaviour:
  - Windows (native .NET on Windows or .NET Core).
  - macOS (.NET Core / .NET 5+).
  - Linux (.NET Core / .NET 5+).
- [ ] Confirm error handling does not break batch processing:
  - Run with mixed file types (plain text, PDF, Office, unsupported).
  - Verify all files attempt rename; no exceptions bubble up.
  - Verify summary accurate (renamed/skipped counts correct).
- [ ] Run linting and validation:
  - PSScriptAnalyzer: `Invoke-ScriptAnalyzer -Path .\scripts -Settings .\PSScriptAnalyzerSettings.psd1 -Recurse`
  - Bicep build (if dependencies require Bicep changes): `az bicep build --file infra/main.bicep`
- [ ] Update [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) to mark Phase 6 complete.
- [ ] Update [README.md](README.md) **Current Limitations** section to reflect new extraction capabilities.

## Future Enhancements (Out of Scope — Not Immediately Planned)

These features are documented as potential future work beyond Phase 7 validation:

- **Recursive subfolder processing** — Current design processes only top-level files to keep behaviour straightforward. Could be added as a flag (e.g., `-Recurse`) in a future version.
- **Batch capacity optimisation** — Scale to 10,000+ files by increasing Azure OpenAI TPM (tokens per minute) quota. Requires quota adjustments and batching logic.
- **Alternative AI backends** — Currently Azure OpenAI only. Other providers (OpenAI API, Anthropic Claude, etc.) could be added, but would require new integration code and testing.
- **GUI or web interface** — Current CLI approach is lightweight and cross-platform. A GUI could improve UX for non-technical users but adds complexity and platform-specific dependencies.
- **File content modification** — Explicitly out of scope. This tool **only renames**; it never edits file contents.
- **Advanced image understanding** — Handwriting recognition, diagram understanding, multi-modal vision at scale (beyond basic OCR).

## Assumptions & Design Decisions

### Current Implementation (MVP Phases 0–5, Phase 6 In Progress)

- **No automated tests:** Validation is manual (dry-run testing, visual inspection). Test harness to be added in future if needed.
- **Azure OpenAI only:** Single AI backend simplifies code and deployment. Alternative providers deferred to post-Phase 7.
- **Credential passing:** Users supply credentials via environment variables (`AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_KEY`) or script parameters for flexibility.
- **PowerShell 7.2+:** Required for cross-platform support (`$PSVersionTable.PSVersion`). Tested on Windows; untested on macOS/Linux but theoretically compatible.
- **Azure CLI (az):** Must be installed; verified at script runtime via `Get-Command az`.
- **Bicep built-in:** Azure CLI includes Bicep compiler; no separate installation needed.
- **Soft-delete handling:** Bicep property `restore: true` automatically restores recently soft-deleted Azure OpenAI resources during redeployment.
- **GlobalStandard deployment:** Data may be processed in any Azure region; stricter alternatives (DataZoneStandard, Regional Standard) available at higher cost (documented in ADR-0003).
- **Plain-text extraction (MVP):** Fully supported. PDF extraction (Phase 6a) and smart-skip logic (Phase 6-Smart-Skip) also complete.
- **Image support priority:** Now prioritised in Phase 6b based on user research showing scanned documents (PDFs, images) are the primary real-world use case.

### Phase 6 Assumptions (Post-MVP Enhancement)

- **User motivation:** Primary real-world use case is renaming scanned documents (PDFs, images) and generic files. Phase 6 prioritises content extraction (PDF, images, Office) and smart skip logic to address this core need.
- **Cross-platform extraction:** All extraction methods (PDF, images, Office) must work on Windows, macOS, and Linux without commercial licenses.
- **Library preference:** Favour .NET libraries (via NuGet) or fully free/open-source tools (OCR utilities) over paid cloud services or external utilities requiring PATH setup.
- **Graceful degradation:** If extraction fails (malformed, encrypted, unreadable), skip the file gracefully rather than stopping the batch.
- **8000-character limit:** Maintain existing truncation for all extraction phases to control Azure OpenAI token usage and costs.
- **Optional dependencies:** Image and Office extraction libraries are optional. Users can install them (e.g., `Install-Dependencies.ps1`) if needed; files are skipped with clear guidance if dependencies are missing.
- **Image support priority:** Images (Phase 6b) are prioritised before Office documents (Phase 6c) because scanned documents are a primary motivation for this tool.

## Phase 8 - Future Considerations: Expanded Features (Out of Scope)

**Status:** ⏳ **Not Started**

**Objective:** Evaluate longer-term enhancements beyond the current Phase 6 focus.

### 8a - Deeper Image Understanding (Future Research)

Once basic OCR-based image support is in place (Phase 6b), consider:

- [ ] Advanced OCR for handwriting and complex layouts.
- [ ] Multi-modal vision models for direct image-to-filename proposals (e.g., GPT-4 Vision at scale).
- [ ] Diagram and table recognition for technical documents.

### 8b - Recursive Folder Processing

Currently out of scope. Future enhancement could add:

- [ ] `-Recurse` flag to process subfolders and nested directories.
- [ ] Preservation of folder hierarchy in renamed files (optional prefixing or flattening).

### 8c - Batch Optimisation

- [ ] Scale to 10,000+ files by optimising Azure OpenAI quota and batching logic.
- [ ] Parallel processing (with rate-limit awareness) to reduce total runtime.
- [ ] Resume capability for interrupted batches.

**Note:** These features are intentionally deferred to allow focus on core Phase 6 capabilities (PDF, images, Office documents) and Phase 7 validation.
