FROM rstudio/plumber

RUN R -e "install.packages(c('dplyr','here'), repos='https://cloud.r-project.org/')"

WORKDIR /app

# Create folders
RUN mkdir -p /app/data/processed

# Copy files
COPY r_scripts/api_visuals.R /app/api_visuals.R
COPY data/processed/clustered_data.csv /app/data/processed/clustered_data.csv

EXPOSE 8000

# 👇 IMPORTANT: just pass file name
CMD ["api_visuals.R"]