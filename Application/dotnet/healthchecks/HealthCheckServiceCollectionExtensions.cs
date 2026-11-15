using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Citadel.HealthChecks;

public static class HealthCheckServiceCollectionExtensions
{
    public const string LiveTag = "live";
    public const string ReadyTag = "ready";

    /// <summary>
    /// Registers self (live), disk + memory (ready), and optional HTTP dependency (ready).
    /// </summary>
    public static IHealthChecksBuilder AddCitadelDefaultHealthChecks(
        this IServiceCollection services,
        Action<DiskSpaceHealthCheckOptions>? configureDisk = null,
        Action<MemoryHealthCheckOptions>? configureMemory = null,
        Action<HttpDependencyHealthCheckOptions>? configureHttpDependency = null)
    {
        var diskOpts = new DiskSpaceHealthCheckOptions();
        configureDisk?.Invoke(diskOpts);

        var memOpts = new MemoryHealthCheckOptions();
        configureMemory?.Invoke(memOpts);

        services.AddSingleton(diskOpts);
        services.AddSingleton(memOpts);
        services.AddSingleton<SelfHealthCheck>();
        services.AddSingleton<DiskSpaceHealthCheck>(sp =>
            new DiskSpaceHealthCheck(sp.GetRequiredService<DiskSpaceHealthCheckOptions>()));
        services.AddSingleton<MemoryHealthCheck>(sp =>
            new MemoryHealthCheck(sp.GetRequiredService<MemoryHealthCheckOptions>()));

        var builder = services.AddHealthChecks()
            .AddCheck<SelfHealthCheck>(
                name: "self",
                failureStatus: HealthStatus.Unhealthy,
                tags: new[] { LiveTag })
            .AddCheck<DiskSpaceHealthCheck>(
                name: "disk",
                failureStatus: HealthStatus.Unhealthy,
                tags: new[] { ReadyTag })
            .AddCheck<MemoryHealthCheck>(
                name: "memory",
                failureStatus: HealthStatus.Unhealthy,
                tags: new[] { ReadyTag });

        if (configureHttpDependency is not null)
        {
            var httpOpts = new HttpDependencyHealthCheckOptions();
            configureHttpDependency(httpOpts);
            services.AddSingleton(httpOpts);
            services.AddHttpClient(nameof(HttpDependencyHealthCheck));

            builder.Add(new HealthCheckRegistration(
                name: string.IsNullOrWhiteSpace(httpOpts.Name) ? "http-dependency" : httpOpts.Name,
                factory: sp =>
                {
                    var client = sp.GetRequiredService<IHttpClientFactory>()
                        .CreateClient(nameof(HttpDependencyHealthCheck));
                    return new HttpDependencyHealthCheck(client, httpOpts);
                },
                failureStatus: HealthStatus.Unhealthy,
                tags: new[] { ReadyTag },
                timeout: TimeSpan.FromMilliseconds(Math.Max(500, httpOpts.TimeoutMilliseconds + 500)));
        }

        return builder;
    }

    public static IHealthChecksBuilder AddCitadelLivenessOnly(this IServiceCollection services)
    {
        services.AddSingleton<SelfHealthCheck>();
        return services.AddHealthChecks()
            .AddCheck<SelfHealthCheck>("self", tags: new[] { LiveTag });
    }
}
