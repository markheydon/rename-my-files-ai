# ADR-0005: PDF Text Extraction Method Selection

## Status

Accepted

## Context

Phase 6a requires replacing the placeholder PDF extraction logic (currently returns `[PDF file: <filename>]`) with real text extraction. This decision evaluates multiple approaches based on the project's constraints:

- **Cross-platform requirement:** Windows, macOS, Linux must all work identically.
- **Installation complexity:** Prefer NuGet packages over external CLI utilities (easier distribution, no PATH dependency).
- **Licensing:** No proprietary, closed-source, or expensive licenses.
- **Error resilience:** Malformed, encrypted, or corrupted PDFs must fall back gracefully without stopping the batch.
- **Dependencies:** Minimal impact on script footprint; no heavy runtime requirements.
- **Integration:** PowerShell 7 native (can use .NET libraries via `Add-Type` or import via assembly).

## Evaluation of Candidates

### 1. PdfPig

**Library:** `UglyToad.PdfPig` (NuGet package)

**Size:** ~500 KB (core + dependencies)

**Licensing:** MIT (fully open source, permissive)

**Cross-Platform:** Yes (works with .NET Core / .NET 5+)

**Installation:** NuGet package; load in PowerShell via `Add-Type -Path`

**Error Handling:**
- Designed to handle malformed PDFs gracefully (doesn't throw on corrupted headers).
- Returns empty or partial text from corrupted documents.
- Does not decrypt password-protected PDFs; returns empty string.

**Pros:**
- Lightweight and minimal dependencies.
- MIT license explicitly permits commercial use.
- Actively maintained (last update: 2024).
- Works cross-platform without external utilities.
- Handles edge cases (corrupted, truncated, scanned PDFs) without crashing.
- Can be redistributed with the script as a NuGet assembly.

**Cons:**
- Requires .NET runtime availability (PowerShell 7 provides this).
- No built-in support for scanning (image-based) PDFs.
- May extract limited text from complex layouts (acceptable; better than filename context).

**Recommendation:** ✅ **RECOMMENDED**

---

### 2. pdftotext (Poppler utility)

**Tool:** External command-line utility (part of Poppler PDF rendering library)

**Licensing:** GPL / Apache 2.0 (open source)

**Cross-Platform:** Yes (available for Windows, macOS, Linux)

**Installation:** System-level installation required (not bundled with PowerShell)

**Error Handling:**
- Returns exit code 1 on encrypted/corrupted PDFs; falls back easily.
- Supports per-page extraction.

**Pros:**
- Battle-tested, widely used.
- Good text extraction quality.
- Can extract from encrypted PDFs with optional password.

**Cons:**
- ❌ Requires separate installation on each machine (breaks "minimal setup" goal).
- ❌ PATH dependency; easy to break if utility moves or is not in PATH.
- ❌ Not bundled with PowerShell; distribution burden.
- ❌ External process overhead per PDF (slower than library).
- Different versions on Windows, macOS, Linux → testing burden.

**Recommendation:** ❌ **NOT RECOMMENDED** (installation friction too high for user base)

---

### 3. iTextSharp

**Library:** `iTextSharp` (NuGet package)

**Licensing:** AGPL v3 (open source) for versions < 5.1; later versions proprietary (requires commercial license for redistribution)

**Cross-Platform:** Yes (.NET library)

**Installation:** NuGet package

**Error Handling:** Robust error handling, but licensing complexity makes it risky for commercial use.

**Pros:**
- Very mature, feature-rich.
- Handles complex PDFs well.

**Cons:**
- ❌ **Licensing conflict:** iTextSharp ≥ 5.0 is AGPL; redistribution requires open-sourcing or commercial license.
- ❌ Licensing model creates legal risk if the tool is distributed to users without explicit compliance.
- Overkill for simple text extraction (heavier than needed).
- Community is fragmenting due to license issues.

**Recommendation:** ❌ **NOT RECOMMENDED** (licensing risk outweighs features)

---

### 4. Azure Document Intelligence (formerly Form Recognizer)

**Service:** Cloud-based AI service (Microsoft Azure)

**Licensing:** Per-page usage fee (~$1–$2 per page depending on tier)

**Cross-Platform:** Yes (cloud service, language-agnostic)

**Installation:** No local installation; calls Azure REST API

**Error Handling:** Returns structured data or error; handles encrypted PDFs gracefully.

**Pros:**
- Excellent OCR for scanned documents.
- Handles complex layouts, handwriting, tables.
- Cloud-based; no local dependency.

**Cons:**
- ❌ **Cost:** Adds per-page cost to every file rename. For a 100-page PDF, cost is $2. For a user batch-renaming 50 PDFs (avg 10 pages each) = ~$10 per batch. Unacceptable overhead.
- ❌ Adds new Azure service dependency (resource, quota management, cost tracking).
- ❌ Cloud API latency (slower than local extraction).
- ❌ Privacy concern: PDF pages must be sent to Azure cloud (not suitable for sensitive documents).
- Out of scope per project decisions (single AI backend for naming, not extracting).

**Recommendation:** ❌ **NOT RECOMMENDED** (cost and privacy concerns)

---

## Decision

**Selected Method: PdfPig (UglyToad.PdfPig)**

We will replace the PDF placeholder extraction in `Rename-MyFiles.ps1` with PdfPig-based extraction.

### Rationale

- **MIT License:** Fully permissive; no commercial redistribution concerns.
- **No external dependency:** Works entirely within PowerShell/.NET; no PATH setup required.
- **Cross-platform:** Compatible with Windows, macOS, Linux via PowerShell 7.
- **Minimal footprint:** ~500 KB core; easily bundled with the script or installed via NuGet.
- **Error resilience:** Corrupted, encrypted, or malformed PDFs do not throw; extract what is readable or return empty gracefully.
- **Integration:** Load via `Add-Type` in PowerShell; familiar pattern.
- **Active maintenance:** Library is under active development (as of 2024).

### Implementation Plan

1. **Dependency management:**
   - Add `UglyToad.PdfPig` as a NuGet reference in the script or a supporting manifest.
   - Document installation: `Install-Package UglyToad.PdfPig` (requires NuGet or manual assembly bundle).
   - Consider shipping pre-compiled assembly as an optional bundle in `/lib` folder to avoid runtime NuGet calls.

2. **Code changes:**
   - Replace placeholder in `Get-FileTextContent` (lines 92–100 of `Rename-MyFiles.ps1`).
   - Load PdfPig assembly at script startup.
   - Extract text up to 8000 characters (existing limit).
   - Catch and fall back to placeholder on read failure (malformed, encrypted, etc.).

3. **Testing:**
   - Small text-based PDF (normal case).
   - Scanned/image-based PDF (expect empty or limited text; fallback acceptable).
   - Encrypted PDF (expect empty; fallback acceptable).
   - Corrupted PDF (expect graceful failure; fallback acceptable).
   - Windows, macOS, Linux (if cross-platform testing available).

4. **Documentation:**
   - Update README.md and user-guide.md: PDF support added (with caveats for scanned/encrypted).
   - Update RUNBOOK.md: PDF text extraction now enabled.
   - Note: Scanned PDFs still rely on filename context (no OCR in MVP).

### Future Considerations

- If image-based PDFs (scanned documents) must be OCR'd, defer to Phase 7 (Image Support Feasibility).
- If Azure Document Intelligence is later approved for vision/OCR tasks, it would be a separate decision with explicit cost and privacy trade-offs documented.

## Consequences

**Positive:**
- Users can rename PDFs with real content extraction (substantial quality improvement over placeholder).
- No new external dependencies or PATH setup required.
- MIT license eliminates legal/regulatory risk.
- Graceful fallback for edge cases (corrupted, encrypted, unusual PDFs).

**Negative:**
- Adds a .NET library dependency (PdfPig assembly must be available at runtime).
- Scanned PDFs will still return empty or minimal text (acceptable; OCR is out of scope).
- Encrypted PDFs cannot be read without password (acceptable; password handling is out of scope).

**Neutral:**
- Slight increase in script complexity (assembly loading, error handling for PDF parsing).
- ~500 KB download/storage overhead if bundled.
