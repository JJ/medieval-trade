## ----statphys.abs, echo=FALSE, message=F, fig.height=4, fig.pos="h"-------------------------------------------------------------------------------
library(ggplot2)
links_year <- readRDS("data/links_year.rds")
links_year$links <- links_year$n
links_year$n <- NULL
# ggplot(links_year, aes(x=year, y=links)) + geom_point() + geom_smooth()

library(changepoint)

link.changepoint <- cpt.mean(links_year$links)
link.changepoint.date <- links_year$year[link.changepoint@cpts]
ticks <- c(1,100,200,300,400)
ticks.years <- links_year$year[ticks]

plot(link.changepoint,xaxt = 'n')
axis(1, at = ticks, labels=ticks.years)


