"""K-means risk clustering and logistic arrest classification (scikit-learn)."""

from __future__ import annotations

import argparse
from pathlib import Path

import pandas as pd
from sklearn.cluster import KMeans
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

from crime_intel.paths import repo_root


def load_incidents(path: Path) -> pd.DataFrame:
    df = pd.read_csv(path)
    needed = {"Latitude", "Longitude", "Hour", "Night", "Arrest"}
    missing = needed - set(df.columns)
    if missing:
        raise ValueError(f"CSV missing columns: {sorted(missing)}")
    return df


def add_crime_density(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    out["Crime_Density"] = out.groupby(["Latitude", "Longitude"])["Latitude"].transform("size")
    return out


def assign_risk_labels(df: pd.DataFrame) -> pd.DataFrame:
    out = df.copy()
    summary = out.groupby("Cluster", as_index=True).agg(Avg_Density=("Crime_Density", "mean"))
    median_density = float(summary["Avg_Density"].median())
    labels = []
    for _, row in out.iterrows():
        high = float(summary.loc[row["Cluster"], "Avg_Density"]) > median_density
        night = int(row["Night"]) == 1
        if night and high:
            labels.append("Night High Crime")
        elif night and not high:
            labels.append("Night Low Crime")
        elif (not night) and high:
            labels.append("Day High Crime")
        else:
            labels.append("Day Low Crime")
    out["Risk_Label"] = labels
    return out


def cluster_incidents(df: pd.DataFrame, k: int = 4, random_state: int = 123) -> pd.DataFrame:
    out = add_crime_density(df)
    features = out[["Latitude", "Longitude", "Hour", "Night", "Crime_Density"]]
    scaled = StandardScaler().fit_transform(features)
    model = KMeans(n_clusters=k, n_init=25, random_state=random_state)
    out["Cluster"] = model.fit_predict(scaled) + 1
    return assign_risk_labels(out)


def classify_arrest(df: pd.DataFrame, random_state: int = 123):
    cols = ["Hour", "Night"]
    for extra in ("Weekend", "Domestic"):
        if extra in df.columns:
            cols.append(extra)
    X = df[cols].fillna(0)
    y = df["Arrest"].astype(int)
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.25, random_state=random_state, stratify=y if y.nunique() > 1 else None
    )
    clf = LogisticRegression(max_iter=500, random_state=random_state)
    clf.fit(X_train, y_train)
    acc = float(accuracy_score(y_test, clf.predict(X_test)))
    return clf, acc


def main() -> None:
    parser = argparse.ArgumentParser(description="Crime clustering and arrest classification")
    parser.add_argument("command", choices=["cluster", "classify"])
    parser.add_argument("input_csv", nargs="?", default=str(repo_root() / "data/processed/clean_data.csv"))
    parser.add_argument("output_csv", nargs="?", default=str(repo_root() / "data/processed/clustered_py.csv"))
    args = parser.parse_args()
    df = load_incidents(Path(args.input_csv))
    if args.command == "cluster":
        clustered = cluster_incidents(df)
        Path(args.output_csv).parent.mkdir(parents=True, exist_ok=True)
        clustered.to_csv(args.output_csv, index=False)
        print(f"wrote {args.output_csv} ({len(clustered)} rows, {clustered['Cluster'].nunique()} clusters)")
        print(clustered["Risk_Label"].value_counts().to_string())
    else:
        _, acc = classify_arrest(df)
        print(f"logistic arrest accuracy={acc:.3f}")


if __name__ == "__main__":
    main()
