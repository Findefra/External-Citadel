# Automation / python (Public Samples)

Canonical path for Python samples from `Findefra/Python_apps`.

| File | Description |
|------|-------------|
| `aws_tag_compliance_checker.py` | EC2/RDS/S3 required-tag compliance → CSV |
| `fastapi_instance_launcher.py` | FastAPI: launch hardened Windows/RHEL AMIs |
| `imagebuilder_cli.py` | Click CLI for Image Builder pipelines |
| `ml_inference_service.py` | FastAPI + scikit-learn demo inference |
| `streamlit_platform_dashboard.py` | Streamlit Image Builder + CodePipeline overview |

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

python aws_tag_compliance_checker.py --output tags.csv
uvicorn fastapi_instance_launcher:app --reload
python imagebuilder_cli.py list-pipelines
uvicorn ml_inference_service:app --reload
streamlit run streamlit_platform_dashboard.py
```

Production Python utilities live in **Internal-Citadel** `Automation/python/`.
