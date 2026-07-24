#!/usr/bin/env Rscript
# Filters the flame time series data, dropping hoards with an invalid or
# 100+ year span, and expands the remaining rows into one row per year with
# a link_rate column (num_coins divided by the number of years in the span).
#
# Usage: Rscript scripts/filter-flame-time-series.R <path-to-csv>

library(dplyr)
library(tidyr)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop("Usage: Rscript filter-flame-time-series.R <path-to-csv>")
}

in_file <- args[1]

flame <- read.csv(in_file, sep = ";")

flame.expanded <- flame |>
  mutate(span = end_year - start_year) |>
  filter(span >= 0, span < 100) |>
  mutate(n_rows = pmax(span, 1),
         link_rate = num_coins / n_rows) |>
  select(hoard, mint, start_year, link_rate, n_rows) |>
  uncount(n_rows, .id = "offset") |>
  mutate(year = start_year + offset - 1) |>
  select(hoard, mint, year, link_rate) |>
  as.data.frame()

out_file <- file.path(dirname(in_file),
                       paste0(tools::file_path_sans_ext(basename(in_file)),
                              "-filtered.rds"))
saveRDS(flame.expanded, out_file)
cat(sprintf("Wrote %s (%d rows)\n", out_file, nrow(flame.expanded)))
