<#
.SYNOPSIS
    Installs optional dependencies (PdfPig) required for PDF text extraction.

.DESCRIPTION
    This script downloads the UglyToad.PdfPig NuGet package directly from NuGet.org
    and extracts the DLL to a local 'lib' folder. No .NET SDK required.

    Requires: PowerShell 7.2+ and internet connection.

.PARAMETER Version
    Version of PdfPig to install. Defaults to 0.1.13 (latest stable as of March 2026).

.EXAMPLE
    .\Install-Dependencies.ps1

    Downloads and installs PdfPig v0.1.13 to ./lib/

.EXAMPLE
    .\Install-Dependencies.ps1 -Version 0.1.12

    Downloads and installs a specific version of PdfPig.

.NOTES
    Run this script once. After successful installation, Rename-MyFiles.ps1 will
    automatically use PdfPig for PDF text extraction.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$Version = '0.1.13'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Output "=========================================="
Write-Output "Installing PDF Support (PdfPig)"
Write-Output "=========================================="
Write-Output ""

# Create lib folder if it doesn't exist.
$libFolder = Join-Path $PSScriptRoot 'lib'
if (-not (Test-Path -LiteralPath $libFolder)) {
    New-Item -ItemType Directory -Path $libFolder -Force | Out-Null
    Write-Output "✓ Created lib folder: $libFolder"
}

# Download .nupkg from NuGet.org using v2 API (package ID is "PdfPig", not "UglyToad.PdfPig").
Write-Output "Downloading PdfPig v$Version from NuGet.org..."

$nupkgUrl = "https://www.nuget.org/api/v2/package/PdfPig/$Version"
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "pdfpig-install-$([guid]::NewGuid())"
$nupkgFile = Join-Path $tempDir "pdfpig.nupkg"

New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Download .nupkg (which is just a zip file).
    Invoke-WebRequest -Uri $nupkgUrl -OutFile $nupkgFile -UseBasicParsing
    Write-Output "✓ Downloaded package"
    
    # Extract .nupkg (rename to .zip and expand).
    $zipFile = Join-Path $tempDir "pdfpig.zip"
    Copy-Item -LiteralPath $nupkgFile -Destination $zipFile
    
    $extractPath = Join-Path $tempDir "extracted"
    Expand-Archive -Path $zipFile -DestinationPath $extractPath -Force
    Write-Output "✓ Extracted package"
    
    # Find the DLL for the appropriate framework (.NET 6.0 or .NET Standard 2.0).
    $dllPaths = @(
        "lib/net6.0/UglyToad.PdfPig.dll",
        "lib/netstandard2.0/UglyToad.PdfPig.dll",
        "lib/net5.0/UglyToad.PdfPig.dll"
    )
    
    $dllSource = $null
    foreach ($relativePath in $dllPaths) {
        $candidatePath = Join-Path $extractPath $relativePath
        if (Test-Path -LiteralPath $candidatePath) {
            $dllSource = $candidatePath
            Write-Output "✓ Found DLL: $relativePath"
            break
        }
    }
    
    if ($null -eq $dllSource) {
        throw "PdfPig DLL not found in package. Package structure may have changed."
    }
    
    # Copy all DLLs from the source directory to lib folder (including transitive dependencies).
    $sourceDir = Split-Path $dllSource
    
    try {
        $dlls = @(Get-ChildItem "$sourceDir\*.dll")
    }
    catch {
        throw "Failed to enumerate DLLs in $sourceDir : $_"
    }
    
    if ($dlls.Count -eq 0) {
        throw "No DLLs found in $sourceDir"
    }
    
    foreach ($dll in $dlls) {
        $destination = Join-Path $libFolder $dll.Name
        try {
            Copy-Item -LiteralPath $dll.FullName -Destination $destination -Force -ErrorAction Stop
            Write-Output "  ✓ Installed: $($dll.Name)"
        }
        catch {
            if ($_.Exception.Message -match "because it is being used by another process") {
                Write-Output "  → Skipped: $($dll.Name) (already in use - will use existing version)"
            }
            else {
                throw
            }
        }
    }
    
    Write-Output "✓ Installed $($dlls.Count) DLL(s) total"
    
    Write-Output ""
    Write-Output "=========================================="
    Write-Output "✓ Installation Complete"
    Write-Output "=========================================="
    Write-Output ""
    Write-Output "PDF text extraction is now enabled."
    Write-Output ""
    Write-Output "Next steps:"
    Write-Output "  1. Run Rename-MyFiles.ps1 with PDF files"
    Write-Output "  2. Add -Verbose to confirm PdfPig loaded:"
    Write-Output "     .\Rename-MyFiles.ps1 -FolderPath C:\Docs -Verbose"
    Write-Output ""
}
catch {
    Write-Error "Installation failed: $_"
    Write-Output ""
    Write-Output "Troubleshooting:"
    Write-Output "  • Check your internet connection"
    Write-Output "  • Try a different version: .\Install-Dependencies.ps1 -Version 0.1.12"
    Write-Output "  • Check available versions: https://www.nuget.org/packages/PdfPig/"
    Write-Output "  • Check NuGet.org status: https://status.nuget.org/"
    exit 1
}
finally {
    # Clean up temp directory.
    if (Test-Path -LiteralPath $tempDir) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
