# Enforces HTTPS-only, TLS 1.2+, disables public blob access, enables soft delete & versioning where missing
Get-AzStorageAccount | ForEach-Object {
    $sa = $_
    $props = @{
        EnableHttpsTrafficOnly = $true
        MinimumTlsVersion      = "TLS1_2"
        AllowBlobPublicAccess  = $false
    }
    Set-AzStorageAccount -ResourceGroupName $sa.ResourceGroupName -Name $sa.StorageAccountName @props | Out-Null

    $ctx = $sa.Context
    Enable-AzStorageBlobDeleteRetentionPolicy -Context $ctx -RetentionDays 14 -PassThru | Out-Null
    Enable-AzStorageBlobVersioning -Context $ctx | Out-Null

    Write-Host "Hardened: $($sa.StorageAccountName)" -ForegroundColor Cyan
}
