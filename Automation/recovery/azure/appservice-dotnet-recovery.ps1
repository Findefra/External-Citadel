<#
.SYNOPSIS
    Azure App Service (.NET) remediation script.
    Checks status, scans for recent issues, restarts the app (or instance), or swaps slots.

.PARAMETER ResourceGroup
    Resource group containing the Web App.

.PARAMETER WebAppName
    Name of the Azure Web App.

.PARAMETER Action
    Status | Restart | RestartInstance | Swap | Diagnose  (default: Diagnose)

.PARAMETER Slot
    Deployment slot name (e.g. staging). Required for Swap; optional for other actions.

.PARAMETER InstanceId
    Specific instance ID for RestartInstance (from az webapp list-instances).

.PARAMETER DryRun
    Show what would be done without changing Azure resources.

.PARAMETER LogDir
    Directory for local log files.

.EXAMPLE
    .\appservice-dotnet-recovery.ps1 -ResourceGroup rg-web -WebAppName myapp -Action Restart

.EXAMPLE
    .\appservice-dotnet-recovery.ps1 -ResourceGroup rg-web -WebAppName myapp -Action Swap -Slot staging
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $true)]
    [string]$WebAppName,

    [ValidateSet('Status', 'Restart', 'RestartInstance', 'Swap', 'Diagnose')]
    [string]$Action = 'Diagnose',

    [string]$Slot,

    [string]$InstanceId,

    [switch]$DryRun,

    [string]$LogDir = 'C:\Logs\AppErrorRecovery'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------
if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$LogFile = Join-Path $LogDir ("azure-appservice-dotnet_{0:yyyyMMdd}.log" -f (Get-Date))

function Write-Log {
    param(
        [Parameter(Mandatory)][ValidateSet('INFO', 'WARN', 'ERROR', 'DRY-RUN')]
        [string]$Level,
        [Parameter(Mandatory)][string]$Message
    )
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$ts] [$Level] $Message"
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARN'    { 'Yellow' }
        'ERROR'   { 'Red' }
        'DRY-RUN' { 'Cyan' }
    }
    Write-Host $line -ForegroundColor $color
    Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8
}

function Test-AzCli {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw 'Azure CLI (az) is required. Install and run az login.'
    }
}

function Invoke-Az {
    param([string[]]$AzArgs)
    Write-Log -Level 'INFO' -Message ("az {0}" -f ($AzArgs -join ' '))
    & az @AzArgs 2>&1
}

# ------------------------------------------------------------
# Actions
# ------------------------------------------------------------
function Get-AppStatus {
    Write-Log -Level 'INFO' -Message "Fetching status for $WebAppName in $ResourceGroup"
    $showArgs = @('webapp', 'show', '-g', $ResourceGroup, '-n', $WebAppName, '-o', 'json')
    if ($Slot) { $showArgs += @('--slot', $Slot) }
    $json = Invoke-Az -AzArgs $showArgs | Out-String
    if ($LASTEXITCODE -ne 0) {
        Write-Log -Level 'ERROR' -Message "Failed to get webapp status"
        return
    }
    $app = $json | ConvertFrom-Json
    Write-Log -Level 'INFO' -Message "State: $($app.state) | Kind: $($app.kind) | Default host: $($app.defaultHostName)"
    Write-Log -Level 'INFO' -Message "HTTPS Only: $($app.httpsOnly) | Client affinity: $($app.clientAffinityEnabled)"

    $instArgs = @('webapp', 'list-instances', '-g', $ResourceGroup, '-n', $WebAppName, '-o', 'table')
    if ($Slot) { $instArgs += @('--slot', $Slot) }
    Write-Log -Level 'INFO' -Message 'Instances:'
    Invoke-Az -AzArgs $instArgs | ForEach-Object { Write-Log -Level 'INFO' -Message "  $_" }
}

