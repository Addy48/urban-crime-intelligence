import os
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

FIXTURE = Path(__file__).parent / "fixtures" / "sample_crime.csv"


@pytest.fixture()
def client(tmp_path, monkeypatch):
    clustered = tmp_path / "clustered.csv"
    import pandas as pd
    from crime_intel.engine import cluster_incidents, load_incidents

    cluster_incidents(load_incidents(FIXTURE)).to_csv(clustered, index=False)
    monkeypatch.setenv("API_KEY", "test-key")
    monkeypatch.setenv("CRIME_DATA", str(clustered))
    import crime_intel.api as api

    api._DATA = None
    return TestClient(api.app)


def test_kpi_requires_key(client):
    res = client.get("/kpi")
    assert res.status_code == 401


def test_kpi_with_key(client):
    res = client.get("/kpi", params={"api_key": "test-key"})
    assert res.status_code == 200
    body = res.json()
    assert body["total_crimes"] > 0
    assert "peak_crime_hour" in body


def test_predict_risk_rejects_wrong_key(client):
    res = client.get(
        "/predict-risk",
        params={"lat": 41.88, "lon": -87.63, "hour": 14, "api_key": "nope"},
    )
    assert res.status_code == 401
