
links_year <- readRDS("data/links_year.rds")
links_year$links <- links_year$n
links_year$n <- NULL

library(dplyr)
library(tidyr)

links_year <- links_year %>%
  complete(year = full_seq(year, 1), fill = list(links = 0))

links_year <- links_year %>%
  filter(year >= 300 & year <= 775)

library(changepoint)

link.changepoint <- cpt.meanvar(links_year$links)
link.changepoint.date <- links_year$year[link.changepoint@cpts]
ticks <- c(1,100,200,300,400,500,600)
ticks.years <- links_year$year[ticks]

# set y label to "# links"

plot(link.changepoint,xaxt = 'n', ylab="# Links", main="Number of links per year and mean before/after changepoint")
axis(1, at = ticks, labels=ticks.years)


