"""FastAPI service. API key comes from API_KEY; never hardcode it."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Optional

import pandas as pd
from dotenv import load_dotenv
from fastapi import FastAPI, Header, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from crime_intel.paths import processed_dir, repo_root

load_dotenv(repo_root() / ".env")

app = FastAPI(title="Urban Crime Intelligence")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

_DATA: Optional[pd.DataFrame] = None


def _api_key() -> str:
    key = os.environ.get("API_KEY", "").strip()
    if not key:
        raise HTTPException(status_code=500, detail="API_KEY is not set")
    return key


def _auth(api_key: Optional[str], x_api_key: Optional[str]) -> None:
    expected = _api_key()
    got = (api_key or x_api_key or "").strip()
    if got != expected:
        raise HTTPException(status_code=401, detail="Unauthorized: Invalid API Key")


def _data() -> pd.DataFrame:
    global _DATA
    if _DATA is None:
        csv_path = Path(os.environ.get("CRIME_DATA", processed_dir() / "clustered_data.csv"))
        if not csv_path.is_file():
            raise HTTPException(status_code=500, detail=f"data file not found: {csv_path}")
        _DATA = pd.read_csv(csv_path)
    return _DATA


@app.middleware("http")
async def auth_middleware(request, call_next):
    if request.method == "OPTIONS" or request.url.path in {"/docs", "/openapi.json", "/redoc"}:
        return await call_next(request)
    api_key = request.query_params.get("api_key") or request.query_params.get("apikey")
    header_key = request.headers.get("x-api-key")
    try:
        _auth(api_key, header_key)
    except HTTPException as exc:
        from fastapi.responses import JSONResponse

        return JSONResponse(status_code=exc.status_code, content={"error": exc.detail})
    return await call_next(request)


@app.get("/kpi")
def kpi():
    df = _data()
    peak = int(df["Hour"].mode().iloc[0]) if "Hour" in df.columns and not df.empty else None
    return {"total_crimes": int(len(df)), "peak_crime_hour": peak}


@app.get("/risk-label")
def risk_label():
    df = _data()
    if "Risk_Label" not in df.columns:
        return {"error": "Risk_Label column not found"}
    counts = df["Risk_Label"].value_counts().reset_index()
    counts.columns = ["Risk_Label", "n"]
    return counts.to_dict(orient="records")


@app.get("/crime-hour")
def crime_hour():
    df = _data()
    if "Hour" not in df.columns:
        return {"error": "Hour column not found"}
    counts = df["Hour"].value_counts().sort_index().reset_index()
    counts.columns = ["Hour", "n"]
    return counts.to_dict(orient="records")


@app.get("/predict-risk")
def predict_risk(
    lat: float = Query(...),
    lon: float = Query(...),
    hour: int = Query(...),
    page: int = Query(1, ge=1),
    limit: int = Query(5, ge=1, le=100),
    api_key: Optional[str] = Query(None),
    x_api_key: Optional[str] = Header(None, alias="X-API-KEY"),
):
    _auth(api_key, x_api_key)
    df = _data().copy()
    df["distance"] = (df["Latitude"] - lat) ** 2 + (df["Longitude"] - lon) ** 2
    sorted_df = df.sort_values("distance")
    start = (page - 1) * limit
    end = start + limit
    cols = [c for c in ("Latitude", "Longitude", "Risk_Label", "Cluster") if c in sorted_df.columns]
    chunk = sorted_df.iloc[start:end][cols]
    return {
        "page": page,
        "limit": limit,
        "total": int(len(sorted_df)),
        "results": chunk.to_dict(orient="records"),
    }
