library(tidyverse)
library(skimr)
library(corrplot)
library(DataExplorer)

data <- read.csv("data/processed/clean_data.csv")
str(data)
head(data)


summary(data)
skim(data)

colSums(is.na(data))
plot_missing(data)

#Crime Type Distribution 
ggplot(data, aes(x = Primary.Type)) +
  geom_bar(fill = "red") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  ggtitle("Crime Type Distribution")

#Crime By Hour
ggplot(data,aes(x=Hour)) + geom_bar(fill="blue")+ ggtitle("Crimes by Hour")

#Crime by Month
ggplot(data,aes(x=Month))+ geom_bar(fill="green")+ ggtitle(("Crimes by Month"))

#Night vs Day
ggplot(data,aes(x=Night))+geom_bar(fill="darkgreen")+labs(x="Night(1=Yes)",title="Night vs Day Crimes")

#District Wise Crime
ggplot(data,aes(x=District))+ geom_bar(fill="orange")+ggtitle("Crimes by District")

#Domestic vs Non-Domestic
ggplot(data,aes(x=Domestic))+ geom_bar(fill="pink") + ggtitle("Domestic Crimes")

#Analysis
ggplot(data,aes(x=Arrest))+geom_bar(fill="yellow")+ggtitle("Arrests Made")


#Crime Hotspots
ggplot(data, aes(x = Longitude, y = Latitude)) +
  geom_bin2d() +
  scale_fill_gradient(low = "yellow", high = "red") +
  ggtitle("Crime Hotspots")

num_data <- data %>% select(where(is.numeric))

cor_matrix <- cor(num_data)

corrplot(cor_matrix, method = "color", tl.cex = 0.7)

create_report(data, output_file = "EDA_Report.html")

