<#
.SYNOPSIS
    Windows Server – Microsoft Dynamics App Server Recovery
#>
[CmdletBinding()]
param([switch]$DryRun, [int]$Minutes = 30, [string]$LogDir = 'C:\Logs\AppErrorRecovery')
Set-StrictMode -Version Latest; $ErrorActionPreference = 'Stop'
$ErrorPatterns = @('error','exception','fatal','critical','timeout','connection refused','dynamics','ax','batch','failed to','sql','AOS')
$ServiceDeps = [ordered]@{'DynamicsAOS'=@('DynamicsBatch','DynamicsManagementReporter'); 'DynamicsBatch'=@(); 'DynamicsManagementReporter'=@()}
$CustomLogs = @{'DynamicsAOS'='C:\Program Files\Microsoft Dynamics\Logs\aos.log'}
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$LogFile = Join-Path $LogDir ("dynamics-recovery_{0:yyyyMMdd}.log" -f (Get-Date))
function Write-Log([string]$Level,[string]$Message){ $ts=Get-Date -Format 'yyyy-MM-dd HH:mm:ss'; $line="[$ts] [$Level] $Message"; $c=switch($Level){'INFO'{'White'}'WARN'{'Yellow'}'ERROR'{'Red'}'DRY-RUN'{'Cyan'}default{'Gray'}}; Write-Host $line -ForegroundColor $c; Add-Content -LiteralPath $LogFile -Value $line -Encoding UTF8 }
function Test-HasErrors([string]$Name){ $start=(Get-Date).AddMinutes(-$Minutes); $pat=($ErrorPatterns -join '|'); try{ $ev=Get-WinEvent -FilterHashtable @{LogName='Application','System';StartTime=$start;Level=1,2,3} -EA SilentlyContinue | Where-Object {$_.Message -match $pat -or $_.ProviderName -like "*$Name*"}; if($ev){Write-Log WARN "Found events for $Name"; return $true} }catch{}; if($CustomLogs.ContainsKey($Name) -and (Test-Path $CustomLogs[$Name])){ if(Select-String -Path $CustomLogs[$Name] -Pattern $pat -Quiet){Write-Log WARN "Errors in custom log for $Name"; return $true} }; return $false }
function Restart-Svc([string]$Name){ if($DryRun){Write-Log DRY-RUN "Would restart $Name"; return}; try{ $s=Get-Service -Name $Name -EA Stop; Write-Log INFO "Restarting $Name"; if($s.Status -eq 'Running'){Restart-Service -Name $Name -Force}else{Start-Service -Name $Name}; Start-Sleep 4; $s.Refresh(); if($s.Status -eq 'Running'){Write-Log INFO "$Name is Running"}else{Write-Log WARN "$Name status: $($s.Status)"} }catch{Write-Log ERROR "Failed $Name : $($_.Exception.Message)"} }
Write-Log INFO "============================================================"; Write-Log INFO "Windows Dynamics Recovery started | log=$LogFile | lookback=${Minutes}m | dry-run=$DryRun"
$restarted=[System.Collections.Generic.List[string]]::new()
foreach($svc in $ServiceDeps.Keys){ Write-Log INFO "Checking: $svc"; if(Test-HasErrors $svc){ Write-Log WARN "Errors detected for $svc"; Restart-Svc $svc; $restarted.Add($svc); foreach($d in $ServiceDeps[$svc]){ if([string]::IsNullOrWhiteSpace($d)){continue}; Write-Log INFO "Restarting dependent: $d"; Restart-Svc $d; $restarted.Add($d) } }else{ Write-Log INFO "No recent errors for $svc" } }
Write-Log INFO "===== Summary ====="; if($restarted.Count -eq 0){Write-Log INFO "No restarts needed"}else{Write-Log INFO ("Restarted: {0}" -f ($restarted -join ', '))}
Write-Log INFO "Windows Dynamics Recovery finished"; Write-Log INFO "============================================================"
