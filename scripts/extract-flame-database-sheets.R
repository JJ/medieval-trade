#!/usr/bin/env Rscript
# Extracts CoinFindings, coin_groups and Mints sheets from the flame database
# spreadsheet into separate CSV files.
#
# Usage: Rscript scripts/extract-flame-database-sheets.R <path-to-xlsx> <release-date>

library(readxl)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  stop("Usage: Rscript extract-flame-database-sheets.R <path-to-xlsx> <release-date>")
}

xlsx_path <- args[1]
release_date <- args[2]

sheets <- c("CoinFindings" = "coinFindings",
            "coin_groups" = "coin_groups",
            "Mints" = "Mints")

for (sheet_name in names(sheets)) {
  data <- read_excel(xlsx_path, sheet = sheet_name)
  out_file <- file.path("data-raw",
                         sprintf("flame-database-%s-%s.csv", release_date, sheets[[sheet_name]]))
  write.csv(data, out_file, row.names = FALSE)
  cat(sprintf("Wrote %s\n", out_file))
}
