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

