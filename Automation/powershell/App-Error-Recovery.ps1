<#
.SYNOPSIS
    Windows-native application error recovery script with structured logging.
    Scans Event Logs (and optional custom log files) for errors, then restarts
    the affected Windows service and any configured dependent services.

.DESCRIPTION
    100% PowerShell implementation designed for Windows Server environments.
    Uses Get-WinEvent, Get-Service, and Restart-Service.
    All actions are written to both the console and a daily rotating log file.

.PARAMETER DryRun
    Show actions without making changes.

.PARAMETER Minutes
    Minutes of Event Log history to examine (default: 30).

.PARAMETER Service
    One or more specific service names to check. If omitted, all services
    defined in $ServiceDeps are processed.

.PARAMETER LogDir
    Directory for log files (default: C:\Logs\AppErrorRecovery).

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
    [string[]]$Service,
    [string]$LogDir = 'C:\Logs\AppErrorRecovery'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------
# CONFIGURATION - Customize for your environment
# ------------------------------------------------------------

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

$ServiceDeps = [ordered]@{
    'PaymentApi'          = @('PaymentWorker', 'PaymentCache')
    'OrderService'        = @('OrderWorker', 'InventorySync')
    'AuthService'         = @('SessionStore')
    'NotificationService' = @()
}

$CustomLogs = @{
    # 'PaymentApi' = 'C:\Logs\PaymentApi\app.log'
}

$EventLogNames = @('Application', 'System')

# ------------------------------------------------------------
# Logging setup
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$LogFile = Join-Path $LogDir ("AppErrorRecovery_{0:yyyyMMdd}.log" -f (Get-Date))

function Write-Log {
    param(
        [Parameter(Mandatory)][ValidateSet('INFO','WARN','ERROR','DRY-RUN','DEBUG')]
        [string]$Level,
        [Parameter(Mandatory)][string]$Message
    )

    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$ts] [$Level] $Message"

    # Console with color
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARN'    { 'Yellow' }
        'ERROR'   { 'Red' }
        'DRY-RUN' { 'Cyan' }
        'DEBUG'   { 'Gray' }
    }
    Write-Host $line -ForegroundColor $color

    # File (always)
    Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8
}

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

function Test-ServiceHasErrors {
    param(
        [string]$ServiceName,
        [int]$LookbackMinutes
    )

    $startTime = (Get-Date).AddMinutes(-$LookbackMinutes)
    $pattern   = ($ErrorPatterns -join '|')

    try {
        $filter = @{
            LogName   = $EventLogNames
            StartTime = $startTime
            Level     = 1, 2, 3
        }

        $events = Get-WinEvent -FilterHashtable $filter -ErrorAction SilentlyContinue |
            Where-Object {
                ($_.Message -match $pattern) -or
                ($_.ProviderName -like "*$ServiceName*") -or
                ($_.Id -in 1000, 1001, 1002)
            }

        if ($events -and $events.Count -gt 0) {
            Write-Log -Level 'WARN' -Message ("Found {0} matching event(s) for {1}" -f $events.Count, $ServiceName)
            return $true
        }
    }
    catch {
        Write-Log -Level 'WARN' -Message "Event Log query limited or failed: $($_.Exception.Message)"
    }

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

Write-Log -Level 'INFO' -Message "============================================================"
Write-Log -Level 'INFO' -Message "Windows App Error Recovery started"
Write-Log -Level 'INFO' -Message "Log file : $LogFile"
Write-Log -Level 'INFO' -Message "Lookback : ${Minutes} minute(s)"
Write-Log -Level 'INFO' -Message "DryRun   : $DryRun"

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

        Restart-WindowsServiceSafe -Name $svcName
        $restarted.Add($svcName)

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

Write-Log -Level 'INFO' -Message "Windows App Error Recovery finished"
Write-Log -Level 'INFO' -Message "============================================================"

exit 0
