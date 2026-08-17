from pathlib import Path

import pandas as pd
import pytest

from crime_intel.engine import classify_arrest, cluster_incidents, load_incidents

FIXTURE = Path(__file__).parent / "fixtures" / "sample_crime.csv"


def test_cluster_assigns_four_risk_labels():
    df = load_incidents(FIXTURE)
    out = cluster_incidents(df, k=4)
    assert len(out) == len(df)
    assert out["Cluster"].nunique() == 4
    assert out["Crime_Density"].min() >= 1
    assert set(out["Risk_Label"].dropna()) <= {
        "Day High Crime",
        "Day Low Crime",
        "Night High Crime",
        "Night Low Crime",
    }


def test_classify_arrest_returns_accuracy():
    df = load_incidents(FIXTURE)
    _, acc = classify_arrest(df)
    assert 0.0 <= acc <= 1.0
