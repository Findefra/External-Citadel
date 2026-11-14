<#
.SYNOPSIS
    Scans application / Windows Event logs for errors and restarts the service
    plus any defined dependent services.

.DESCRIPTION
    Windows equivalent of the Linux app-error-recovery.sh script.
    - Checks Application and System event logs (or a custom log file)
    - Looks for configurable error patterns in the recent time window
    - Restarts the primary Windows service
    - Restarts any dependent services listed in the configuration

.PARAMETER DryRun
    Show what would be done without making changes.

.PARAMETER Minutes
    How far back to look in the logs (default: 30).

.PARAMETER Service
    Optional list of specific services to check. If omitted, all services
    defined in $ServiceDeps are checked.

.EXAMPLE
    .\App-Error-Recovery.ps1

.EXAMPLE
    .\App-Error-Recovery.ps1 -DryRun

.EXAMPLE
    .\App-Error-Recovery.ps1 -Minutes 15 -Service "PaymentApi","OrderService"
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [int]$Minutes = 30,
    [string[]]$Service
)

# ------------------------------------------------------------
# CONFIGURATION - Edit this section for your environment
# ------------------------------------------------------------

# Error patterns (case-insensitive regex fragments)
$ErrorPatterns = @(
    "error",
    "exception",
    "fatal",
    "critical",
    "panic",
    "traceback",
    "out of memory",
    "connection refused",
    "timeout",
    "failed to"
)

# Primary service -> comma-separated list of dependent services
# Use the exact Windows service name (Get-Service | Select Name)
$ServiceDeps = @{
    "PaymentApi"          = @("PaymentWorker", "PaymentCache")
    "OrderService"        = @("OrderWorker", "InventorySync")
    "AuthService"         = @("SessionStore")
    "NotificationService" = @()
    # Add more applications here
}

# Optional: path to a custom application log file per service
# If set, the script will also scan that file in addition to Event Log
$CustomLogs = @{
    # "PaymentApi" = "C:\Logs\PaymentApi\app.log"
}

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

function Write-Log {
    param(
        [string]$Level,
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

function Test-ServiceHasErrors {
    param(
        [string]$ServiceName,
        [int]$LookbackMinutes
    )

    $startTime = (Get-Date).AddMinutes(-$LookbackMinutes)
    $pattern   = ($ErrorPatterns -join "|")

    # 1. Check Windows Event Log (Application + System)
    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName   = 'Application', 'System'
            StartTime = $startTime
            Level     = 1, 2, 3   # Critical, Error, Warning
        } -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Message -match $pattern -or
            $_.ProviderName -like "*$ServiceName*"
        }

        if ($events) {
            return $true
        }
    }
    catch {
        # Some systems restrict event log access; continue to custom log
    }

    # 2. Optional custom log file
    if ($CustomLogs.ContainsKey($ServiceName) -and (Test-Path $CustomLogs[$ServiceName])) {
        $content = Get-Content -Path $CustomLogs[$ServiceName] -Tail 500 -ErrorAction SilentlyContinue
        if ($content -match $pattern) {
            return $true
        }
    }

    return $false
}

function Restart-WindowsService {
    param(
        [string]$Name
    )

    if ($DryRun) {
        Write-Log "DRY-RUN" "Would restart service: $Name"
        return
    }

    Write-Log "INFO" "Restarting service: $Name"

    try {
        $svc = Get-Service -Name $Name -ErrorAction Stop

        if ($svc.Status -eq 'Running') {
            Restart-Service -Name $Name -Force -ErrorAction Stop
        }
        else {
            Start-Service -Name $Name -ErrorAction Stop
        }

        Start-Sleep -Seconds 3

        $svc.Refresh()
        if ($svc.Status -eq 'Running') {
            Write-Log "INFO" "$Name is running after restart"
        }
        else {
            Write-Log "WARN" "$Name did not reach Running state (current: $($svc.Status))"
        }
    }
    catch {
        Write-Log "ERROR" "Failed to restart $Name : $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

Write-Log "INFO" "Starting application error recovery scan (lookback: ${Minutes}m)"
if ($DryRun) {
    Write-Log "INFO" "Running in DRY-RUN mode – no changes will be made"
}

$targets = if ($Service -and $Service.Count -gt 0) {
    $Service
} else {
    $ServiceDeps.Keys
}

$restarted = [System.Collections.Generic.List[string]]::new()

foreach ($svcName in $targets) {
    if (-not $ServiceDeps.ContainsKey($svcName)) {
        Write-Log "WARN" "Service '$svcName' is not defined in ServiceDeps – skipping"
        continue
    }

    Write-Log "INFO" "Checking logs for: $svcName"

    if (Test-ServiceHasErrors -ServiceName $svcName -LookbackMinutes $Minutes) {
        Write-Log "WARN" "Errors detected for $svcName"

        # Restart primary
        Restart-WindowsService -Name $svcName
        $restarted.Add($svcName)

        # Restart dependents
        $deps = $ServiceDeps[$svcName]
        foreach ($dep in $deps) {
            if ([string]::IsNullOrWhiteSpace($dep)) { continue }
            Write-Log "INFO" "Restarting dependent service of ${svcName}: $dep"
            Restart-WindowsService -Name $dep
            $restarted.Add($dep)
        }
    }
    else {
        Write-Log "INFO" "No recent errors found for $svcName"
    }
}

Write-Host ""
Write-Log "INFO" "===== Recovery Summary ====="
if ($restarted.Count -eq 0) {
    Write-Log "INFO" "No services required a restart"
}
else {
    Write-Log "INFO" "Services restarted: $($restarted -join ', ')"
}

if ($DryRun) {
    Write-Log "INFO" "Dry-run complete. Re-run without -DryRun to apply changes."
}
