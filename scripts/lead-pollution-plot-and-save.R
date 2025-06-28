library(ggplot2)
library(ggthemes)

lead.pollution <- read.csv("data/pollution-data.csv",sep=";")
ggplot(lead.pollution, aes(x=decade, y=averagePg)) + geom_point() + geom_smooth() + theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))
# Save the plot
ggsave("lead_pollution_decade.png", width = 6, height = 10)

saveRDS(lead.pollution, "data/lead_pollution_decade.rds")
