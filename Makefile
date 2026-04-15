CXX ?= g++
CXXFLAGS ?= -O2 -std=c++17 -Wall -Wextra
BIN := bin/crime_engine

.PHONY: all test clean cluster classify

all: $(BIN)

$(BIN): cpp/crime_engine.cpp
	mkdir -p bin
	$(CXX) $(CXXFLAGS) -o $@ $<

cluster: $(BIN)
	$(BIN) cluster data/processed/clean_data.csv data/processed/clustered_cpp.csv

classify: $(BIN)
	$(BIN) classify data/processed/clean_data.csv

test: $(BIN)
	$(BIN) cluster tests/fixtures/sample_crime.csv /tmp/crime_clusters.csv
	$(BIN) classify tests/fixtures/sample_crime.csv
	test -s /tmp/crime_clusters.csv

clean:
	rm -rf bin
