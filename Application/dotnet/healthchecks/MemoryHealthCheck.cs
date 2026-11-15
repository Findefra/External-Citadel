using System.Diagnostics;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;

namespace Citadel.HealthChecks;

public sealed class MemoryHealthCheckOptions
{
    public long UnhealthyThresholdMegabytes { get; set; } = 2048;
    public long DegradedThresholdMegabytes { get; set; } = 1536;
}

/// <summary>
/// Process working-set check for memory-constrained App Service plans.
/// </summary>
public sealed class MemoryHealthCheck : IHealthCheck
{
    private readonly MemoryHealthCheckOptions _options;

    public MemoryHealthCheck(IOptions<MemoryHealthCheckOptions> options)
    {
        _options = options?.Value ?? new MemoryHealthCheckOptions();
    }

    public MemoryHealthCheck(MemoryHealthCheckOptions options)
    {
        _options = options ?? new MemoryHealthCheckOptions();
    }

    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            using var process = Process.GetCurrentProcess();
            var workingSetMb = process.WorkingSet64 / (1024 * 1024);
            var privateMb = process.PrivateMemorySize64 / (1024 * 1024);

            var data = new Dictionary<string, object>
            {
                ["workingSetMegabytes"] = workingSetMb,
                ["privateMemoryMegabytes"] = privateMb,
                ["degradedThresholdMegabytes"] = _options.DegradedThresholdMegabytes,
                ["unhealthyThresholdMegabytes"] = _options.UnhealthyThresholdMegabytes,
                ["gcTotalMemoryMegabytes"] = GC.GetTotalMemory(forceFullCollection: false) / (1024 * 1024)
            };

            if (workingSetMb >= _options.UnhealthyThresholdMegabytes)
            {
                return Task.FromResult(HealthCheckResult.Unhealthy(
                    $"Working set high: {workingSetMb} MB (threshold {_options.UnhealthyThresholdMegabytes} MB).",
                    data: data));
            }

            if (workingSetMb >= _options.DegradedThresholdMegabytes)
            {
                return Task.FromResult(HealthCheckResult.Degraded(
                    $"Working set elevated: {workingSetMb} MB.",
                    data: data));
            }

            return Task.FromResult(HealthCheckResult.Healthy($"Memory OK: working set {workingSetMb} MB.", data));
        }
        catch (Exception ex)
        {
            return Task.FromResult(HealthCheckResult.Unhealthy("Failed to evaluate process memory.", ex));
        }
    }
}
