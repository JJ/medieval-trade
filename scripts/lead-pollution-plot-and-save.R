library(ggplot2)

lead.pollution <- read.csv("data/pollution-data.csv",sep=";")
ggplot(lead.pollution, aes(x=decade, y=averagePg)) + geom_point() + geom_smooth()

saveRDS(lead.pollution, "data/lead_pollution_decade.rds")
