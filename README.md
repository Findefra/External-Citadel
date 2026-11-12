# External-Citadel

Public Citadel platform monorepo — shareable samples and non-sensitive content.

## Structure

```
External-Citadel/
├── Application/
├── Infrastructure/
│   ├── aws/samples/
│   ├── azure/samples/
│   ├── gcp/
│   └── kubernetes/samples/
├── Automation/
│   ├── aws/ops/
│   └── python/                  # Python samples (from Python_apps)
└── Artificial-Intelligence/
    └── azure/ado-agent-ops/
```

Private / production content lives in **Internal-Citadel**.

## CI

GitHub Actions run on every push and pull request to `main`:

| Workflow | What it does |
|----------|--------------|
| **Terraform** | `fmt -check`, auto-discover validate, TFLint, Checkov (soft-fail) |
| **ShellCheck** | Lints all `.sh` scripts |
| **Structure Guard** | Warns on unexpected top-level dirs or missing domain READMEs |

See [`.github/workflows/`](.github/workflows/).

## Related

- [Internal-Citadel](https://github.com/Findefra/Internal-Citadel) (private)
- Legacy: [Automation_Scripts](https://github.com/Findefra/Automation_Scripts), [Python_apps](https://github.com/Findefra/Python_apps) (migrated — archive when ready)
