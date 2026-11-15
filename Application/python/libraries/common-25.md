# 25 commonly used Python libraries

Practical shortlist for general development, data, cloud, and automation—not a ranking of “best,” but libraries you will see constantly in production and agent toolchains.

| # | Library | Typical use |
|---|---------|-------------|
| 1 | **requests** | HTTP client for APIs |
| 2 | **httpx** | Async/sync HTTP (modern alternative to requests) |
| 3 | **aiohttp** | Async HTTP client/server |
| 4 | **fastapi** | High-performance APIs and agent tool backends |
| 5 | **flask** | Lightweight web apps/APIs |
| 6 | **django** | Full-stack web framework |
| 7 | **pydantic** | Data validation and settings (v2 ubiquitous in agents) |
| 8 | **sqlalchemy** | SQL toolkit / ORM |
| 9 | **alembic** | DB migrations |
| 10 | **pandas** | Tabular data analysis |
| 11 | **numpy** | Numerical arrays and compute |
| 12 | **httpx / urllib3** | (see httpx) low-level HTTP transport often pulled in transitively |
| 12 | **pytest** | Testing |
| 13 | **black** | Opinionated code formatting |
| 14 | **ruff** | Fast lint + format |
| 15 | **mypy** | Static typing |
| 16 | **python-dotenv** | `.env` loading |
| 17 | **pyyaml** | YAML parse/emit |
| 18 | **click** / **typer** | CLI apps (typer builds on click) |
| 19 | **rich** | Terminal output, logging UX |
| 20 | **boto3** | AWS SDK |
| 21 | **azure-identity** / **azure-mgmt-*** | Azure auth and resource management (pair as needed) |
| 22 | **google-cloud-*** | GCP client libraries (e.g. storage, secret manager) |
| 23 | **redis** | Redis client |
| 24 | **celery** | Distributed task queues |
| 25 | **openai** / **anthropic** | LLM provider SDKs for agent apps |

### Honorable mentions (often #26–35)

`pillow`, `cryptography`, `jinja2`, `uvicorn`, `gunicorn`, `structlog`, `tenacity`, `orjson`, `polars`, `scikit-learn`, `langchain` / `langgraph`, `httpcore`, `attrs`.

### Install pattern

```bash
pip install requests httpx pydantic fastapi uvicorn pandas numpy pytest ruff boto3
# or uv/poetry for lockfiles
```

### Library “calls” path

Prefer a thin wrapper module per integration under app code, e.g.:

```
src/integrations/
  http_client.py    # httpx
  aws_s3.py         # boto3
  llm.py            # openai/anthropic
```

Keep secrets out of library defaults; inject via env / settings (pydantic-settings).
