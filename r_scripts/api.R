#* Predict crime risk (with auth + pagination)
#* @param lat
#* @param lon
#* @param hour
#* @param page
#* @param limit
#* @param apikey
#* @get /predict-risk

function(lat, lon, hour, page = 1, limit = 5, apikey = NULL){
  
  # -------------------------------
  # 1. AUTHENTICATION
  # -------------------------------
  if (is.null(apikey) || apikey != "12345") {
    return(list(error = "Unauthorized: Invalid API Key"))
  }
  
  lat <- as.numeric(lat)
  lon <- as.numeric(lon)
  hour <- as.numeric(hour)
  page <- as.numeric(page)
  limit <- as.numeric(limit)
  
  # -------------------------------
  # 2. Compute distances
  # -------------------------------
  data$distance <- (data$Latitude - lat)^2 + (data$Longitude - lon)^2
  
  # Sort nearest
  sorted_data <- data[order(data$distance), ]
  
  # -------------------------------
  # 3. PAGINATION
  # -------------------------------
  start <- (page - 1) * limit + 1
  end <- min(start + limit - 1, nrow(sorted_data))
  
  result <- sorted_data[start:end, ]
  
  # -------------------------------
  # 4. Return JSON-friendly output
  # -------------------------------
  return(list(
    page = page,
    limit = limit,
    total = nrow(sorted_data),
    results = result[, c("Latitude", "Longitude", "Risk_Label", "Cluster")]
  ))
}
