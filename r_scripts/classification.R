library(dplyr)
library(caret)
install.packages("randomForest")
library(randomForest)

setwd("C:/Users/soumy/Desktop/urban-crime-intelligence")

cat("Loading clustered data...\n")
data <- read.csv("data/processed/clustered_data_modified_final.csv")

# -------------------------------
# STEP 1: Prepare Data
# -------------------------------
data$Arrest <- as.factor(data$Arrest)
data$Risk_Label <- as.factor(data$Risk_Label)

model_data <- data %>%
  select(Latitude, Longitude, Hour, Night, Crime_Density, Risk_Label, Arrest)

# -------------------------------
# STEP 2: Train-Test Split
# -------------------------------
set.seed(123)

trainIndex <- createDataPartition(model_data$Arrest, p = 0.85, list = FALSE)

train_data <- model_data[trainIndex, ]
test_data  <- model_data[-trainIndex, ]

# -------------------------------
# STEP 3: Train Model (FIXED → Random Forest)
# -------------------------------
cat("Training Random Forest model...\n")

model <- randomForest(Arrest ~ ., data = train_data, ntree = 100)

# -------------------------------
# STEP 4: Predictions
# -------------------------------
probabilities <- predict(model, test_data, type = "prob")[,2]

predictions <- ifelse(probabilities > 0.5, 1, 0)
predictions <- as.factor(predictions)

# -------------------------------
# STEP 5: Evaluation
# -------------------------------
conf_matrix <- confusionMatrix(predictions, test_data$Arrest)

print(conf_matrix)

# -------------------------------
# STEP 6: Save Model + Levels
# -------------------------------
dir.create("models", showWarnings = FALSE)

saveRDS(model, "models/arrest_model.rds")
saveRDS(levels(data$Risk_Label), "models/risk_levels.rds")

cat("Classification completed and model saved.\n")
# pick SAME row you are testing in API
row <- data[100, ]

print(row$Arrest)

# model prediction
prob <- predict(model, row, type = "prob")[,2]
print(prob)

pred <- ifelse(prob > 0.5, 1, 0)
print(pred)
readRDS("models/risk_levels.rds")
table(data$Arrest)
prop.table(table(data$Arrest))