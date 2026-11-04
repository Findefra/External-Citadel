# Finds overly permissive NSG rules (Any/Any, * sources, high-risk ports open to Internet)
$risky = @()
Get-AzNetworkSecurityGroup | ForEach-Object {
    $nsg = $_
    foreach ($rule in $nsg.SecurityRules) {
        $isRisky = $false
        $reasons = @()
        if ($rule.SourceAddressPrefix -in @("*","Internet","0.0.0.0/0") -and $rule.Access -eq "Allow") {
            $isRisky = $true; $reasons += "Open to Internet"
        }
        if ($rule.DestinationPortRange -match "22|3389|1433|3306|5432|445|135|139" -and $rule.SourceAddressPrefix -in @("*","Internet")) {
            $isRisky = $true; $reasons += "High-risk port exposed"
        }
        if ($isRisky) {
            $risky += [PSCustomObject]@{
                NSG           = $nsg.Name
                ResourceGroup = $nsg.ResourceGroupName
                RuleName      = $rule.Name
                Direction     = $rule.Direction
                Priority      = $rule.Priority
                Source        = $rule.SourceAddressPrefix
                Ports         = $rule.DestinationPortRange
                Reasons       = $reasons -join "; "
            }
        }
    }
}
$risky | Sort-Object NSG, Priority | Format-Table -AutoSize
