FROM rstudio/plumber

RUN R -e "install.packages(c('dplyr','here','dotenv'), repos='https://cloud.r-project.org/')"

WORKDIR /app

RUN mkdir -p /app/data/processed

COPY r_scripts/api_visuals.R /app/api_visuals.R
COPY data/processed/clustered_data.csv /app/data/processed/clustered_data.csv

EXPOSE 8000

CMD ["api_visuals.R"]