#!/usr/bin/env python3
"""
Minimal ML inference API – swap the model for your own later
"""

from fastapi import FastAPI
from pydantic import BaseModel
import joblib
import numpy as np
from pathlib import Path

app = FastAPI(title="Simple ML Inference", version="0.1.0")

MODEL_PATH = Path("model.joblib")
if MODEL_PATH.exists():
    model = joblib.load(MODEL_PATH)
else:
    from sklearn.linear_model import LogisticRegression
    model = LogisticRegression()
    X = np.array([[0], [1], [2], [3]])
    y = np.array([0, 0, 1, 1])
    model.fit(X, y)
    joblib.dump(model, MODEL_PATH)

class PredictRequest(BaseModel):
    features: list[float]

class PredictResponse(BaseModel):
    prediction: int
    probability: float | None = None

@app.post("/predict", response_model=PredictResponse)
def predict(req: PredictRequest):
    X = np.array(req.features).reshape(1, -1)
    pred = int(model.predict(X)[0])
    proba = None
    if hasattr(model, "predict_proba"):
        proba = float(model.predict_proba(X).max())
    return PredictResponse(prediction=pred, probability=proba)

@app.get("/health")
def health():
    return {"status": "ok", "model_loaded": True}
