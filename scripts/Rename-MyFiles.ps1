<#
.SYNOPSIS
    Renames files in a folder using Azure AI to generate descriptive, human-readable filenames.

.DESCRIPTION
    Rename-MyFiles.ps1 iterates through each file in the specified folder, reads its content,
    and uses an Azure OpenAI model to propose a meaningful filename based on the document's
    subject, sender, recipient, and any reliable date information. The file is then renamed
    on disk, preserving its original extension.

    Files that cannot be read (unsupported types, encrypted, corrupted) are skipped and logged.
    A summary is displayed at the end showing how many files were renamed, skipped, or failed.

.PARAMETER FolderPath
    The path to the folder containing the files to rename. Must exist and be accessible.

.PARAMETER AzureOpenAIEndpoint
    The Azure OpenAI resource endpoint URL (e.g. https://my-resource.openai.azure.com/).
    If not provided, falls back to the AZURE_OPENAI_ENDPOINT environment variable.

.PARAMETER AzureOpenAIKey
    The Azure OpenAI API key.
    If not provided, falls back to the AZURE_OPENAI_KEY environment variable.

.PARAMETER DeploymentName
    The name of the Azure OpenAI model deployment to use. Defaults to 'gpt-4o-mini'.

.PARAMETER RequestThrottleSeconds
    Delay in seconds between Azure OpenAI API calls to avoid rate limits (default: 5 seconds).
    Default is tuned for typical usage with moderate quota. Most users should not need to change this.

.PARAMETER MaxPromptCharacters
    Maximum characters sent to Azure OpenAI from each file (default: 900).
    Lower values reduce token usage and cost per file. Default is set for low-cost operation.

.PARAMETER WhatIf
    Shows what files would be renamed without actually renaming them.

.EXAMPLE
    .\Rename-MyFiles.ps1 -FolderPath "C:\Documents\Unfiled"

    Renames all supported files in C:\Documents\Unfiled using Azure AI.

.EXAMPLE
    .\Rename-MyFiles.ps1 -FolderPath "C:\Documents\Unfiled" -WhatIf

    Shows proposed renames without making any changes.

.EXAMPLE
    .\Rename-MyFiles.ps1 -FolderPath "C:\Documents\Unfiled" -Verbose

    Renames files with detailed progress output.



.NOTES
    Requires PowerShell 7.2 or later.
    Set AZURE_OPENAI_ENDPOINT and AZURE_OPENAI_KEY environment variables, or pass them as parameters.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory, Position = 0, HelpMessage = 'Path to the folder containing files to rename.')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container }, ErrorMessage = 'FolderPath must be an existing directory.')]
    [string]$FolderPath,

    [Parameter(HelpMessage = 'Azure OpenAI endpoint URL. Falls back to AZURE_OPENAI_ENDPOINT env var.')]
    [string]$AzureOpenAIEndpoint = $env:AZURE_OPENAI_ENDPOINT,

    [Parameter(HelpMessage = 'Azure OpenAI API key. Falls back to AZURE_OPENAI_KEY env var.')]
    [string]$AzureOpenAIKey = $env:AZURE_OPENAI_KEY,

    [Parameter(HelpMessage = 'Azure OpenAI model deployment name.')]
    [ValidateNotNullOrEmpty()]
    [string]$DeploymentName = 'gpt-4o-mini',

    [Parameter(HelpMessage = 'Delay in seconds between Azure OpenAI API calls to avoid TPM/RPM rate limits.')]
    [ValidateRange(0, 60)]
    [int]$RequestThrottleSeconds = 5,

    [Parameter(HelpMessage = 'Maximum number of characters sent to Azure OpenAI from each file (lower values reduce token usage).')]
    [ValidateRange(400, 8000)]
    [int]$MaxPromptCharacters = 900
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Module loading: Attempt to load PdfPig for PDF text extraction.
# ---------------------------------------------------------------------------
$pdfPigLoaded = $false
$pdfPigAssemblyPath = $null

# Try to find PdfPig in common NuGet locations.
$nugetPaths = @(
    "$env:USERPROFILE\.nuget\packages\uglytoad.pdfpig\*\lib\net*\UglyToad.PdfPig.dll",
    "$PSScriptRoot\..\lib\UglyToad.PdfPig.dll",
    "$PSScriptRoot\lib\UglyToad.PdfPig.dll"
)

