library(dplyr)
library(ggplot2)

links <- read.csv("data/links.csv",sep=";")

links %>% group_by(year) %>%
  summarise(n = n()) -> links_year

saveRDS(links_year, "data/links_year.rds")
