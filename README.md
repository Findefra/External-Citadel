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
│   └── python/
└── Artificial-Intelligence/
    └── azure/ado-agent-ops/
```

## Where to put new code

| You are adding… | Put it in |
|-----------------|----------|
| A sample app or utility (non-sensitive) | `Application/` |
| Public Terraform samples / patterns | `Infrastructure/<cloud>/samples/` |
| Shareable scripts or Python utilities | `Automation/` |
| Public AI / agent ops samples | `Artificial-Intelligence/` |

**Rules of thumb**
- No secrets, account IDs, or production-only config.
- Prefer samples that another engineer can run with minimal setup.
- Private / production content belongs in [Internal-Citadel](https://github.com/Findefra/Internal-Citadel).
- Every new module folder should include a short `README.md`.

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
- Portfolio: [fde-portfolio](https://github.com/Findefra/fde-portfolio)