foreach ($searchPath in $nugetPaths) {
    $resolvedPath = Resolve-Path -Path $searchPath -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($resolvedPath) {
        $pdfPigAssemblyPath = $resolvedPath.Path
        try {
            Add-Type -LiteralPath $pdfPigAssemblyPath -ErrorAction Stop
            $pdfPigLoaded = $true
            Write-Verbose "Successfully loaded PdfPig from: $pdfPigAssemblyPath"
            break
        }
        catch {
            Write-Verbose "Failed to load PdfPig from $pdfPigAssemblyPath : $_"
            $pdfPigLoaded = $false
        }
    }
}

if (-not $pdfPigLoaded) {
    Write-Warning @"
⚠️  PdfPig library not found. PDF files will be SKIPPED.

To enable PDF support, run the installation script:
    .\scripts\Install-Dependencies.ps1

Then run this script again. For details, see: docs/user-guide.md > Enabling PDF text extraction
"@
}

# ---------------------------------------------------------------------------
# Helper: Extract text from a PDF file using PdfPig.
# Returns extracted text up to 8000 characters, or $null on failure.
# ---------------------------------------------------------------------------
function Get-PdfTextContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    if (-not $pdfPigLoaded) {
        Write-Verbose "PdfPig not loaded. Cannot extract PDF text from $FilePath"
        return $null
    }

    try {
        $document = [UglyToad.PdfPig.PdfDocument]::Open($FilePath)
        
        if ($null -eq $document) {
            Write-Verbose "PdfPig returned null document for $FilePath"
            return $null
        }

        $textBuilder = [System.Text.StringBuilder]::new()
        foreach ($page in $document.GetPages()) {
            if ($null -ne $page.Text) {
                $textBuilder.Append($page.Text) | Out-Null
            }
        }

        $document.Dispose()

        $extractedText = $textBuilder.ToString()
        if ([string]::IsNullOrWhiteSpace($extractedText)) {
            Write-Verbose "No text extracted from PDF: $FilePath"
            return $null
        }

        # Truncate to 8000 characters to match existing limit.
        if ($extractedText.Length -gt 8000) {
            $extractedText = $extractedText.Substring(0, 8000)
        }

        Write-Verbose "Extracted $($extractedText.Length) characters from PDF: $FilePath"
        return $extractedText
    }
    catch {
        # Distinguish between dependency/installation errors vs. PDF content errors.
        if ($_.Exception.Message -match "Could not load file or assembly") {
            Write-Error "Missing PdfPig dependency for $FilePath : Run '.\scripts\Install-Dependencies.ps1' to install all required libraries. Error: $_"
            throw  # Stop script execution on dependency errors.
        }
        else {
            # PDF content error (scanned, encrypted, corrupted, etc).
            Write-Verbose "PDF extraction error for $FilePath : $_"
            return $null
        }
    }
}

# ---------------------------------------------------------------------------
# Helper: Read file content as plain text, with PDF support.
# Returns a string (content or placeholder), never $null.
# Returns $null only if the file type is unsupported.
# ---------------------------------------------------------------------------
function Get-FileTextContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.IO.FileInfo]$File
    )

    try {
        $extension = $File.Extension.ToLowerInvariant()

        switch ($extension) {
            { $_ -in '.txt', '.md', '.csv', '.log', '.json', '.xml', '.html', '.htm', '.yaml', '.yml' } {
                # Plain text -- read directly.
                return Get-Content -LiteralPath $File.FullName -Raw -Encoding UTF8
            }

            '.pdf' {
                # Require PdfPig for PDF extraction -- do not degrade to filename context.
                if (-not $pdfPigLoaded) {
                    Write-Verbose "PdfPig not loaded. Skipping PDF file: $($File.Name)"
                    return $null
                }
                
                $extractedText = Get-PdfTextContent -FilePath $File.FullName
                if ($null -ne $extractedText) {
                    # Extraction succeeded.
                    return $extractedText
                }
                else {
                    # Extraction failed (corrupted, scanned, encrypted, etc).
                    Write-Verbose "Could not extract text from PDF: $($File.Name) (may be scanned, encrypted, or corrupted)"
                    return $null
                }
            }

            { $_ -in '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx' } {
                # TODO: For production use, consider using the Open XML SDK or COM interop.
                # This stub returns a placeholder so the file still gets a best-effort rename.
                Write-Verbose "Office document extraction is not fully implemented. Using filename as context for: $($File.Name)"
                return "[Office document: $($File.Name)]"
            }

            default {
                # Unsupported file type -- skip it.
                Write-Verbose "Unsupported file type '$extension' for file: $($File.Name)"
                return $null
            }
        }
    }
    catch {
        Write-Verbose "Failed to read '$($File.Name)': $_"
        return $null
    }
}

