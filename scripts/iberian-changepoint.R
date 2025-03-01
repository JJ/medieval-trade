
links_decade_raw <- readRDS("data/iberian_links_decade.rds")

links_decade <- links_decade_raw[order(links_decade_raw$decade),]
links_decade$links <- links_decade$n
links_decade$n <- NULL

library(changepoint)

link.changepoint <- cpt.mean(links_decade$links)
link.changepoint.date <- links_decade$decade[link.changepoint@cpts]
ticks <- c(1,10,20,30,40)
ticks.years <- links_decade$decade[ticks]

plot(link.changepoint,xaxt = 'n')
axis(1, at = ticks, labels=ticks.years)

all_links_decade_raw <- readRDS("data/all_iberian_links_decade.rds")
all_links_decade <- all_links_decade_raw[order(all_links_decade_raw$decade),]
all_links_decade$links <- all_links_decade$n
all_links_decade$n <- NULL

all.link.changepoint <- cpt.mean(all_links_decade$links)
all.link.changepoint.date <- all_links_decade$decade[all.link.changepoint@cpts]
ticks <- c(1,10,20,30,40,50,60)
ticks.years <- all_links_decade$decade[ticks]

plot(all.link.changepoint,xaxt = 'n')
axis(1, at = ticks, labels=ticks.years)
