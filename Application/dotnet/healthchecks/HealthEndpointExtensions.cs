using System.Text.Json;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Citadel.HealthChecks;

public static class HealthEndpointExtensions
{
    /// <summary>
    /// Maps /health/live (live tag), /health/ready (ready tag), and /health (all).
    /// </summary>
    public static IEndpointRouteBuilder MapCitadelHealthEndpoints(
        this IEndpointRouteBuilder endpoints,
        string livePath = "/health/live",
        string readyPath = "/health/ready")
    {
        static HealthCheckOptions Options(Func<HealthCheckRegistration, bool> predicate) => new()
        {
            Predicate = predicate,
            ResponseWriter = WriteCompactJsonAsync,
            ResultStatusCodes =
            {
                [HealthStatus.Healthy] = StatusCodes.Status200OK,
                [HealthStatus.Degraded] = StatusCodes.Status200OK,
                [HealthStatus.Unhealthy] = StatusCodes.Status503ServiceUnavailable
            }
        };

        endpoints.MapHealthChecks(livePath, Options(r => r.Tags.Contains(HealthCheckServiceCollectionExtensions.LiveTag)));
        endpoints.MapHealthChecks(readyPath, Options(r => r.Tags.Contains(HealthCheckServiceCollectionExtensions.ReadyTag)));
        endpoints.MapHealthChecks("/health", Options(_ => true));

        return endpoints;
    }

    private static async Task WriteCompactJsonAsync(HttpContext context, HealthReport report)
    {
        context.Response.ContentType = "application/json; charset=utf-8";

        var payload = new
        {
            status = report.Status.ToString(),
            totalDurationMs = report.TotalDuration.TotalMilliseconds,
            entries = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                durationMs = e.Value.Duration.TotalMilliseconds,
                data = e.Value.Data
            })
        };

        await JsonSerializer.SerializeAsync(
            context.Response.Body,
            payload,
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
    }
}