# ---------------------------------------------------------------------------
# Helper: Call Azure OpenAI to propose a filename for the given content.
# Includes exponential backoff retry for rate limit errors.
# Returns a proposed filename string (without extension), or $null on failure.
# ---------------------------------------------------------------------------
function Invoke-AzureOpenAIFilenameProposal {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$FileContent,

        [Parameter(Mandatory)]
        [string]$OriginalFileName,

        [Parameter(Mandatory)]
        [string]$Endpoint,

        [Parameter(Mandatory)]
        [string]$ApiKey,

        [Parameter(Mandatory)]
        [string]$DeploymentName,

        [Parameter()]
        [ValidateRange(400, 8000)]
        [int]$MaxPromptCharacters = 1200,

        [Parameter()]
        [int]$MaxRetries = 3,

        [Parameter()]
        [int]$InitialDelaySeconds = 2
    )

    $systemPrompt = @'
You are a file-naming assistant. Your only job is to propose a clear, descriptive, human-readable
filename for a document based on its content.

Rules:
- Identify the document's subject, sender, recipient, and any reliable date you can infer.
- Propose a filename that would make sense to a human user scanning a folder.
- Do NOT include the file extension -- that will be added by the caller.
- Use title case. Use hyphens or spaces as separators (spaces are fine).
- Keep the name concise but descriptive (aim for under 80 characters).
- Avoid special characters that are invalid on Windows filesystems: \ / : * ? " < > |
- If you cannot reliably determine specific details, still propose the best descriptive name you can.
- Respond with ONLY the proposed filename -- no explanation, no punctuation at the end.

Examples of good output:
  Acme Ltd Contract Renewal Notice - 13th January 2026
  HMRC Self Assessment Tax Return 2024-25
  Dr Smith Referral Letter - Patient John Doe
  Electricity Bill - March 2025
'@

    $userPrompt = "Original filename: $OriginalFileName`n`nDocument content:`n$FileContent"

    # Truncate content to avoid exceeding token limits.
    # Low-cost default: 900 chars to keep per-file token usage and rate-limit risk lower.
    if ($userPrompt.Length -gt $MaxPromptCharacters) {
        $userPrompt = $userPrompt.Substring(0, $MaxPromptCharacters) + "`n[... content truncated ...]"
    }

    $requestBody = @{
        messages = @(
            @{ role = 'system'; content = $systemPrompt },
            @{ role = 'user';   content = $userPrompt }
        )
        max_tokens   = 60
        temperature  = 0.2
    } | ConvertTo-Json -Depth 5

    $uri = "$($Endpoint.TrimEnd('/'))/openai/deployments/$DeploymentName/chat/completions?api-version=2024-02-01"

    $retryCount = 0

    while ($retryCount -le $MaxRetries) {
        try {
            $response = Invoke-RestMethod -Uri $uri -Method Post -ContentType 'application/json' -Body $requestBody -Headers @{
                'api-key' = $ApiKey
            }
            $proposed = $response.choices[0].message.content.Trim()
            return $proposed
        }
        catch {
            $errorMessage = $_.Exception.Message
            $statusCode = $_.Exception.Response.StatusCode.value__ 2>$null

            # Check for rate limit (429 Too Many Requests or RateLimitReached error code).
            $isRateLimit = ($statusCode -eq 429) -or ($errorMessage -match 'RateLimitReached|rate.limit|quota')
            
            if ($isRateLimit) {
                if ($retryCount -lt $MaxRetries) {
                    # Extract Retry-After header (Microsoft recommended approach).
                    $retryAfterSeconds = $null
                    try {
                        $httpResponse = $_.Exception.Response
                        if ($null -ne $httpResponse -and $null -ne $httpResponse.Headers) {
                            # Try Retry-After header (seconds).
                            $retryAfterValues = $httpResponse.Headers.GetValues('Retry-After')
                            if ($null -ne $retryAfterValues -and $retryAfterValues.Count -gt 0) {
                                $retryAfterSeconds = [int]$retryAfterValues[0]
                            }
                            
                            # Try retry-after-ms header (milliseconds).
                            if ($null -eq $retryAfterSeconds) {
                                $retryAfterMsValues = $httpResponse.Headers.GetValues('retry-after-ms')
                                if ($null -ne $retryAfterMsValues -and $retryAfterMsValues.Count -gt 0) {
                                    $retryAfterSeconds = [Math]::Ceiling([int]$retryAfterMsValues[0] / 1000)
                                }
                            }
                        }
                    }
                    catch {
                        # Header parsing failed; fall back to exponential backoff.
                        Write-Verbose "Could not parse Retry-After header: $_"
                    }

                    # Use server-provided wait time if available, otherwise exponential backoff.
                    if ($null -eq $retryAfterSeconds -or $retryAfterSeconds -le 0) {
                        # For rate limits, use longer base delay (10s) since TPM quotas replenish slowly.
                        # Standard exponential backoff: 10s, 20s, 40s (capped at 60s).
                        $retryAfterSeconds = 10 * [Math]::Pow(2, $retryCount)
                        $retryAfterSeconds = [Math]::Min($retryAfterSeconds, 60)  # Cap at 60s
                        Write-Verbose "No Retry-After header found; using exponential backoff: ${retryAfterSeconds}s"
                    }
                    else {
                        Write-Verbose "Using server-provided Retry-After: ${retryAfterSeconds}s"
                    }

                    # Add jitter (±25% random variation to avoid thundering herd).
                    $jitter = (Get-Random -Minimum -0.25 -Maximum 0.25) * $retryAfterSeconds
                    $actualDelay = [Math]::Max(1, [Math]::Ceiling($retryAfterSeconds + $jitter))

                    Write-Verbose "Rate limit hit for '$OriginalFileName'. Waiting ${actualDelay}s before retry (attempt $($retryCount + 1)/$MaxRetries)..."
                    Start-Sleep -Seconds $actualDelay
                    $retryCount++
                    continue
                }
                else {
                    Write-Warning "Rate limit exceeded for '$OriginalFileName' after $MaxRetries retries."
                    Write-Warning "The script is already using low-cost defaults."
                    Write-Warning "If this persists, your Azure OpenAI quota is likely too low for current batch size."
                    return $null
                }
            }

            # Other errors (not rate limit).
            Write-Verbose "Azure OpenAI call failed for '$OriginalFileName' (attempt $($retryCount + 1)): $errorMessage"
            
            # Don't retry non-rate-limit errors.
            return $null
        }
    }

    Write-Warning "Failed to get filename proposal for '$OriginalFileName' after $MaxRetries retries."
    return $null
}

