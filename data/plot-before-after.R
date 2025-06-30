library(ggplot2)
library(dplyr)
all_links <- read.csv("data/all-links.csv", sep=";")

# Eliminate all links that start by "Unknown"
#
all_links <- all_links %>%
  filter(!grepl("^Unknown", hoard) & !grepl("^Unknown", mint))

library(igraph)

all_links$num_coins <- as.numeric(all_links$num_coins)
all_links <- all_links %>%
  group_by(hoard, mint) %>%
  summarise(weight = sum(num_coins, na.rm=TRUE)) %>%
  ungroup()

all_links_network <- graph_from_data_frame(all_links, directed=FALSE)


plot(all_links_network)
