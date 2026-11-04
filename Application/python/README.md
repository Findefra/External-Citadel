# Python Application Samples (Public)

Migrated from `Findefra/Python_apps`.

| File | Description |
|------|-------------|
| `aws_tag_compliance_checker.py` | EC2/RDS/S3 required-tag compliance → CSV |
| `fastapi_instance_launcher.py` | FastAPI: launch hardened Windows/RHEL from Image Builder AMIs |
| `imagebuilder_cli.py` | Click CLI: list/trigger/status Image Builder pipelines |
| `ml_inference_service.py` | FastAPI + scikit-learn demo inference |
| `streamlit_platform_dashboard.py` | Streamlit overview of Image Builder + CodePipeline |

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# examples
python aws_tag_compliance_checker.py --output tags.csv
uvicorn fastapi_instance_launcher:app --reload
python imagebuilder_cli.py list-pipelines
uvicorn ml_inference_service:app --reload
streamlit run streamlit_platform_dashboard.py
```

Production platform automation lives in **Internal-Citadel**.