function Invoke-Diagnose {
    Get-AppStatus
    Write-Log -Level 'INFO' -Message 'Downloading recent application logs (if log collection is enabled)...'
    $downloadArgs = @('webapp', 'log', 'download', '-g', $ResourceGroup, '-n', $WebAppName, '--log-file', (Join-Path $LogDir "webapp-logs-$WebAppName.zip"))
    if ($Slot) { $downloadArgs += @('--slot', $Slot) }
    if ($DryRun) {
        Write-Log -Level 'DRY-RUN' -Message ("Would run: az {0}" -f ($downloadArgs -join ' '))
    } else {
        try {
            Invoke-Az -AzArgs $downloadArgs | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Log -Level 'INFO' -Message "Logs saved under $LogDir (zip). Review for .NET exceptions, 5xx, startup failures."
            } else {
                Write-Log -Level 'WARN' -Message 'Log download failed or logging not configured. Enable App Service logs / use Log stream or Application Insights.'
            }
        } catch {
            Write-Log -Level 'WARN' -Message $_.Exception.Message
        }
    }
    Write-Log -Level 'INFO' -Message 'Manual checks: Portal → Diagnose and solve problems | Application Insights failures | Kudu VFS/logs'
}

function Invoke-Restart {
    if ($DryRun) {
        Write-Log -Level 'DRY-RUN' -Message "Would restart webapp $WebAppName (slot=$Slot)"
        return
    }
    $args = @('webapp', 'restart', '-g', $ResourceGroup, '-n', $WebAppName)
    if ($Slot) { $args += @('--slot', $Slot) }
    Write-Log -Level 'INFO' -Message "Restarting App Service $WebAppName..."
    Invoke-Az -AzArgs $args | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Log -Level 'INFO' -Message 'Restart requested successfully. Allow cold-start time for .NET.'
    } else {
        Write-Log -Level 'ERROR' -Message 'Restart failed.'
    }
}

function Invoke-RestartInstance {
    if ([string]::IsNullOrWhiteSpace($InstanceId)) {
        Write-Log -Level 'ERROR' -Message 'RestartInstance requires -InstanceId. List with: az webapp list-instances -g <rg> -n <app>'
        return
    }
    if ($DryRun) {
        Write-Log -Level 'DRY-RUN' -Message "Would restart instance $InstanceId on $WebAppName"
        return
    }
    $args = @('webapp', 'restart', '-g', $ResourceGroup, '-n', $WebAppName, '--instance-id', $InstanceId)
    if ($Slot) { $args += @('--slot', $Slot) }
    Write-Log -Level 'INFO' -Message "Restarting instance $InstanceId..."
    Invoke-Az -AzArgs $args | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Log -Level 'INFO' -Message 'Instance restart requested.'
    } else {
        Write-Log -Level 'ERROR' -Message 'Instance restart failed.'
    }
}

function Invoke-Swap {
    if ([string]::IsNullOrWhiteSpace($Slot)) {
        Write-Log -Level 'ERROR' -Message 'Swap requires -Slot (e.g. staging).'
        return
    }
    if ($DryRun) {
        Write-Log -Level 'DRY-RUN' -Message "Would swap slot '$Slot' with production on $WebAppName"
        return
    }
    Write-Log -Level 'INFO' -Message "Swapping slot '$Slot' ↔ production for $WebAppName (typical rollback/promote path for .NET deploys)..."
    $args = @('webapp', 'deployment', 'slot', 'swap', '-g', $ResourceGroup, '-n', $WebAppName, '--slot', $Slot, '--target-slot', 'production')
    Invoke-Az -AzArgs $args | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Log -Level 'INFO' -Message 'Slot swap completed.'
    } else {
        Write-Log -Level 'ERROR' -Message 'Slot swap failed. Check slot names and permissions.'
    }
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
Write-Log -Level 'INFO' -Message '============================================================'
Write-Log -Level 'INFO' -Message "Azure App Service .NET recovery | app=$WebAppName | rg=$ResourceGroup | action=$Action | dry-run=$DryRun"
Write-Log -Level 'INFO' -Message "Log file: $LogFile"

try {
    Test-AzCli
    switch ($Action) {
        'Status'          { Get-AppStatus }
        'Diagnose'        { Invoke-Diagnose }
        'Restart'         { Invoke-Restart }
        'RestartInstance' { Invoke-RestartInstance }
        'Swap'            { Invoke-Swap }
    }
} catch {
    Write-Log -Level 'ERROR' -Message $_.Exception.Message
    exit 1
}

Write-Log -Level 'INFO' -Message 'Azure App Service .NET recovery finished'
Write-Log -Level 'INFO' -Message '============================================================'
