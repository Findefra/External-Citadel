<#
.SYNOPSIS
    Windows-native application error recovery script.
    Scans Event Logs (and optional custom log files) for errors, then restarts
    the affected Windows service and any configured dependent services.

.DESCRIPTION
    100% PowerShell implementation designed for Windows Server environments.
    Uses Get-WinEvent, Get-Service, and Restart-Service.
    Supports dry-run, configurable lookback, and explicit service targeting.

.PARAMETER DryRun
    Show actions without making changes.

.PARAMETER Minutes
    Minutes of Event Log history to examine (default: 30).

.PARAMETER Service
    One or more specific service names to check. If omitted, all services
    defined in $ServiceDeps are processed.

.EXAMPLE
    .\App-Error-Recovery.ps1 -DryRun

.EXAMPLE
    .\App-Error-Recovery.ps1 -Minutes 15 -Service "PaymentApi","OrderService"

.NOTES
    Run elevated (Administrator) for reliable service control and full Event Log access.
    Edit the CONFIGURATION section before first use.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$DryRun,
    [ValidateRange(1, 1440)]
    [int]$Minutes = 30,
    [string[]]$Service
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------
# CONFIGURATION - Customize for your environment
# ------------------------------------------------------------

# Case-insensitive regex fragments that indicate a problem
$ErrorPatterns = @(
    'error',
    'exception',
    'fatal',
    'critical',
    'panic',
    'traceback',
    'out of memory',
    'connection refused',
    'timeout',
    'failed to',
    'unhandled',
    'stack overflow'
)

# Primary Windows service name -> array of dependent service names
# Use the exact Name property from Get-Service
$ServiceDeps = [ordered]@{
    'PaymentApi'          = @('PaymentWorker', 'PaymentCache')
    'OrderService'        = @('OrderWorker', 'InventorySync')
    'AuthService'         = @('SessionStore')
    'NotificationService' = @()
    # Add more entries as needed
}

# Optional custom application log files (scanned in addition to Event Log)
$CustomLogs = @{
    # 'PaymentApi' = 'C:\Logs\PaymentApi\app.log'
}

# Event Log names to query
$EventLogNames = @('Application', 'System')

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

function Write-Log {
    param(
        [Parameter(Mandatory)][ValidateSet('INFO','WARN','ERROR','DRY-RUN')]
        [string]$Level,
        [Parameter(Mandatory)][string]$Message
    )
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARN'    { 'Yellow' }
        'ERROR'   { 'Red' }
        'DRY-RUN' { 'Cyan' }
    }
    Write-Host "[$ts] [$Level] $Message" -ForegroundColor $color
}

function Test-ServiceHasErrors {
    param(
        [string]$ServiceName,
        [int]$LookbackMinutes
    )

    $startTime = (Get-Date).AddMinutes(-$LookbackMinutes)
    $pattern   = ($ErrorPatterns -join '|')

    # --- Windows Event Log ---
    try {
        $filter = @{
            LogName   = $EventLogNames
            StartTime = $startTime
            Level     = 1, 2, 3   # Critical, Error, Warning
        }

        $events = Get-WinEvent -FilterHashtable $filter -ErrorAction SilentlyContinue |
            Where-Object {
                ($_.Message -match $pattern) -or
                ($_.ProviderName -like "*$ServiceName*") -or
                ($_.Id -in 1000, 1001, 1002)  # common application error event IDs
            }

        if ($events -and $events.Count -gt 0) {
            Write-Log -Level 'WARN' -Message ("Found {0} matching event(s) for {1}" -f $events.Count, $ServiceName)
            return $true
        }
    }
    catch {
        Write-Log -Level 'WARN' -Message "Event Log query limited or failed: $($_.Exception.Message)"
    }

    # --- Optional custom log file ---
    if ($CustomLogs.ContainsKey($ServiceName)) {
        $logPath = $CustomLogs[$ServiceName]
        if (Test-Path -LiteralPath $logPath) {
            $recent = Get-Content -LiteralPath $logPath -Tail 800 -ErrorAction SilentlyContinue |
                      Select-String -Pattern $pattern -SimpleMatch:$false
            if ($recent) {
                Write-Log -Level 'WARN' -Message "Errors found in custom log: $logPath"
                return $true
            }
        }
    }

    return $false
}

function Restart-WindowsServiceSafe {
    param([string]$Name)

    if ($DryRun) {
        Write-Log -Level 'DRY-RUN' -Message "Would restart service: $Name"
        return
    }

    try {
        $svc = Get-Service -Name $Name -ErrorAction Stop
        Write-Log -Level 'INFO' -Message "Restarting service: $Name (current status: $($svc.Status))"

        if ($svc.Status -eq 'Running') {
            Restart-Service -Name $Name -Force -ErrorAction Stop
        }
        else {
            Start-Service -Name $Name -ErrorAction Stop
        }

        # Wait and verify
        $timeout = 30
        $elapsed = 0
        do {
            Start-Sleep -Seconds 2
            $elapsed += 2
            $svc.Refresh()
        } while ($svc.Status -ne 'Running' -and $elapsed -lt $timeout)

        if ($svc.Status -eq 'Running') {
            Write-Log -Level 'INFO' -Message "$Name is Running after restart"
        }
        else {
            Write-Log -Level 'WARN' -Message "$Name did not reach Running state (status: $($svc.Status))"
        }
    }
    catch {
        Write-Log -Level 'ERROR' -Message "Failed to restart '$Name': $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------

Write-Log -Level 'INFO' -Message "Windows App Error Recovery starting (lookback = ${Minutes} min)"
if ($DryRun) {
    Write-Log -Level 'INFO' -Message 'DRY-RUN mode enabled – no services will be restarted'
}

$targets = if ($Service -and $Service.Count -gt 0) { $Service } else { @($ServiceDeps.Keys) }
$restarted = [System.Collections.Generic.List[string]]::new()

foreach ($svcName in $targets) {
    if (-not $ServiceDeps.ContainsKey($svcName)) {
        Write-Log -Level 'WARN' -Message "Service '$svcName' is not defined in `$ServiceDeps – skipping"
        continue
    }

    Write-Log -Level 'INFO' -Message "Checking: $svcName"

    if (Test-ServiceHasErrors -ServiceName $svcName -LookbackMinutes $Minutes) {
        Write-Log -Level 'WARN' -Message "Errors detected for $svcName – initiating recovery"

        # Primary service
        Restart-WindowsServiceSafe -Name $svcName
        $restarted.Add($svcName)

        # Dependents
        foreach ($dep in $ServiceDeps[$svcName]) {
            if ([string]::IsNullOrWhiteSpace($dep)) { continue }
            Write-Log -Level 'INFO' -Message "Restarting dependent: $dep"
            Restart-WindowsServiceSafe -Name $dep
            $restarted.Add($dep)
        }
    }
    else {
        Write-Log -Level 'INFO' -Message "No recent errors for $svcName"
    }
}

Write-Host ''
Write-Log -Level 'INFO' -Message '===== Recovery Summary ====='
if ($restarted.Count -eq 0) {
    Write-Log -Level 'INFO' -Message 'No services required a restart'
}
else {
    Write-Log -Level 'INFO' -Message ("Services restarted: {0}" -f ($restarted -join ', '))
}

if ($DryRun) {
    Write-Log -Level 'INFO' -Message 'Dry-run complete. Re-run without -DryRun to apply changes.'
}

exit 0
