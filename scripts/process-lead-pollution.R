library(dplyr)

lead_pollution_raw <- read.csv("data-raw/lead-pollution-mcconnell.csv", sep=";")

#convert year before 1950 to CE
lead_pollution_raw$year_ce <- 1950 - lead_pollution_raw$year
