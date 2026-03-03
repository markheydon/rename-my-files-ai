---
title: Rename My Files
layout: home
---

# Rename My Files

**Rename My Files** automatically renames files with clearer, descriptive names by using AI to analyse available text content.

Instead of names like `scan0042.pdf` or `Document (3).docx`, you get names such as:

- `Acme Ltd Invoice - February 2025.pdf`
- `HMRC Self Assessment Tax Return 2024-25.pdf`
- `Dr Smith Referral Letter - John Doe.docx`

---

## How It Works

1. You point the tool at a folder of files.
2. The tool reads available text content from each file.
3. It sends that context to Azure AI in your Azure subscription.
4. Azure AI suggests a descriptive, human-readable name.
5. The tool renames the file, keeping the same extension.

Your files stay in the same folder — only their names change.

---

## Getting Started

👉 **New here? Start with the [User Guide](user-guide.md)** — it walks you through everything step by step, including how to set up Azure and run the tool.

---

## Limitations

- Plain text files (`.txt`, `.md`, `.csv`, etc.) and PDF files with PdfPig installed are fully supported.
- Scanned PDFs, encrypted PDFs, and Office documents have limited/no support and will be skipped.
- Unsupported or unreadable files are skipped.
- AI-generated names are suggestions — they may not always be perfect.
- Only files in the selected folder are processed (subfolders are not scanned).

---

## Cost

Using this tool requires an Azure account. Costs are **very low** for typical use:

- About **$0.0001 per document** for typical files.
- **No ongoing idle cost** — you only pay when the tool processes a file.

See the [User Guide](user-guide.md#cost) for more detail.

---

## Source & Contributions

- [View on GitHub](https://github.com/markheydon/rename-my-files-ai)
- Licensed under the [MIT Licence](https://github.com/markheydon/rename-my-files-ai/blob/main/LICENSE)
