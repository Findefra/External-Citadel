# Common agent skills

“Skills” here means **reusable capabilities** an AI agent can invoke—not a single Python package. Overlaps with tool-calling, MCP tools, and repo-local skills (e.g. PEP 8 reviewer).

## 25 commonly used agent skills

| # | Skill | What the agent does |
|---|--------|---------------------|
| 1 | **Web search** | Query the public web for current facts |
| 2 | **Fetch / browse URL** | Read a page or API response |
| 3 | **Code execution** | Run Python/shell in a sandbox |
| 4 | **File read/write** | Open, edit, create project files |
| 5 | **Repo / Git operations** | Status, diff, commit, branch (controlled) |
| 6 | **GitHub / GitLab API** | Issues, PRs, actions, releases |
| 7 | **Shell / terminal** | Controlled command execution |
| 8 | **Database query** | SQL or ORM against approved DBs |
| 9 | **HTTP API call** | Invoke internal/external REST tools |
| 10 | **Cloud CLI** | `aws` / `az` / `gcloud` read or change (scoped) |
| 11 | **Kubernetes ops** | `kubectl` get/apply/logs (scoped) |
| 12 | **Docker / image build** | Build, tag, scan images |
| 13 | **Lint / format code** | ruff, black, eslint, etc. |
| 14 | **Code review** | Style, security, PR commentary |
| 15 | **Test runner** | pytest, npm test, go test |
| 16 | **Search codebase** | Semantic or text search over repo |
| 17 | **Memory / notes** | Store durable user or project facts |
| 18 | **Calendar / email** | Schedule, send (connected apps) |
| 19 | **Docs / Notion / wiki** | Read or update knowledge bases |
| 20 | **Incident / ticketing** | ServiceNow, Jira create/update |
| 21 | **Observability query** | Logs, metrics, traces (Prom, CloudWatch) |
| 22 | **Secret lookup** | Read from vault/SM (never print secrets) |
| 23 | **Image generation / vision** | Generate or describe images |
| 24 | **RAG retrieval** | Query vector index / knowledge base |
| 25 | **Human approval gate** | Pause for confirm on destructive actions |

## Skill design checklist

- Clear **name + description** (for tool routing)
- **Input schema** (JSON Schema / Pydantic)
- **Least privilege** (read-only default where possible)
- **Idempotent** when safe
- **Timeouts + error strings** agents can recover from
- **Audit log** of invocations

## Example skill categories by domain

| Domain | Skills |
|--------|--------|
| DevOps | Shell, K8s, cloud CLI, CI, observability |
| Engineering | Code exec, lint, test, review, repo search |
| Data | SQL, pandas exec, notebook export |
| ITSM | Ticketing, status pages, runbook fetch |
| Personal productivity | Calendar, email, memory |

## Relation to this monorepo

- Implement skills as **documented tools** agents may call (scripts under `Automation/`, APIs under `Application/`).
- Prefer **Python libraries** from `../libraries/common-25.md` inside skill implementations.
- Keep destructive skills behind **approval** and narrow IAM.
