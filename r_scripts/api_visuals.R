library(plumber)
library(dplyr)

# -------------------------------
# LOAD DATA
# -------------------------------
crime_data <- read.csv("D:/ADIT/ML/PDS/urban-crime-intelligence/data/processed/clustered_data_modified_final.csv")

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