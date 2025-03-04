library(ggplot2)

mints.decade <- read.csv("data-raw/number-of-mints-decade.csv", sep=";")

ggplot( mints.decade, aes(x=Decade, y=Mints)) + geom_point() + geom_smooth() +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(title = "Mints in Iberia by Decade",
       x = "Decade",
       y = "Number of Mints")

saveRDS(mints.decade, "data/mints_decade.rds")
