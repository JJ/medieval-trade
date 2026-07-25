library(dplyr)
britannia_links <- readRDS("data/flame-time-series-April-2026-filtered.rds") %>% filter( hoard == "Britannia" | mint=="Britannia")

britannia_intra_links <- britannia_links %>% filter(hoard == "Britannia" & mint=="Britannia")


britannia_links %>% group_by( year ) %>% summarise( total_link_rate = sum( link_rate )) -> britannia_links_year
britannia_intra_links %>% group_by( year ) %>% summarise( total_link_rate = sum( link_rate )) -> britannia_intra_links_year

library(ggplot2)

ggplot( britannia_links_year, aes(x=year,y=total_link_rate,color="Total"))+ geom_line()+
  geom_line(data=britannia_intra_links_year,aes(y=total_link_rate,color="Intra"))+theme_minimal()
