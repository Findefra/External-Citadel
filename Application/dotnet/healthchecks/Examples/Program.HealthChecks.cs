// Example wiring for ASP.NET Core (.NET 6/7/8+). Merge into your Program.cs.
//
// using Citadel.HealthChecks;
//
// var builder = WebApplication.CreateBuilder(args);
//
// builder.Services.AddCitadelDefaultHealthChecks(
//     configureDisk: o =>
//     {
//         // Azure App Service example:
//         // o.Path = Environment.GetEnvironmentVariable("HOME") ?? o.Path;
//         o.MinimumFreeMegabytes = 512;
//         o.DegradedFreeMegabytes = 1024;
//     },
//     configureMemory: o =>
//     {
//         o.DegradedThresholdMegabytes = 1024;
//         o.UnhealthyThresholdMegabytes = 1536;
//     },
//     configureHttpDependency: o =>
//     {
//         o.Name = "downstream-api";
//         o.Url = builder.Configuration["HealthChecks:DownstreamUrl"] ?? "";
//         o.TimeoutMilliseconds = 3000;
//     });
//
// // Optional community checks:
// // builder.Services.AddHealthChecks()
// //     .AddSqlServer(conn, name: "sql", tags: new[] { "ready" });
//
// var app = builder.Build();
// app.MapCitadelHealthEndpoints();
// app.Run();

namespace Citadel.HealthChecks.Examples;

public static class ProgramHealthChecksExample
{
    public const string Documentation = "See file header comments for Program.cs integration.";
}
