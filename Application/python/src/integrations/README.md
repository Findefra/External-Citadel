# Thin `src/integrations` wrappers

Small, opinionated adapters around common libraries. App and agent code imports **these** modules—not raw SDKs—so credentials, timeouts, and errors stay consistent.

## Layout

```
src/integrations/
├── README.md
├── __init__.py
├── settings.py       # env-based config (pydantic-settings optional)
├── http_client.py    # httpx
├── aws_s3.py         # boto3 S3
└── llm.py            # OpenAI-compatible chat
```

## Design rules

1. No secrets in code — env / settings only
2. Explicit timeouts
3. Narrow public functions
4. Raise or return structured errors; no silent swallow
5. Easy to mock in tests

## Install (examples)

```bash
pip install httpx boto3 pydantic pydantic-settings openai
```

## Usage

```python
from integrations.http_client import get_json
from integrations.aws_s3 import upload_bytes
from integrations.llm import chat

data = get_json("https://httpbin.org/json")
upload_bytes("my-bucket", "path/obj.txt", b"hello")
text = chat([{"role": "user", "content": "Summarize integrations pattern"}])
```
