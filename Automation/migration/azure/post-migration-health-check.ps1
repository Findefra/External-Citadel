<#
.SYNOPSIS
  Azure post-migration health assessment with Markdown/JSON reports.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ResourceGroup,
    [string]$ReportDir = "./reports",
    [string[]]$WebAppNames = @(),
    [string]$Subscription
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command az -ErrorAction SilentlyContinue)) { throw 'Azure CLI (az) required' }
if ($Subscription) { az account set --subscription $Subscription | Out-Null }

New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
$ts = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ')
$reportMd = Join-Path $ReportDir "azure-post-migration-$ts.md"
$reportJson = Join-Path $ReportDir "azure-post-migration-$ts.json"

$pass = 0; $warn = 0; $fail = 0
$results = New-Object System.Collections.Generic.List[object]

function Add-Result([string]$Name, [string]$Status, [string]$Detail) {
    switch ($Status) {
        'PASS' { $script:pass++ }
        'WARN' { $script:warn++ }
        'FAIL' { $script:fail++ }
    }
    $results.Add([pscustomobject]@{ name = $Name; status = $Status; detail = $Detail }) | Out-Null
    Add-Content -Path $reportMd -Value "| $Name | $Status | $Detail |"
}

@(
    '# Azure Post-Migration Health Report'
    ''
    "- **Generated (UTC):** $((Get-Date).ToUniversalTime().ToString('o'))"
    "- **Resource group:** $ResourceGroup"
    ''
    '## Summary'
    ''
    '| Check | Status | Detail |'
    '|-------|--------|--------|'
) | Set-Content -Path $reportMd -Encoding UTF8

$vmNames = @(az vm list -g $ResourceGroup --query '[].name' -o tsv 2>$null)
if (-not $vmNames -or $vmNames.Count -eq 0) {
    Add-Result 'Virtual machines' 'WARN' 'No VMs in resource group'
} else {
    foreach ($vm in $vmNames) {
        if ([string]::IsNullOrWhiteSpace($vm)) { continue }
        $power = az vm get-instance-view -g $ResourceGroup -n $vm --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv 2>$null
        if ($power -eq 'VM running') { Add-Result "VM $vm" 'PASS' "power=$power" }
        else { Add-Result "VM $vm" 'FAIL' "power=$power" }
    }
}

if ($WebAppNames.Count -eq 0) {
    Add-Result 'App Service' 'WARN' 'Skipped (pass -WebAppNames)'
} else {
    foreach ($app in $WebAppNames) {
        $state = az webapp show -g $ResourceGroup -n $app --query state -o tsv 2>$null
        if ($state -eq 'Running') { Add-Result "App Service $app" 'PASS' "state=$state" }
        else { Add-Result "App Service $app" 'FAIL' "state=$state" }
    }
}

$sqlCount = az sql server list -g $ResourceGroup --query 'length(@)' -o tsv 2>$null
if ([int]$sqlCount -gt 0) { Add-Result 'Azure SQL servers' 'PASS' "count=$sqlCount" }
else { Add-Result 'Azure SQL servers' 'WARN' 'None in RG' }

@(
    ''
    '## Totals'
    ''
    "- PASS: $pass"
    "- WARN: $warn"
    "- FAIL: $fail"
    ''
    '## Native migration context'
    ''
    'Align with Azure Migrate, ASR, and Azure DMS. Pair web apps with /health/ready checks.'
) | Add-Content -Path $reportMd

$summary = [pscustomobject]@{
    timestamp     = $ts
    cloud         = 'azure'
    resourceGroup = $ResourceGroup
    summary       = @{ pass = $pass; warn = $warn; fail = $fail }
    results       = $results
}
$summary | ConvertTo-Json -Depth 6 | Set-Content -Path $reportJson -Encoding UTF8

Write-Host "Report written: $reportMd"
Write-Host "JSON written:   $reportJson"
if ($fail -gt 0) { exit 1 }
exit 0
