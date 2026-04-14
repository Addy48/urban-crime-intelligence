library(dplyr)
library(ggplot2)

setwd("D:/ADIT/ML/PDS/urban-crime-intelligence/urban-crime-intelligence")

cat("Loading dataset...\n")
data <- read.csv("data/processed/clean_data.csv")

# -------------------------------
# STEP 1: Create Crime Density
# -------------------------------
cat("Creating crime density...\n")

data <- data %>%
  group_by(Latitude, Longitude) %>%
  mutate(Crime_Density = n()) %>%
  ungroup()

# -------------------------------
# STEP 2: Select Features
# -------------------------------
cluster_data <- data %>%
  select(Latitude, Longitude, Hour, Night, Crime_Density)

# -------------------------------
# STEP 3: Scaling
# -------------------------------
scaled_data <- scale(cluster_data)

# -------------------------------
# STEP 4: K-Means Clustering
# -------------------------------
set.seed(123)
kmeans_model <- kmeans(scaled_data, centers = 4, nstart = 25)

data$Cluster <- kmeans_model$cluster

# -------------------------------
# STEP 5: Cluster Summary
# -------------------------------
cluster_summary <- data %>%
  group_by(Cluster) %>%
  summarise(
    Avg_Hour = mean(Hour),
    Night_Ratio = mean(Night),
    Avg_Density = mean(Crime_Density),
    Count = n()
  )

print(cluster_summary)

# -------------------------------
# STEP 6: Improved Risk Labels
# -------------------------------
cat("Assigning Risk Labels (FIXED)...\n")

median_density <- median(cluster_summary$Avg_Density)

data$Risk_Label <- NA

for (i in 1:4) {
  
  cluster_density <- cluster_summary$Avg_Density[i]
  
  # Assign based on BOTH cluster + row-level Night
  data$Risk_Label[data$Cluster == i & data$Night == 1 & cluster_density > median_density] <- "Night High Crime"
  
  data$Risk_Label[data$Cluster == i & data$Night == 1 & cluster_density <= median_density] <- "Night Low Crime"
  
  data$Risk_Label[data$Cluster == i & data$Night == 0 & cluster_density > median_density] <- "Day High Crime"
  
  data$Risk_Label[data$Cluster == i & data$Night == 0 & cluster_density <= median_density] <- "Day Low Crime"
}

# -------------------------------
# STEP 7: Visualization
# -------------------------------
ggplot(data, aes(x = Longitude, y = Latitude, color = Risk_Label)) +
  geom_point(alpha = 0.5) +
  ggtitle("Crime Clusters with Risk Labels")

# -------------------------------
# STEP 8: Save Output
# -------------------------------
write.csv(data, "data/processed/clustered_data_modified_final.csv", row.names = FALSE)
table(data$Risk_Label)
cat("Clustering completed.\n")