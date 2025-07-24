
pollution_data <- read.csv("data/pollution-data.csv", sep=";")
links_decade <- readRDS("data/links_year.rds")
links_decade$decade <- links_decade$year

pollution_links <- merge(pollution_data, links_decade, by="decade")

library(ggplot2)

ggplot(pollution_links,aes(x=averagePg,y=n))+geom_point()

model <- lm(averagePg ~ n, data=pollution_links )
summary(model)

iberian_links_decade <- readRDS("data/iberian_links_decade.rds")
pollution_links <- merge(pollution_data, iberian_links_decade, by="decade")
ggplot(pollution_links,aes(x=averagePg,y=n))+geom_point()

model <- lm(averagePg ~ n, data=pollution_links)
summary(model)

# find cross-correlation between the time series of lead pollution and the number of links

pollution_ts <- ts(pollution_data$averagePg, start=min(pollution_data$decade), frequency=10)
links_ts <- ts(links_decade$n, start=min(links_decade$decade), frequency=10)
cross_correlation <- ccf(pollution_ts, links_ts, lag.max=10)
plot(cross_correlation, main="Cross-Correlation between Lead Pollution and Links", xlab="Lag", ylab="Cross-Correlation")


