# 🚔 Urban Crime Intelligence System using Data Analytics

## 📌 Overview

The **Urban Crime Intelligence System** is a data-driven project designed to analyze, classify, and visualize crime patterns using real-world police data.

The system integrates **data preprocessing, machine learning, API development, and visualization** to provide actionable insights into urban crime trends.

---

## 🎯 Objectives

* Analyze crime data to identify patterns and trends
* Predict whether a crime leads to an arrest (classification)
* Segment crimes into risk-based categories (clustering)
* Provide interactive visual insights using dashboards
* Deploy the system using containerization for scalability

---

## 📊 Dataset

* **Source:** California Police Crime Data
* Contains information such as:

  * Crime type
  * Time (day/night, hour, month)
  * Location (latitude & longitude)
  * Arrest status

---

## ⚙️ Project Workflow

### 🔹 1. Data Preprocessing

* Data cleaning and handling missing values
* Feature engineering (Hour, Night, Weekend, Month)
* Data transformation for modeling

### 🔹 2. Exploratory Data Analysis (EDA)

* Crime distribution analysis
* Time-based trends (hour, day/night, monthly)
* Risk-level insights

### 🔹 3. Classification

* Goal: Predict whether a crime results in **arrest or not**
* Machine learning model trained on processed dataset

### 🔹 4. Clustering

* Crimes grouped into 4 categories:

  * **Day High Risk**
  * **Day Low Risk**
  * **Night High Risk**
  * **Night Low Risk**

---

## 🔌 API Development

* Built using **Plumber**
* Provides endpoints for:

  * KPI metrics
  * Risk distribution
  * Crime by hour
  * Cluster analysis

### 🔐 Security

* API protected using **API Key authentication**

---

## 📈 Visualization

* Dashboard built using **Power BI**
* Features:

  * Crime heatmaps
  * Risk distribution charts
  * Time-based insights
  * Cluster visualization

---

## 🐳 Deployment

* Containerized using **Docker**
* Ensures:

  * Easy setup
  * Portability
  * Consistent environment

---

## 🚀 How to Run

### 🔹 Using Docker

```bash
docker build -t crime-api .
docker run --env-file .env -p 8000:8000 crime-api
```

### 🔹 Access API

```text
http://localhost:8000/kpi?api_key=YOUR_API_KEY
```

---

## 📁 Project Structure

```
urban-crime-intelligence/
├── python_scripts/        # EDA and modeling notebooks
├── r_scripts/             # Plumber API
├── data/processed/        # Cleaned datasets
├── PowerBI/               # Dashboard
├── Dockerfile
└── README.md
```

---

## 💡 Key Features

* End-to-end data pipeline
* Machine learning integration
* Secure REST API
* Interactive dashboards
* Docker-based deployment

---

## C++ engine

Risk clustering and arrest classification run in C++ (`cpp/crime_engine.cpp`). No extra libraries.

```bash
make
make test
make cluster    # writes data/processed/clustered_cpp.csv
make classify   # prints logistic accuracy on Arrest
```

Four k-means groups on latitude, longitude, hour, night, and local crime density. Logistic model uses hour, night, weekend, and domestic flags.

## 🧠 Conclusion

This project demonstrates how data science and software engineering can be combined to build a **scalable and intelligent crime analysis system**, enabling better decision-making through data-driven insights.

---

## Author

[Aaditya Upadhyay](https://github.com/Addy48)

---
