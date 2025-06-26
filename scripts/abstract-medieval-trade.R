## ----statphys.abs, echo=FALSE, message=F, fig.height=4, fig.pos="h"-------------------------------------------------------------------------------
links_year <- readRDS("data/links_year.rds")
links_year$links <- links_year$n
links_year$n <- NULL
# fill with 0s any value of year that is missing
library(dplyr)
library(tidyr)

links_year <- links_year %>%
  complete(year = full_seq(year, 1), fill = list(links = 0))

# limit the data frame to the rows bwtween year 300 and 775

links_year <- links_year %>%
  filter(year >= 300 & year <= 775)

library(changepoint)

link.changepoint <- cpt.meanvar(links_year$links)
link.changepoint.date <- links_year$year[link.changepoint@cpts]
ticks <- c(1,100,200,300,400,500,600)
ticks.years <- links_year$year[ticks]

plot(link.changepoint,xaxt = 'n')
axis(1, at = ticks, labels=ticks.years)


