
pollution_data <- read.csv("data/pollution-data.csv", sep=";")
iberian_links_decade <- readRDS("data/all_iberian_links_decade.rds")

pollution_links <- merge(pollution_data, iberian_links_decade, by="decade")

library(ggplot2)

ggplot(pollution_links,aes(x=averagePg,y=n))+geom_point()

model <- glm(n ~ averagePg, data=pollution_links)
summary(model)

iberian_links_decade <- readRDS("data/iberian_links_decade.rds")
pollution_links <- merge(pollution_data, iberian_links_decade, by="decade")
ggplot(pollution_links,aes(x=averagePg,y=n))+geom_point()

model <- glm(n ~ averagePg, data=pollution_links)
summary(model)
