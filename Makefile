PYTHON ?= python3
export PYTHONPATH := .

.PHONY: test cluster classify api cpp cpp-test

test:
	$(PYTHON) -m pytest -q

cluster:
	$(PYTHON) -m crime_intel.engine cluster data/processed/clean_data.csv data/processed/clustered_py.csv

classify:
	$(PYTHON) -m crime_intel.engine classify data/processed/clean_data.csv

api:
	uvicorn crime_intel.api:app --host 0.0.0.0 --port 8000

cpp:
	mkdir -p bin
	$(CXX) -O2 -std=c++17 -Wall -Wextra -o bin/crime_engine cpp/crime_engine.cpp

cpp-test: cpp
	./bin/crime_engine cluster tests/fixtures/sample_crime.csv /tmp/crime_clusters.csv
	./bin/crime_engine classify tests/fixtures/sample_crime.csv
