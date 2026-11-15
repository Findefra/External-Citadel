using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;

namespace Citadel.HealthChecks;

public sealed class HttpDependencyHealthCheckOptions
{
    public string Name { get; set; } = "http-dependency";
    public string Url { get; set; } = string.Empty;
    public int TimeoutMilliseconds { get; set; } = 3000;
    public Func<HttpResponseMessage, bool>? IsSuccess { get; set; }
}

/// <summary>
/// Readiness check against an HTTP dependency.
/// </summary>
public sealed class HttpDependencyHealthCheck : IHealthCheck
{
    private readonly HttpClient _httpClient;
    private readonly HttpDependencyHealthCheckOptions _options;

    public HttpDependencyHealthCheck(HttpClient httpClient, IOptions<HttpDependencyHealthCheckOptions> options)
    {
        _httpClient = httpClient ?? throw new ArgumentNullException(nameof(httpClient));
        _options = options?.Value ?? new HttpDependencyHealthCheckOptions();
    }

    public HttpDependencyHealthCheck(HttpClient httpClient, HttpDependencyHealthCheckOptions options)
    {
        _httpClient = httpClient ?? throw new ArgumentNullException(nameof(httpClient));
        _options = options ?? new HttpDependencyHealthCheckOptions();
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_options.Url))
        {
            return HealthCheckResult.Unhealthy("HTTP dependency URL is not configured.");
        }

        using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        cts.CancelAfter(_options.TimeoutMilliseconds);

        var data = new Dictionary<string, object>
        {
            ["url"] = _options.Url,
            ["timeoutMilliseconds"] = _options.TimeoutMilliseconds
        };

        try
        {
            using var response = await _httpClient
                .GetAsync(_options.Url, HttpCompletionOption.ResponseHeadersRead, cts.Token)
                .ConfigureAwait(false);

            data["statusCode"] = (int)response.StatusCode;
            var ok = _options.IsSuccess?.Invoke(response) ?? response.IsSuccessStatusCode;

            if (ok)
            {
                return HealthCheckResult.Healthy($"{_options.Name} OK ({(int)response.StatusCode}).", data);
            }

            return HealthCheckResult.Unhealthy($"{_options.Name} returned {(int)response.StatusCode}.", data: data);
        }
        catch (OperationCanceledException)
        {
            return HealthCheckResult.Unhealthy($"{_options.Name} timed out or was canceled.", data: data);
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy($"{_options.Name} failed: {ex.Message}", ex, data);
        }
    }
}
