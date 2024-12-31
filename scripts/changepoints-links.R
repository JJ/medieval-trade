library(dplyr)
library(ggplot2)

links <- read.csv("data/links.csv",sep=";")

# count the number of rows for each year and store it in a new data frame
links %>% group_by(year) %>%
  summarise(n = n())
