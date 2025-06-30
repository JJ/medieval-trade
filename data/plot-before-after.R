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

all_links <- all_links %>% filter(weight > 0)

all_links_network <- graph_from_data_frame(all_links, directed=FALSE)

V(all_links_network)$betweenness <- betweenness(all_links_network, directed=FALSE)

# avoid that all central nodes cluster together
plot(all_links_network,
     vertex.size=log(V(all_links_network)$betweenness) * 2,
     layout=layout.reingold.tilford(all_links_network, circular=T),
     vertex.label.cex=0.5, vertex.label.color="black", vertex.color=rgb(1,1,0,0.5),
     edge.color="gray")
