using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;

namespace Citadel.HealthChecks;

public sealed class DiskSpaceHealthCheckOptions
{
    public string Path { get; set; } = OperatingSystem.IsWindows() ? @"C:\" : "/";
    public long MinimumFreeMegabytes { get; set; } = 512;
    public long DegradedFreeMegabytes { get; set; } = 1024;
}

/// <summary>
/// Readiness check: enough free disk for logs, temp, and uploads.
/// </summary>
public sealed class DiskSpaceHealthCheck : IHealthCheck
{
    private readonly DiskSpaceHealthCheckOptions _options;

    public DiskSpaceHealthCheck(IOptions<DiskSpaceHealthCheckOptions> options)
    {
        _options = options?.Value ?? new DiskSpaceHealthCheckOptions();
    }

    public DiskSpaceHealthCheck(DiskSpaceHealthCheckOptions options)
    {
        _options = options ?? new DiskSpaceHealthCheckOptions();
    }

    public Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var path = _options.Path;
            var root = Path.GetPathRoot(Path.GetFullPath(string.IsNullOrWhiteSpace(path) ? Directory.GetCurrentDirectory() : path));
            if (string.IsNullOrEmpty(root))
            {
                return Task.FromResult(HealthCheckResult.Unhealthy($"Could not resolve drive root for path: {path}"));
            }

            var driveInfo = new DriveInfo(root);
            if (!driveInfo.IsReady)
            {
                return Task.FromResult(HealthCheckResult.Unhealthy($"Drive not ready: {driveInfo.Name}"));
            }

            var freeMb = driveInfo.AvailableFreeSpace / (1024 * 1024);
            var totalMb = driveInfo.TotalSize / (1024 * 1024);
            var data = new Dictionary<string, object>
            {
                ["path"] = path,
                ["drive"] = driveInfo.Name,
                ["freeMegabytes"] = freeMb,
                ["totalMegabytes"] = totalMb,
                ["minimumFreeMegabytes"] = _options.MinimumFreeMegabytes,
                ["degradedFreeMegabytes"] = _options.DegradedFreeMegabytes
            };

            if (freeMb < _options.MinimumFreeMegabytes)
            {
                return Task.FromResult(HealthCheckResult.Unhealthy(
                    $"Low disk space: {freeMb} MB free (minimum {_options.MinimumFreeMegabytes} MB).",
                    data: data));
            }

            if (freeMb < _options.DegradedFreeMegabytes)
            {
                return Task.FromResult(HealthCheckResult.Degraded(
                    $"Disk space getting low: {freeMb} MB free.",
                    data: data));
            }

            return Task.FromResult(HealthCheckResult.Healthy($"Disk space OK: {freeMb} MB free.", data));
        }
        catch (Exception ex)
        {
            return Task.FromResult(HealthCheckResult.Unhealthy("Failed to evaluate disk space.", ex));
        }
    }
}
