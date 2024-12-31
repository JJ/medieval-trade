library(dplyr)
library(ggplot2)

links <- read.csv("data/links.csv",sep=";")

links %>% group_by(year) %>%
  summarise(n = n())
