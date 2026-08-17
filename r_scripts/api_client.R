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

# Convert to text
json_data <- content(response, as = "text")

# Convert JSON → R list
parsed_data <- fromJSON(json_data)

print(parsed_data)
