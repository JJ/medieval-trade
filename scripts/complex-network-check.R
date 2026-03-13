all_links <- read.csv("data/all-links.csv", sep=";")
all_links <- all_links[!startsWith(all_links$hoard,"Unknown"),]
all_links <- all_links[!startsWith(all_links$mint,"Unknown"),]
all_links <- all_links[all_links$num_coins>=1,]
all_links$weight <- as.numeric(gsub(",", ".", all_links$num_coins))

library(igraph)

coin_hoard_graph <- graph_from_data_frame(all_links, directed=FALSE)
coin_hoard_graph <- simplify(coin_hoard_graph, edge.attr.comb=list(weight="sum", "ignore"))

plot(coin_hoard_graph)

coin_hoard_graph$degree <- degree(coin_hoard_graph)

library(ggplot2)

degree_data <- data.frame(names=names(coin_hoard_graph$degree), degree=unlist(coin_hoard_graph$degree))
degree_data <- degree_data[order(degree_data$degree, decreasing=TRUE),]
degree_data$rank <- 1:nrow(degree_data)

ggplot(degree_data, aes(x=rank, y=degree)) + geom_point() + geom_smooth() +
  scale_x_log10() + scale_y_log10() +
  theme_minimal() +
  labs(title = "Degree Distribution of Coin Hoard Network",
       x = "Rank (log scale)",
       y = "Degree (log scale)")

library(dplyr)
degree_data %>% group_by(degree) %>% summarise(count = n()) -> degree_distribution
ggplot(degree_distribution, aes(x=degree, y=count)) + geom_point() + geom_smooth() +
  scale_x_log10() + scale_y_log10() +
  theme_minimal() +
  labs(title = "Degree Distribution of Coin Hoard Network",
       x = "Degree (log scale)",
       y = "Count (log scale)")
