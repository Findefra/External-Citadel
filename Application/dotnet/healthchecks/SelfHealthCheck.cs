using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Citadel.HealthChecks;

/// <summary>
/// Lightweight liveness check — process is running and can execute code.
/// Tag with "live" only; do not depend on I/O or external services.
/// </summary>
public sealed class SelfHealthCheck : IHealthCheck
{
    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        var data = new Dictionary<string, object>
        {
            ["utc"] = DateTime.UtcNow.ToString("o"),
            ["machine"] = Environment.MachineName
        };

        return Task.FromResult(
            HealthCheckResult.Healthy("Process is responsive.", data));
    }
}
