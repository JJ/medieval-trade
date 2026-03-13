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

ggplot( degree_data, aes(x=rank, y=degree)) +
  geom_point() +
  scale_x_log10() +
  scale_y_log10() +
  theme_minimal()

p_k <- table(degree_data$degree)/length(degree_data$degree)
pk_df <- data.frame(
  k = as.numeric(names(p_k)),
  Pk = as.numeric(p_k)
)

ggplot(pk_df, aes(x = k, y = Pk)) +
  geom_point() +
  scale_x_log10() +
  scale_y_log10() +
  theme_minimal()

library(dplyr)
degree_data %>% group_by(degree) %>% summarise(count = n()) -> degree_distribution
ggplot(degree_distribution, aes(x=degree, y=count)) + geom_point() + geom_smooth() +
  scale_x_log10() + scale_y_log10() +
  theme_minimal() +
  labs(title = "Degree Distribution of Coin Hoard Network",
       x = "Degree (log scale)",
       y = "Count (log scale)")

# Small world network

transitivity <- transitivity(coin_hoard_graph, type="average")
average_path_length <- mean_distance(coin_hoard_graph, directed=FALSE)

n <- vcount(coin_hoard_graph)
m <- ecount(coin_hoard_graph)

nrep <- 100
Crand <- numeric(nrep)
Lrand <- numeric(nrep)

for(i in 1:nrep){
  gr <- sample_gnm(n, m, directed=FALSE)

  Crand[i] <- transitivity(gr, type="average")
  Lrand[i] <- mean_distance(gr, directed=FALSE)
}

Cr <- mean(Crand)
Lr <- mean(Lrand)

small_world_coefficient <- (transitivity / Cr) / (average_path_length / Lr)

nrep <- 200
Crand <- numeric(nrep)
Lrand <- numeric(nrep)

for(i in 1:nrep){
  gr <- sample_degseq(degree(coin_hoard_graph), method="vl")
  Crand[i] <- transitivity(gr, type="average")
  Lrand[i] <- mean_distance(gr)
}

Cr <- mean(Crand)
Lr <- mean(Lrand)

small_world_coefficient_degree <- (transitivity / Cr) / (average_path_length / Lr)

# Now omega
nrep <- 200
Lrand <- numeric(nrep)

for(i in 1:nrep){
  gr <- sample_gnm(n, m)
  Lrand[i] <- mean_distance(gr)
}

Lr <- mean(Lrand)

k <- round(2*m/n)  # approximate average degree
if(k %% 2 == 1) k <- k - 1

gl <- make_lattice(length=n, dim=1, nei=k/2, circular=TRUE)

Cl <- transitivity(gl, type="average")

omega <- (Lr/average_path_length) - (transitivity/Cl)

# Simple clustering coefficient

Crand <- (2*m)/(n*(n-1))
C_ratio <- transitivity / Crand
