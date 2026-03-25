library(dplyr)
library(lubridate)

cat("Loading raw dataset...\n")

data <- read.csv("../data/raw/crime_data.csv")

# Convert Date safely
data$Date <- mdy_hms(data$Date)

# Temporal Features
data$Hour    <- hour(data$Date)
data$Month   <- month(data$Date)

data$Weekday <- wday(data$Date, label=TRUE, abbr=TRUE)
data$Weekday <- as.character(data$Weekday)

data$Weekend <- ifelse(data$Weekday %in% c("Sat","Sun"),1,0)
data$Night   <- ifelse(data$Hour >= 20 | data$Hour <= 5,1,0)

# Convert logical to numeric
data$Arrest   <- ifelse(tolower(data$Arrest) == "true", 1, 0)
data$Domestic <- ifelse(tolower(data$Domestic) == "true",1,0)

# Remove missing geo
data <- data %>%
  filter(!is.na(Latitude), !is.na(Longitude))

# Select useful columns
clean_data <- data %>%
  select(Latitude,
         Longitude,
         Beat,
         District,
         Ward,
         Community.Area,
         Hour,
         Month,
         Weekend,
         Night,
         Arrest,
         Domestic,
         Primary.Type)

# Ensure folder exists
dir.create("../data/processed", recursive = TRUE, showWarnings = FALSE)

# Save
write.csv(clean_data, "../data/processed/clean_data.csv", row.names=FALSE)

cat("Preprocessing completed successfully.\n")
getwd()
