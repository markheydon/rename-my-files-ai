<#
.SYNOPSIS
    Deploys the Azure resources required by the Rename My Files utility.

.DESCRIPTION
    Deploy-RenameMyFiles.ps1 provisions all necessary Azure resources for the Rename My Files
    utility, including an Azure OpenAI resource and a GPT-4o mini model deployment.

    The script uses the Bicep template in the infra/ folder. On completion it outputs the
    Azure OpenAI endpoint and API key so you can configure Rename-MyFiles.ps1.

.PARAMETER SubscriptionId
    The Azure subscription ID in which to deploy resources.

.PARAMETER ResourceGroupName
    The name of the resource group to create (or reuse if it already exists).
    Defaults to 'rg-rename-my-files'.

.PARAMETER Location
    The Azure region for the resources. Defaults to 'uksouth'.
    Note: Azure OpenAI is not available in all regions. See:
    https://learn.microsoft.com/azure/ai-services/openai/concepts/models#model-summary-table-and-region-availability

.EXAMPLE
    .\Deploy-RenameMyFiles.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000"

    Deploys resources with default resource group name and location.

.EXAMPLE
    .\Deploy-RenameMyFiles.ps1 `
        -SubscriptionId "00000000-0000-0000-0000-000000000000" `
        -ResourceGroupName "rg-myfiles-prod" `
        -Location "uksouth"

    Deploys resources to UK South in a custom resource group.

.NOTES
    Requires PowerShell 7.2 or later and the Azure CLI.
    Install Azure CLI from: https://learn.microsoft.com/cli/azure/install-azure-cli
    Bicep support is built into Azure CLI (no separate installation required).
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory, HelpMessage = 'Azure subscription ID.')]
    [ValidateNotNullOrEmpty()]
    [string]$SubscriptionId,

    [Parameter(HelpMessage = 'Resource group name. Defaults to rg-rename-my-files.')]
    [ValidateNotNullOrEmpty()]
    [string]$ResourceGroupName = 'rg-rename-my-files',

    [Parameter(HelpMessage = 'Azure region. Defaults to uksouth.')]
    [ValidateNotNullOrEmpty()]
    [string]$Location = 'uksouth'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$bicepTemplatePath = Join-Path $PSScriptRoot '../infra' 'main.bicep'

if (-not (Test-Path -LiteralPath $bicepTemplatePath)) {
    throw "Bicep template not found at: $bicepTemplatePath"
}

Write-Output 'Rename My Files - Azure Deployment'
Write-Output '------------------------------------'
Write-Output " Subscription  : $SubscriptionId"
Write-Output " Resource Group: $ResourceGroupName"
Write-Output " Location      : $Location"
Write-Output ''

# Check Azure CLI is installed.
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "Azure CLI not found. Install from: https://learn.microsoft.com/cli/azure/install-azure-cli"
}

# Connect / set subscription.
try {
    # Check current Azure CLI context.
    $accountJson = az account show 2>$null
    $currentAccount = if ($accountJson) { $accountJson | ConvertFrom-Json } else { $null }
    
    if (-not $currentAccount -or $currentAccount.id -ne $SubscriptionId) {
        if (-not $currentAccount) {
            Write-Output 'Not logged in to Azure. Initiating login...'
            az login --use-device-code | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "Azure login failed."
            }
        }
        
        Write-Output "Setting subscription to: $SubscriptionId"
        az account set --subscription $SubscriptionId 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to set subscription. Verify subscription ID is correct and you have access."
        }
    }
    
    Write-Output "Using subscription: $SubscriptionId"
}
catch {
    throw "Failed to authenticate with Azure: $_"
}

# Create resource group if it does not exist.
if ($PSCmdlet.ShouldProcess($ResourceGroupName, 'Create resource group')) {
    $rgJson = az group show --name $ResourceGroupName 2>$null
    $rg = if ($rgJson) { $rgJson | ConvertFrom-Json } else { $null }
    
    if (-not $rg) {
        Write-Output "Creating resource group '$ResourceGroupName' in '$Location'..."
        az group create --name $ResourceGroupName --location $Location --output json | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create resource group."
        }
        Write-Output 'Resource group created.'
    }
    else {
        Write-Output "Resource group '$ResourceGroupName' already exists."
    }
}

# Deploy Bicep template.
if ($PSCmdlet.ShouldProcess($ResourceGroupName, 'Deploy Bicep template')) {
    Write-Output 'Deploying Azure resources (this may take a few minutes)...'

    $deploymentName = "rename-my-files-$(Get-Date -Format 'yyyyMMddHHmmss')"

    function Invoke-RmfDeployment {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory)]
            [bool]$RestoreOpenAI
        )

        $restoreValue = if ($RestoreOpenAI) { 'true' } else { 'false' }

        $result = az deployment group create `
            --name $deploymentName `
            --resource-group $ResourceGroupName `
            --template-file $bicepTemplatePath `
            --parameters location=$Location restoreOpenAI=$restoreValue `
            --only-show-errors `
            --output json 2>&1

        return [PSCustomObject]@{
            ExitCode = $LASTEXITCODE
            Output   = ($result | Out-String)
        }
    }

    try {
        # First attempt: normal deployment (active resources should not use restore=true).
        $deployResult = Invoke-RmfDeployment -RestoreOpenAI $false

        # Retry only when Azure reports a soft-deleted resource that requires restore.
        if ($deployResult.ExitCode -ne 0 -and $deployResult.Output -match 'FlagMustBeSetForRestore') {
            Write-Warning 'Soft-deleted Azure OpenAI resource detected. Retrying deployment with restore enabled...'
            $deployResult = Invoke-RmfDeployment -RestoreOpenAI $true
        }

        if ($deployResult.ExitCode -ne 0) {
            throw "Deployment command failed. Azure CLI output: $($deployResult.Output.Trim())"
        }

        $deploymentJson = $deployResult.Output

        # Azure CLI can occasionally prepend warning text to output; keep only JSON lines.
        $jsonLines = $deploymentJson -split [Environment]::NewLine | Where-Object {
            $_ -and $_.Trim() -ne '' -and $_ -notmatch '^\s*WARNING:'
        }
        $cleanJson = ($jsonLines -join [Environment]::NewLine).Trim()

        try {
            $deployment = $cleanJson | ConvertFrom-Json
        }
        catch {
            throw "Failed to parse deployment JSON output. Raw Azure CLI output: $deploymentJson"
        }

        if ($deployment.properties.provisioningState -ne 'Succeeded') {
            throw "Deployment finished with state: $($deployment.properties.provisioningState)"
        }

        Write-Output 'Deployment succeeded!'
        Write-Output ''
        Write-Output '------------------------------------'
        Write-Output ' Next steps'
        Write-Output '------------------------------------'
        Write-Output ' Set these environment variables before running Rename-MyFiles.ps1:'
        Write-Output ''

        $endpoint = $deployment.properties.outputs.openAIEndpoint.value
        Write-Output "  `$env:AZURE_OPENAI_ENDPOINT = '$endpoint'"

        Write-Output ''
        Write-Output ' To retrieve your API key, run:'

        $openAIName = $deployment.properties.outputs.openAIResourceName.value
        Write-Output "  az cognitiveservices account keys list --name '$openAIName' --resource-group '$ResourceGroupName' --query key1 --output tsv"
        Write-Output ''
        Write-Output ' Then set:'
        Write-Output '  $env:AZURE_OPENAI_KEY = "<key from above>"'
        Write-Output ''
        Write-Output ' Run the rename script:'
        Write-Output '  .\scripts\Rename-MyFiles.ps1 -FolderPath "C:\YourFolder"'
        Write-Output '------------------------------------'
    }
    catch {
        Write-Error "Deployment failed: $_"
        throw
    }
}