# ---------------------------------------------------------------------------
# Helper: Sanitise a filename by removing characters invalid on common filesystems.
# ---------------------------------------------------------------------------
function Get-SanitisedFileName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ProposedName
    )

    # Remove characters invalid on Windows (and problematic on Unix).
    $sanitised = $ProposedName -replace '[\\/:*?"<>|]', ''

    # Remove control characters (ASCII < 32) and newlines.
    $sanitised = ($sanitised.ToCharArray() | Where-Object { [int]$_ -ge 32 }) -join ''

    # Normalise all whitespace (tabs, newlines, multiple spaces) to a single space.
    $sanitised = $sanitised -replace '\s+', ' '

    # Collapse multiple dashes, then trim whitespace and trailing dots.
    $sanitised = $sanitised -replace '-{2,}', '-'
    $sanitised = $sanitised.Trim().TrimEnd('.')

    if ([string]::IsNullOrWhiteSpace($sanitised)) {
        return $null
    }

    # Handle Windows reserved device names (CON, PRN, AUX, NUL, COM1..COM9, LPT1..LPT9)
    $reserved = @('CON','PRN','AUX','NUL') + @(1..9 | ForEach-Object {"COM$_","LPT$_"})
    $base = $sanitised
    $suffixPattern = '-\d+$'
    $suffix = ''
    if ($sanitised -match $suffixPattern) {
        $suffix = $Matches[0]
        $base = $sanitised.Substring(0, $sanitised.Length - $suffix.Length)
    }
    if ($reserved -contains $base.ToUpperInvariant()) {
        $base = "${base}_file"
    }
    $sanitised = $base + $suffix

    # Truncate to fit within Windows filename limits (255 chars for filename, 260 for full path).
    $maxLength = 255
    if ($sanitised.Length -gt $maxLength) {
        $baseLength = $maxLength - $suffix.Length
        $sanitised = $sanitised.Substring(0, $baseLength) + $suffix
    }
    return $sanitised
}

# ---------------------------------------------------------------------------
# Helper: Resolve a collision-free destination path.
# If the proposed path already exists, appends -1, -2, etc.
# ---------------------------------------------------------------------------
function Resolve-UniqueFilePath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Directory,

        [Parameter(Mandatory)]
        [string]$BaseName,

        [Parameter(Mandatory)]
        [string]$Extension
    )

    $candidate = Join-Path $Directory "$BaseName$Extension"
    if (-not (Test-Path -LiteralPath $candidate)) {
        return $candidate
    }

    $counter = 1
    do {
        $candidate = Join-Path $Directory "$BaseName-$counter$Extension"
        $counter++
    } while (Test-Path -LiteralPath $candidate)

    return $candidate
}

