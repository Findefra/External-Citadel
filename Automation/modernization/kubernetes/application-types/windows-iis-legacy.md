# Type: Windows / IIS / .NET Framework legacy

## Characteristics

- IIS, System.Web, GAC dependencies, Windows auth
- May require **Windows node pools**

## Modernization path (realistic order)

1. **Inventory** — frameworks, COM, file paths, scheduled tasks
2. **Option A — Windows containers** on Kubernetes Windows nodes (higher ops cost)
3. **Option B — Replatform** to ASP.NET Core on Linux (preferred long-term)
4. **Option C — Retain** on IIS/VM or App Service until rewrite funded
5. If Windows containers: hostProcess vs isolated; correct base images; Services still work; many CNI/mesh features lag Linux

## Pitfalls

- Assuming full feature parity with Linux pods
- Mixing Windows and Linux in one Deployment
- Skipping a clear exit plan from Windows nodes
