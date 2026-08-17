FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY crime_intel/ /app/crime_intel/
COPY data/processed/clustered_data.csv /app/data/processed/clustered_data.csv

ENV PORT=8000
EXPOSE 8000

CMD ["sh", "-c", "uvicorn crime_intel.api:app --host 0.0.0.0 --port ${PORT}"]
