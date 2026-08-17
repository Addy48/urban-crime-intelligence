library(httr)
library(jsonlite)

api_key <- Sys.getenv("API_KEY")
if (!nzchar(api_key)) stop("API_KEY is not set. Copy .env.example to .env.")

url <- "http://localhost:8000/predict-risk"

response <- GET(url, query = list(
  lat = 41.8,
  lon = -87.6,
  hour = 23,
  page = 1,
  limit = 5,
  apikey = api_key
))

json_data <- content(response, as = "text")
parsed_data <- fromJSON(json_data)

print(parsed_data)
all_data <- list()

for (p in 1:3) {
  res <- GET(url, query = list(
    lat = 41.8,
    lon = -87.6,
    hour = 23,
    page = p,
    limit = 5,
    apikey = api_key
  ))
  json <- content(res, as = "text")
  parsed <- fromJSON(json)
  all_data[[p]] <- parsed$results
}

final_df <- do.call(rbind, all_data)
print(final_df)