# ---------------------------------------------------------------------------
# Main processing
# ---------------------------------------------------------------------------

# Validate Azure credentials.
if ([string]::IsNullOrWhiteSpace($AzureOpenAIEndpoint)) {
    throw 'Azure OpenAI endpoint is required. Pass -AzureOpenAIEndpoint or set the AZURE_OPENAI_ENDPOINT environment variable.'
}
if ([string]::IsNullOrWhiteSpace($AzureOpenAIKey)) {
    throw 'Azure OpenAI API key is required. Pass -AzureOpenAIKey or set the AZURE_OPENAI_KEY environment variable.'
}

$resolvedFolder = Resolve-Path -LiteralPath $FolderPath
Write-Output "Scanning folder: $resolvedFolder"

$files = Get-ChildItem -LiteralPath $resolvedFolder -File

if ($files.Count -eq 0) {
    Write-Output 'No files found in the specified folder.'
    return
}

Write-Output "Found $($files.Count) file(s). Processing..."

$countRenamed  = 0
$countSkipped  = 0
$skippedFiles  = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($file in $files) {
    Write-Verbose "Processing: $($file.Name)"

    # Step 1: Read content.
    $content = Get-FileTextContent -File $file
    if ($null -eq $content) {
        $skippedFiles.Add([PSCustomObject]@{ Name = $file.Name; Reason = 'Unsupported or unreadable file type' })
        $countSkipped++
        Write-Output "  SKIPPED  $($file.Name) -- unsupported or unreadable"
        continue
    }

    # Step 2: Ask Azure AI for a proposed filename.
    $proposed = Invoke-AzureOpenAIFilenameProposal `
        -FileContent $content `
        -OriginalFileName $file.Name `
        -Endpoint $AzureOpenAIEndpoint `
        -ApiKey $AzureOpenAIKey `
        -DeploymentName $DeploymentName `
        -MaxPromptCharacters $MaxPromptCharacters

    if ($null -eq $proposed) {
        $skippedFiles.Add([PSCustomObject]@{ Name = $file.Name; Reason = 'Azure AI call failed' })
        $countSkipped++
        Write-Output "  SKIPPED  $($file.Name) -- Azure AI call failed"
        continue
    }

    # Pace requests to avoid bursting into TPM/RPM limits (Microsoft recommended approach).
    if ($RequestThrottleSeconds -gt 0) {
        Write-Verbose "Throttling: waiting ${RequestThrottleSeconds}s before next API call..."
        Start-Sleep -Seconds $RequestThrottleSeconds
    }

    # Step 3: Sanitise the proposed name.
    $sanitised = Get-SanitisedFileName -ProposedName $proposed
    if ($null -eq $sanitised) {
        $skippedFiles.Add([PSCustomObject]@{ Name = $file.Name; Reason = 'AI returned an unusable filename' })
        $countSkipped++
        Write-Output "  SKIPPED  $($file.Name) -- AI returned an unusable filename"
        continue
    }

    # Step 4: Resolve a unique destination path.
    $destinationPath = Resolve-UniqueFilePath `
        -Directory $file.DirectoryName `
        -BaseName $sanitised `
        -Extension $file.Extension

    $newName = Split-Path $destinationPath -Leaf

    # Step 5: Rename (or preview in -WhatIf mode).
    if ($PSCmdlet.ShouldProcess($file.Name, "Rename to '$newName'")) {
        try {
            Rename-Item -LiteralPath $file.FullName -NewName $newName -ErrorAction Stop
            $countRenamed++
            Write-Output "  RENAMED  $($file.Name)  ->  $newName"
        }
        catch {
            $reason = "Rename failed: $($_.Exception.Message)"
            $skippedFiles.Add([PSCustomObject]@{ Name = $file.Name; Reason = $reason })
            $countSkipped++
            Write-Output "  SKIPPED  $($file.Name) -- $reason"
        }
    }
    else {
        # -WhatIf path -- ShouldProcess already printed the WhatIf message.
        Write-Output "  PROPOSED $($file.Name)  ->  $newName"
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Output ''
Write-Output '-------------------------------------'
Write-Output ' Summary'
Write-Output '-------------------------------------'
Write-Output " Files scanned : $($files.Count)"
Write-Output " Files renamed : $countRenamed"
Write-Output " Files skipped : $countSkipped"

if ($skippedFiles.Count -gt 0) {
    Write-Output ''
    Write-Output ' Skipped files:'
    foreach ($skipped in $skippedFiles) {
        Write-Output "   * $($skipped.Name) -- $($skipped.Reason)"
    }
}
Write-Output '-------------------------------------'
