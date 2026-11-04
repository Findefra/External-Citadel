# Compares current month spend vs previous periods and flags large increases
$end = Get-Date
$startCurrent = $end.AddDays(-30)
$startPrev    = $end.AddDays(-60)

$current = Get-AzConsumptionUsageDetail -StartDate $startCurrent -EndDate $end |
           Measure-Object -Property PretaxCost -Sum | Select-Object -ExpandProperty Sum

$previous = Get-AzConsumptionUsageDetail -StartDate $startPrev -EndDate $startCurrent |
            Measure-Object -Property PretaxCost -Sum | Select-Object -ExpandProperty Sum

$delta = $current - $previous
$pct   = if ($previous -gt 0) { [math]::Round(($delta / $previous) * 100, 1) } else { 0 }

[PSCustomObject]@{
    Period30Days   = [math]::Round($current, 2)
    PeriodPrev30   = [math]::Round($previous, 2)
    Delta          = [math]::Round($delta, 2)
    PercentChange  = "$pct%"
    Alert          = if ([math]::Abs($pct) -gt 25) { "REVIEW" } else { "OK" }
} | Format-List
