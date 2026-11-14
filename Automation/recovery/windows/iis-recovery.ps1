<#
.SYNOPSIS
    Windows Server – IIS (W3SVC / WAS / Application Pools) Error Recovery
.DESCRIPTION
    Scans Event Logs and optional IIS logs for errors, then restarts W3SVC, WAS,
    and/or affected application pools.
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [ValidateRange(1, 1440)]
    [int]$Minutes = 30,
    [string]$LogDir = 'C:\Logs\AppErrorRecovery',
    [string[]]$AppPool  # optional specific app pools; if omitted, uses configured list
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------
$ErrorPatterns = @(
    'error', 'exception', 'fatal', 'critical', 'timeout',
    'application pool', 'w3svc', 'was', '503', '500.19',
    'failed to', 'rapid-fail', 'crashed'
)

# Primary services and related app pools
$ServiceDeps = [ordered]@{
    'W3SVC' = @('WAS')
    'WAS'   = @()
}

# Application pools to check/restart when problems are detected
$DefaultAppPools = @(
    'DefaultAppPool'
    # 'MyWebAppPool'
    # 'PaymentAppPool'
)

$CustomLogs = @{
    # 'W3SVC' = 'C:\inetpub\logs\LogFiles\W3SVC1\*.log'  # optional; Event Log is primary
}

# ------------------------------------------------------------
# Logging
# ------------------------------------------------------------
if (-not (Test-Path -LiteralPath $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
$LogFile = Join-Path $LogDir ("iis-recovery_{0:yyyyMMdd}.log" -f (Get-Date))

function Write-Log {
    param(
        [Parameter(Mandatory)][ValidateSet('INFO','WARN','ERROR','DRY-RUN')]
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

function Test-IisErrors {
    param([int]$LookbackMinutes)
    $startTime = (Get-Date).AddMinutes(-$LookbackMinutes)
    $pattern = ($ErrorPatterns -join '|')

    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName   = 'Application', 'System'
            StartTime = $startTime
            Level     = 1, 2, 3
        } -ErrorAction SilentlyContinue |
        Where-Object {
            $_.ProviderName -match 'IIS|WAS|W3SVC|ASP\.NET' -or
            $_.Message -match $pattern
        }
        if ($events -and $events.Count -gt 0) {
            Write-Log -Level 'WARN' -Message ("Found {0} IIS/WAS-related event(s)" -f $events.Count)
            return $true
        }
    } catch {
        Write-Log -Level 'WARN' -Message "Event Log query limited: $($_.Exception.Message)"
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
        Write-Log -Level 'INFO' -Message "Restarting service: $Name (status: $($svc.Status))"
        if ($svc.Status -eq 'Running') {
            Restart-Service -Name $Name -Force -ErrorAction Stop
        } else {
            Start-Service -Name $Name -ErrorAction Stop
        }
        Start-Sleep -Seconds 3
        $svc.Refresh()
        if ($svc.Status -eq 'Running') {
            Write-Log -Level 'INFO' -Message "$Name is Running"
        } else {
            Write-Log -Level 'WARN' -Message "$Name status: $($svc.Status)"
        }
    } catch {
        Write-Log -Level 'ERROR' -Message "Failed to restart $Name : $($_.Exception.Message)"
    }
}

function Restart-AppPoolSafe {
    param([string]$Name)
    if ($DryRun) {
        Write-Log -Level 'DRY-RUN' -Message "Would restart app pool: $Name"
        return
    }
    try {
        Import-Module WebAdministration -ErrorAction Stop
        Write-Log -Level 'INFO' -Message "Recycling application pool: $Name"
        Restart-WebAppPool -Name $Name -ErrorAction Stop
        Start-Sleep -Seconds 2
        $state = (Get-WebAppPoolState -Name $Name).Value
        Write-Log -Level 'INFO' -Message "App pool $Name state: $state"
    } catch {
        Write-Log -Level 'ERROR' -Message "Failed to restart app pool $Name : $($_.Exception.Message)"
    }
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
Write-Log -Level 'INFO' -Message "============================================================"
Write-Log -Level 'INFO' -Message "IIS Recovery started | log=$LogFile | lookback=${Minutes}m | dry-run=$DryRun"

$restarted = [System.Collections.Generic.List[string]]::new()
$pools = if ($AppPool -and $AppPool.Count -gt 0) { $AppPool } else { $DefaultAppPools }

if (Test-IisErrors -LookbackMinutes $Minutes) {
    Write-Log -Level 'WARN' -Message "IIS-related errors detected – initiating recovery"

    # Restart core services
    foreach ($svcName in $ServiceDeps.Keys) {
        Restart-WindowsServiceSafe -Name $svcName
        $restarted.Add($svcName)
        foreach ($dep in $ServiceDeps[$svcName]) {
            if ([string]::IsNullOrWhiteSpace($dep)) { continue }
            Restart-WindowsServiceSafe -Name $dep
            $restarted.Add($dep)
        }
    }

    # Restart configured application pools
    foreach ($pool in $pools) {
        if ([string]::IsNullOrWhiteSpace($pool)) { continue }
        Restart-AppPoolSafe -Name $pool
        $restarted.Add("AppPool:$pool")
    }
} else {
    Write-Log -Level 'INFO' -Message "No recent IIS/WAS errors found in Event Log"
}

Write-Log -Level 'INFO' -Message "===== Recovery Summary ====="
if ($restarted.Count -eq 0) {
    Write-Log -Level 'INFO' -Message "No services or app pools required a restart"
} else {
    Write-Log -Level 'INFO' -Message ("Restarted: {0}" -f ($restarted -join ', '))
}

if ($DryRun) {
    Write-Log -Level 'INFO' -Message "Dry-run complete. Re-run without -DryRun to apply changes."
}
Write-Log -Level 'INFO' -Message "IIS Recovery finished"
Write-Log -Level 'INFO' -Message "============================================================"
