# Pulls policy compliance state and exports non-compliant resources
$states = Get-AzPolicyState -Filter "ComplianceState eq 'NonCompliant'"
$summary = $states | Group-Object PolicyDefinitionName | Select-Object Name, Count | Sort-Object Count -Descending
$summary | Format-Table -AutoSize

$states | Select-Object ResourceId, PolicyDefinitionName, PolicyAssignmentName, ComplianceState, Timestamp |
    Export-Csv ".\Policy_NonCompliant_$(Get-Date -Format yyyyMMdd_HHmm).csv" -NoTypeInformation
