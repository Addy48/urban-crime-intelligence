# Urban Crime Intelligence System

Python-first crime analytics: preprocess police incidents, cluster risk, predict arrest, serve a REST API, and visualize in Power BI.

**Author:** [Aaditya Upadhyay](https://github.com/Addy48)  
**Repo:** https://github.com/Addy48/urban-crime-intelligence

## What it does

- Cleans California police incident records and builds hour / night / weekend / month features
- Clusters incidents into 4 risk groups (day/night × high/low) with **scikit-learn KMeans**
- Fits a **logistic regression** model for arrest vs no arrest
- Serves KPI, hourly, risk-label, and nearest-incident endpoints from **FastAPI**
- Optional R Plumber API and C++ engine remain in the tree; they are not required to run the project

## Dataset

California police crime data: type, time, location, arrest status. Processed CSV lives in `data/processed/`.

## Setup

```bash
cp .env.example .env    # set API_KEY — never commit .env
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
# cluster + classify (relative paths, no Windows drive letters)
PYTHONPATH=. python -m crime_intel.engine cluster
PYTHONPATH=. python -m crime_intel.engine classify

# API — reads API_KEY from the environment / .env
PYTHONPATH=. uvicorn crime_intel.api:app --host 0.0.0.0 --port 8000
```

```text
http://localhost:8000/kpi?api_key=YOUR_API_KEY
```

## Docker

```bash
docker build -t crime-api .
docker run --env-file .env -p 8000:8000 crime-api
```

`Dockerfile` is the Python API. `Dockerfile.r` is the older Plumber image if you need it.

## Tests

```bash
PYTHONPATH=. pytest -q
```

## Layout

```
crime_intel/           # Python engine + FastAPI
r_scripts/             # optional R preprocessing / Plumber
cpp/                   # optional C++ engine
data/processed/        # cleaned CSVs
PowerBI/               # dashboard
tests/                 # pytest
```

R scripts resolve the repo root from `PROJECT_ROOT` or the script location. They do not `setwd()` to a laptop path. API clients read `Sys.getenv("API_KEY")` — the key is not in source.
