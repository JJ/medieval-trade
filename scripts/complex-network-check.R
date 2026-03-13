all_links <- read.csv("data/all-links.csv", sep=";")
all_links <- all_links[!startsWith(all_links$hoard,"Unknown"),]
all_links <- all_links[!startsWith(all_links$mint,"Unknown"),]
all_links <- all_links[all_links$num_coins>=1,]
all_links$weight <- as.numeric(gsub(",", ".", all_links$num_coins))

library(igraph)

coin_hoard_graph <- graph_from_data_frame(all_links, directed=FALSE)
coin_hoard_graph <- simplify(coin_hoard_graph, edge.attr.comb=list(weight="sum", "ignore"))

plot(coin_hoard_graph)
