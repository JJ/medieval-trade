library(dplyr)

lead.pollution.raw <- read.csv("data-raw/lead-pollution-from-pnas.csv",sep=";")

# Compute average lead pollution by decade
#
lead.pollution.raw %>%
