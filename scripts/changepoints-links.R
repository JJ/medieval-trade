library(dplyr)

links <- read.csv("data/all-iberian-links.csv",sep=";")
links$decade <- floor( links$year / 10 ) * 10

links %>% group_by(decade) %>%
  summarise(n = n()) -> links_decade

for (decade in seq(min(links_decade$decade), max(links_decade$decade), 10)) {
  if ( !decade %in% links_decade$decade ) {
    links_decade <- rbind(links_decade, data.frame(decade=decade, n=0))
  }
}

saveRDS(links_decade, "data/all_iberian_links_decade.rds")
saveRDS(links, "data/all_iberian_links.rds")

links <- read.csv("data/iberian-links.csv",sep=";")
links$decade <- floor( links$year / 10 ) * 10

links %>% group_by(decade) %>% summarise(n = n()) -> links_decade

for (decade in seq(min(links_decade$decade), max(links_decade$decade), 10)) {
  if ( !decade %in% links_decade$decade ) {
    links_decade <- rbind(links_decade, data.frame(decade=decade, n=0))
  }
}

saveRDS(links_decade, "data/iberian_links_decade.rds")
saveRDS(links, "data/iberian_links.rds")
