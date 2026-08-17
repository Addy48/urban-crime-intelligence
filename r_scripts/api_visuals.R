library(plumber)
library(dplyr)
library(dotenv)
library(here)

if (file.exists(".env")) dotenv::load_dot_env(".env")

API_KEY <- Sys.getenv("API_KEY")
if (!nzchar(API_KEY)) {
  stop("API_KEY is not set. Copy .env.example to .env or pass --env-file to Docker.")
}

root <- Sys.getenv("PROJECT_ROOT", unset = "")
if (!nzchar(root)) {
  root <- tryCatch(here::here(), error = function(e) getwd())
}
csv_path <- file.path(root, "data", "processed", "clustered_data.csv")
if (!file.exists(csv_path)) {
  csv_path <- "data/processed/clustered_data.csv"
}

# -------------------------------
# LOAD DATA
# -------------------------------
crime_data <- read.csv(csv_path)

# -------------------------------
# CORS (KEEP THIS)
# -------------------------------
#* @filter cors
function(req, res){
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type")
  
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  }
  
  plumber::forward()
}

#* @filter auth
function(req, res){
  
  # 🔑 First try URL query param
  client_key <- req$args$api_key
  
  # 🔁 Fallback to header (optional)
  if (is.null(client_key)) {
    client_key <- req$HTTP_X_API_KEY
  }
  
  # ❌ If invalid
  if (is.null(client_key) || client_key != API_KEY) {
    res$status <- 401
    return(list(error = "Unauthorized: Invalid API Key"))
  }
  
  # ✅ Continue request
  plumber::forward()
}

# -------------------------------
# 1. KPI ENDPOINT
# -------------------------------
#* @get /kpi
function(){
  
  total <- nrow(crime_data)
  
  risk_counts <- crime_data %>% count(Risk_Label, sort = TRUE)
  hour_counts <- crime_data %>% count(Hour, sort = TRUE)
  
  peak_hour <- if(nrow(hour_counts)>0) hour_counts$Hour[1] else NA
  
  return(data.frame(
    total_crimes = total,
  
    peak_crime_hour = peak_hour
  ))
}

# -------------------------------
# 2. MAP DATA
# -------------------------------
#* @get /map-data
function(){
  crime_data %>%
    select(Latitude, Longitude, Cluster, Risk_Label)
}

# -------------------------------
# 3. RISK LABEL DISTRIBUTION
# -------------------------------
#* @get /risk-label
function(){
  crime_data %>%
    count(Risk_Label)
}

# -------------------------------
# 4. CLUSTER vs RISK
# -------------------------------
#* @get /cluster-risk
function(){
  crime_data %>%
    count(Cluster, Risk_Label)
}

# -------------------------------
# 5. CRIME BY HOUR
# -------------------------------
#* @get /crime-hour
function(){
  if(!"Hour" %in% colnames(crime_data)){
    return(list(error = "Hour column not found"))
  }
  
  crime_data %>%
    count(Hour)
}

# -------------------------------
# 6. DAY vs NIGHT
# -------------------------------
#* @get /day-night
function(){
  if(!"Night" %in% colnames(crime_data)){
    return(list(error = "Night column not found"))
  }
  
  crime_data %>%
    count(Night)
}

# -------------------------------
# 7. WEEKEND ANALYSIS
# -------------------------------
#* @get /weekend
function(){
  if(!"Weekend" %in% colnames(crime_data)){
    return(list(error = "Weekend column not found"))
  }
  
  crime_data %>%
    count(Weekend)
}

# -------------------------------
# 8. MONTHLY TREND
# -------------------------------
#* @get /monthly
function(){
  if(!"Month" %in% colnames(crime_data)){
    return(list(error = "Month column not found"))
  }
  
  crime_data %>%
    count(Month)
}

#* @get /arrest
function(){
  
  if(!"Arrest" %in% colnames(crime_data)){
    return(data.frame(
      Category = "Not Available",
      Count = 0
    ))
  }
  
  crime_data %>%
    count(Arrest) %>%
    mutate(
      Category = ifelse(Arrest == 1, "Arrested", "Not Arrested")
    ) %>%
    select(Category, Count = n)
}

#* @get /domestic
function(){
  
  if(!"Domestic" %in% colnames(crime_data)){
    return(data.frame(
      Category = "Not Available",
      Count = 0
    ))
  }
  
  crime_data %>%
    count(Domestic) %>%
    mutate(
      Category = ifelse(Domestic == 1, "Domestic", "Non-Domestic")
    ) %>%
    select(Category, Count = n)
}

#* @get /primary-type
function(){
  
  if(!"Primary.Type" %in% colnames(crime_data)){
    return(data.frame(
      Primary_Type = "Not Available",
      Count = 0
    ))
  }
  
  crime_data %>%
    count(Primary.Type, sort = TRUE) %>%
    rename(Count = n)
}