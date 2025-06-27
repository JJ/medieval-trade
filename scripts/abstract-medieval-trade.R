
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
png("statphys-changepoint.png",width=2000, height=1500, units="px")
par(mar = c(5.1, 8.1, 4.1, 2.1))
plot(link.changepoint,yaxt='n',xaxt = 'n', xlab="", ylab="", main="Number of links per year and mean before/after changepoint", cex=3, cex.main=3, cex.lab=4, cex.axis=3, cex.sub=3)
# move position of tick labels down so that it does not overlaps ticks
offset <- -0.05
axis(1, at = ticks, labels=ticks.years, cex=3, cex.axis=3)
axis(2, cex=3,cex.axis=3)
mtext("# Links", side=2, line=5, cex=3)
mtext("Year", side=1, line=4, cex=3)
dev.off()


