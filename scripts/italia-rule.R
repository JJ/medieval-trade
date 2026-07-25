library(dplyr)

italia_links <- readRDS("data/flame-time-series-April-2026-filtered.rds") %>% filter( !is.na(link_rate) & (hoard == "Italia" | mint=="Italia") )

italia_intra_links <- italia_links %>% filter(hoard == "Italia" & mint=="Italia")

italia_links %>% group_by( year ) %>% arrange( year ) %>% summarise( link_density = sum( link_rate )) -> italia_links_year
italia_intra_links %>% group_by( year ) %>% arrange( year ) %>% summarise( link_density = sum( link_rate )) -> italia_intra_links_year

library(ggplot2)

ggplot( italia_links_year, aes(x=year,y=link_density,color="Total"))+ geom_line()+
  geom_line(data=italia_intra_links_year,aes(y=link_density,color="Intra"))+theme_minimal()

italia_extra_links <- italia_links %>% filter(!(hoard == "Italia" & mint=="Italia"))
italia_extra_links%>% group_by( year ) %>% arrange( year ) %>% summarise( link_density = sum( link_rate )) -> italia_extra_links_year

library(ecp)
z_links <- matrix(c(italia_extra_links_year$link_density, Italia_intra_links_year$link_density), ncol=2)

multi_changepoint <- e.divisive(z_links, min.size=100)
multi_changepoint_year <- italia_extra_links_year$year[multi_changepoint$estimate[2]]

multi_changepoint_50y <- e.divisive(z_links, min.size=50)
multi_changepoint_year_50y <- italia_extra_links_year$year[multi_changepoint_50y$estimate[2]]

library(igraph)

italia_links_for_graph <- italia_links %>% rename( from=hoard, to=mint)

library(dplyr)

italia_links_combined <- italia_links_for_graph %>%
  filter(!startsWith(from, "Unknown") & !startsWith(to, "Unknown")) %>%
  mutate(
    standardized_from = pmin(from, to),
    standardized_to = pmax(from, to)
  ) %>%
  # Group by the new node pair and the year
  group_by(from = standardized_from, to = standardized_to, year) %>%
  # Sum the link rates for the combined directions
  summarise(link_rate = sum(link_rate), .groups = "drop")

pre_cp_data <- italia_links_combined %>%
  filter( year <= multi_changepoint_year) %>%
  summarise( .by=c(from,to), weight = sum(link_rate))

italia_pre_cp_graph <- graph_from_data_frame( pre_cp_data,
                                              directed=F )

library(ggraph)
# Note: Ensure your network object (e.g., igraph or tbl_graph) is loaded
# Replace 'your_graph_object' with the actual name of your graph variable

ggraph(italia_pre_cp_graph, layout = 'stress') +

  # 1. Map edge weights to line thickness
  geom_edge_link(aes(linewidth = weight), color = "gray60", alpha = 0.6) +
 # scale_edge_width(range = c(0.5, 3), name = "Link Rate") +

  # 2. Style the nodes
  geom_node_point(size = 7, fill = "#E69F00", color = "black", shape = 21) +

  # 3. Add labels that automatically repel away from each other
  geom_node_text(aes(label = name),
                 repel = TRUE,
                 size = 4,
                 color = "#002B5B",
                 bg.color = "white", # Adds a slight white halo for readability
                 bg.r = 0.15) +

  # 4. Clean up the background
  theme_graph() +
  theme(legend.position = "bottom")

post_cp_data <- italia_links_combined %>%
  filter( year >= multi_changepoint_year) %>%
  summarise( .by=c(from,to), weight = sum(link_rate))

italia_post_cp_graph <- graph_from_data_frame( post_cp_data,
                                              directed=F )


ggraph(italia_post_cp_graph, layout = 'stress') +

  # 1. Map edge weights to line thickness
  geom_edge_link(aes(linewidth = weight), color = "gray60", alpha = 0.6) +
  # scale_edge_width(range = c(0.5, 3), name = "Link Rate") +

  # 2. Style the nodes
  geom_node_point(size = 7, fill = "#E69F00", color = "black", shape = 21) +

  # 3. Add labels that automatically repel away from each other
  geom_node_text(aes(label = name),
                 repel = TRUE,
                 size = 4,
                 color = "#002B5B",
                 bg.color = "white", # Adds a slight white halo for readability
                 bg.r = 0.15) +

  # 4. Clean up the background
  theme_graph() +
  theme(legend.position = "bottom")

library(networkD3)

italia_pre_partners <- pre_cp_data %>%
  filter(from == "Italia" | to == "Italia") %>%
  mutate(partner = if_else(from == "Italia", to, from)) %>%
  select(partner, weight) %>%
  slice_max( weight, n = 10 )

italia_post_partners <- post_cp_data %>%
  filter(from == "Italia" | to == "Italia") %>%
  mutate(partner = if_else(from == "Italia", to, from)) %>%
  select(partner, weight) %>%
  slice_max( weight, n = 10 )

sankey_nodes <- data.frame(
  name = c(paste0("Pre: ", italia_pre_partners$partner),
           "Italia",
           paste0("Post: ", italia_post_partners$partner))
)

italia_node_index <- nrow(italia_pre_partners) # 0-based index of "Italia" node

sankey_links <- rbind(
  data.frame(
    source = seq_len(nrow(italia_pre_partners)) - 1,
    target = italia_node_index,
    value = italia_pre_partners$weight
  ),
  data.frame(
    source = italia_node_index,
    target = italia_node_index + seq_len(nrow(italia_post_partners)),
    value = italia_post_partners$weight
  )
)

sankeyNetwork(Links = sankey_links, Nodes = sankey_nodes,
              Source = "source", Target = "target", Value = "value",
              NodeID = "name", fontSize = 12, nodeWidth = 30)

