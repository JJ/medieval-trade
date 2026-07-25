library(dplyr)
italia_links <- readRDS("data/flame-time-series-April-2026-filtered.rds") %>% filter( !is.na(link_rate) & (hoard == "Italia" | mint=="Italia") )

Italia_intra_links <- italia_links %>% filter(hoard == "Italia" & mint=="Italia")

italia_links %>% mutate( year_group = floor( year / 5 ) * 5 ) %>% group_by( year_group ) %>% arrange( year_group ) %>% summarise( total_link_rate = sum( link_rate )) -> italia_links_year
Italia_intra_links %>% mutate( year_group = floor( year / 5 ) * 5 ) %>% group_by( year_group ) %>% arrange( year_group ) %>% summarise( total_link_rate = sum( link_rate )) -> Italia_intra_links_year

library(ggplot2)

ggplot( italia_links_year, aes(x=year_group,y=total_link_rate,color="Total"))+ geom_line()+
  geom_line(data=Italia_intra_links_year,aes(y=total_link_rate,color="Intra"))+theme_minimal()
