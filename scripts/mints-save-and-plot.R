library(ggplot2)

mints.decade <- read.csv("data-raw/mints_decade.csv")

ggplot( mints.decade, aes(x=decade, y=mints)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  labs(title = "Mints in Iberia by Decade",
       x = "Decade",
       y = "Number of Mints")