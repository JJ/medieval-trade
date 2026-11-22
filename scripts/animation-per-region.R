library(tidyverse)
library(maps)
library(gganimate)

# Animated ego network of a single region: every link between that region
# and any other region, year by year. Uses the same data and workflow as
# wivace26.Rnw.
#
# Usage (from the project root):
#   Rscript scripts/animation-per-region.R             # Italia
#   Rscript scripts/animation-per-region.R Anatolia
#   Rscript scripts/animation-per-region.R Hispania    # = "Iberian Peninsula"

# 0. Pick the focal region
args <- commandArgs(trailingOnly = TRUE)
focal_region <- if (length(args) >= 1) args[1] else "Italia"

# Aliases for names that differ from the ones used in the dataset
region_aliases <- c("Hispania" = "Iberian Peninsula")
if (focal_region %in% names(region_aliases)) {
  focal_region <- region_aliases[[focal_region]]
}

# 1. Load the dataset (same source as wivace26.Rnw)
trade_data <- readRDS("data/flame-time-series-April-2026-filtered.rds") %>%
  filter(!is.na(link_rate)) %>%
  # The dataset uses both spellings; they are the same territory on the map
  mutate(across(c(hoard, mint), ~ if_else(.x == "Palestine", "Palestina", .x)))

# 2. Coordinates for every region in the dataset
# Anchored to a main (modern or historical) city for each region.
regions_coords <- tribble(
  ~region, ~lon, ~lat,
  "Iberian Peninsula", -3.7038, 40.4168,    # Madrid
  "Gallia", 2.3522, 48.8566,                # Paris
  "Britannia", -0.1276, 51.5072,            # London
  "Ireland", -6.2603, 53.3498,              # Dublin
  "Italia", 12.4964, 41.9028,               # Rome
  "Germany", 10.4515, 51.1657,              # Central Germany
  "Greece", 23.7275, 37.9838,               # Athens
  "Egypt", 31.2333, 30.0444,                # Cairo
  "Anatolia", 32.8597, 39.9334,             # Ankara
  "Hungary", 19.0402, 47.4979,              # Budapest
  "Austria", 16.3738, 48.2082,              # Vienna
  "Algeria", 3.0588, 36.7538,               # Algiers
  "Tunisia", 10.1658, 36.8065,              # Tunis (Carthage)
  "Syria", 36.2913, 33.5138,                # Damascus
  "Palestina", 35.2137, 31.7683,            # Jerusalem
  "Afghanistan", 69.2075, 34.5553,          # Kabul
  "Albania", 19.8187, 41.3275,              # Tirana
  "Armenia", 44.5152, 40.1872,              # Yerevan
  "Azerbaijan", 49.8671, 40.4093,           # Baku
  "Belarus", 27.5615, 53.9045,              # Minsk
  "Belgium", 4.3517, 50.8503,               # Brussels
  "Bosnia & Herzegovina", 18.4131, 43.8563, # Sarajevo
  "Bulgaria", 23.3219, 42.6977,             # Sofia
  "China", 108.9402, 34.3416,               # Xi'an (Chang'an)
  "Croatia", 15.9819, 45.8150,              # Zagreb
  "Cyprus", 33.3823, 35.1856,               # Nicosia
  "Czech Republic", 14.4378, 50.0755,       # Prague
  "Estonia", 24.7536, 59.4370,              # Tallinn
  "Ethiopia", 38.7183, 14.1211,             # Aksum
  "Finland", 24.9384, 60.1699,              # Helsinki
  "Georgia", 44.7930, 41.7151,              # Tbilisi
  "India", 77.2090, 28.6139,                # Delhi
  "Iran", 51.3890, 35.6892,                 # Tehran
  "Iraq", 44.3661, 33.3152,                 # Baghdad
  "Japan", 135.8048, 34.6851,               # Nara
  "Jordan", 35.9106, 31.9539,               # Amman
  "Kazakhstan", 76.8512, 43.2220,           # Almaty
  "Kyrgyzstan", 74.5698, 42.8746,           # Bishkek
  "Latvia", 24.1052, 56.9496,               # Riga
  "Lebanon", 35.5018, 33.8938,              # Beirut
  "Libya", 13.1913, 32.8872,                # Tripoli
  "Liechtenstein", 9.5209, 47.1410,         # Vaduz
  "Lithuania", 25.2797, 54.6872,            # Vilnius
  "Luxembourg", 6.1296, 49.6116,            # Luxembourg
  "Macedonia", 21.4314, 41.9981,            # Skopje
  "Moldova", 28.8638, 47.0105,              # Chisinau
  "Montenegro", 19.2594, 42.4304,           # Podgorica
  "Morocco", -6.8498, 34.0209,              # Rabat
  "Netherlands", 4.9041, 52.3676,           # Amsterdam
  "Oman", 58.4059, 23.5880,                 # Muscat
  "Pakistan", 72.8300, 33.7400,             # Taxila
  "Poland", 21.0122, 52.2297,               # Warsaw
  "Romania", 26.1025, 44.4268,              # Bucharest
  "Russia", 37.6173, 55.7558,               # Moscow
  "Saudi Arabia", 46.6753, 24.7136,         # Riyadh
  "Scandinavia", 18.0686, 59.3293,          # Stockholm
  "Serbia", 20.4489, 44.7866,               # Belgrade
  "Slovakia", 17.1077, 48.1486,             # Bratislava
  "Slovenia", 14.5058, 46.0569,             # Ljubljana
  "Somalia", 45.3182, 2.0469,               # Mogadishu
  "Sudan", 33.7500, 16.9400,                # Meroe
  "Switzerland", 7.4474, 46.9480,           # Bern
  "Tajikistan", 68.7870, 38.5598,           # Dushanbe
  "Turkmenistan", 58.3261, 37.9601,         # Ashgabat
  "Ukraine", 30.5234, 50.4501,              # Kyiv
  "United Arab Emirates", 54.3773, 24.4539, # Abu Dhabi
  "Uzbekistan", 66.9597, 39.6542,           # Samarkand
  "Yemen", 45.3256, 15.4300                 # Marib
)

if (!focal_region %in% regions_coords$region) {
  stop("Unknown region '", focal_region, "'. Available: ",
       paste(sort(regions_coords$region), collapse = ", "))
}

# 3. Data Wrangling: all links between the focal region and any other region.
# Both directions (focal as hoard or as mint) are summed, as in wivace26.Rnw,
# and the focal region is always the origin of the curve.
map_data <- trade_data %>%
  filter(
    hoard != mint,
    !startsWith(hoard, "Unknown"),
    !startsWith(mint, "Unknown"),
    hoard == focal_region | mint == focal_region
  ) %>%
  mutate(partner = if_else(hoard == focal_region, mint, hoard)) %>%
  summarise(value = sum(link_rate), .by = c(partner, year)) %>%
  left_join(regions_coords, by = c("partner" = "region")) %>%
  rename(lon2 = lon, lat2 = lat) %>%
  mutate(
    lon1 = regions_coords$lon[regions_coords$region == focal_region],
    lat1 = regions_coords$lat[regions_coords$region == focal_region]
  )

missing_coords <- map_data %>% filter(is.na(lon2)) %>% distinct(partner) %>% pull(partner)
if (length(missing_coords) > 0) {
  warning("No coordinates for: ", paste(missing_coords, collapse = ", "),
          ". Add them to regions_coords; these links are dropped.")
}
map_data <- map_data %>% drop_na()

if (nrow(map_data) == 0) {
  stop("No links found for region '", focal_region, "'.")
}

# 4. The Time Warp (Slowing down 350-500 AD)
anim_data <- map_data %>%
  mutate(frame_repeats = if_else(year >= 350 & year <= 500, 5, 1)) %>%
  uncount(frame_repeats)

# 5. Total trade of the focal region per year: every link involving it,
# including intra-regional and unknown-partner links, as the "Total" series
# in wivace26.Rnw
frame_years <- sort(unique(anim_data$year))
focal_totals <- trade_data %>%
  filter(hoard == focal_region | mint == focal_region) %>%
  summarise(total = sum(link_rate), .by = year) %>%
  right_join(tibble(year = seq(min(frame_years), max(frame_years))), by = "year") %>%
  mutate(total = replace_na(total, 0)) %>%
  arrange(year)

# 6. Fetch basic polygon map data (No sf/GDAL required!)
world_map <- map_data("world")
focal_point <- regions_coords %>% filter(region == focal_region)

# Whole Mediterranean basin (east and west) up to just North of Denmark
# and just East of Syria.
# Links to regions outside this frame (Scandinavia, Mesopotamia, Asia...)
# are still drawn and run off the edge of the map in their direction.
map_xlim <- c(-12, 43.5)
ylim <- c(24, 58.5)

# Side chart, drawn in map coordinates on a strip left of the map
# (gganimate can't animate patchwork compositions).
# Year runs top to bottom, total trade density left to right.
chart_strip <- c(-41, map_xlim[1])
chart_x <- c(-36, -14.5)
chart_y <- c(ylim[1] + 2, ylim[2] - 6)
xlim <- c(chart_strip[1], map_xlim[2])

year_range <- range(focal_totals$year)
max_total <- max(focal_totals$total)
year_to_y <- function(y) chart_y[2] - (y - year_range[1]) / diff(year_range) * diff(chart_y)
total_to_x <- function(t) chart_x[1] + t / max_total * diff(chart_x)

# Static layers must not have a `year` column, or transition_manual
# would filter them; the series uses `yr` instead.
chart_series <- focal_totals %>%
  transmute(yr = year, x = total_to_x(total), y = year_to_y(year))
chart_ticks <- tibble(yr = seq(ceiling(year_range[1] / 100) * 100, year_range[2], by = 100)) %>%
  mutate(y = year_to_y(yr))
# Per-frame layers keep `year`, so only the current one is shown
chart_marker <- focal_totals %>%
  filter(year %in% frame_years) %>%
  mutate(x = total_to_x(total), y = year_to_y(year))
focal_sized <- focal_totals %>%
  filter(year %in% frame_years) %>%
  mutate(lon = focal_point$lon, lat = focal_point$lat)

# 7. Build the plot
p <- ggplot() +
  # Map layer: using standard polygons instead of sf objects
  geom_polygon(
    data = world_map,
    aes(x = long, y = lat, group = group),
    fill = "#f4f1e1", color = "#cccccc", linewidth = 0.2
  ) +
  # White strip for the side chart, covering the map underneath
  annotate("rect", xmin = chart_strip[1], xmax = chart_strip[2],
           ymin = ylim[1], ymax = ylim[2], fill = "white") +
  annotate("segment", x = chart_strip[2], xend = chart_strip[2],
           y = ylim[1], yend = ylim[2], color = "grey60", linewidth = 0.4) +
  # Trade links layer
  geom_curve(
    data = anim_data,
    aes(x = lon1, y = lat1, xend = lon2, yend = lat2, linewidth = value, color = value),
    curvature = 0.2, alpha = 0.8
  ) +
  # Side chart: header, year gridlines and labels, density axis
  # Title lives here: gganimate (with ggplot2 >= 4.0) ignores the
  # plot.title theme, leaving a small plain title that clips at the top
  annotate("text", x = chart_strip[1] + 1, y = ylim[2] - 0.8,
           label = paste("Trade Link Density:", focal_region),
           hjust = 0, vjust = 1, size = 8, fontface = "bold", color = "#002B5B") +
  annotate("text", x = chart_x[1], y = ylim[2] - 3.6, label = "Total trade density",
           hjust = 0, vjust = 1, size = 5.5, fontface = "bold", color = "grey30") +
  geom_segment(
    data = chart_ticks,
    aes(x = chart_x[1], xend = chart_x[2], y = y, yend = y),
    color = "grey90", linewidth = 0.3
  ) +
  geom_text(
    data = chart_ticks,
    aes(x = chart_x[1] - 0.6, y = y, label = yr),
    hjust = 1, size = 4.5, color = "grey30"
  ) +
  annotate("text", x = chart_x, y = chart_y[1] - 0.6,
           label = c("0", format(signif(max_total, 2), big.mark = ",")),
           hjust = c(0, 1), vjust = 1, size = 4.5, color = "grey30") +
  # Side chart: full series, filled so it reads as a horizontal area chart
  geom_ribbon(
    data = chart_series,
    aes(y = y, xmin = chart_x[1], xmax = x),
    orientation = "y", fill = "#b2182b", alpha = 0.25
  ) +
  geom_path(data = chart_series, aes(x = x, y = y), color = "#b2182b", linewidth = 0.5) +
  # Side chart: current year marker
  geom_segment(
    data = chart_marker,
    aes(x = chart_x[1], xend = chart_x[2], y = y, yend = y),
    color = "#002B5B", linewidth = 0.6
  ) +
  geom_point(
    data = chart_marker,
    aes(x = x, y = y),
    shape = 21, size = 4, fill = "#b2182b", color = "#002B5B", stroke = 1
  ) +
  # Focal region, area proportional to its total trade that year,
  # over a small fixed dot so the capital is visible even in quiet years
  geom_point(
    data = focal_point,
    aes(x = lon, y = lat),
    shape = 21, size = 2.5, fill = "#b2182b", color = "white", stroke = 0.6
  ) +
  geom_point(
    data = focal_sized,
    aes(x = lon, y = lat, size = total),
    shape = 21, fill = "#b2182b", color = "white", stroke = 1, alpha = 0.9
  ) +
  scale_size_area(max_size = 18, guide = "none") +
  scale_linewidth_continuous(range = c(0.5, 4), guide = "none") +
  # Truncate magma before its pale-yellow end so the weakest links (coral)
  # stand out against both the cream land and the pale teal sea;
  # strongest links are near-black purple.
  scale_color_viridis_c(option = "magma", direction = -1, begin = 0, end = 0.75, guide = "none") +
  # Frame the map and fix the aspect ratio so it doesn't look stretched
  coord_fixed(xlim = xlim, ylim = ylim, ratio = 1.3, expand = FALSE) +
  theme_void() +
  theme(
    panel.background = element_rect(fill = "#cce5df", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  ) +
  # Year drawn inside the map (top-left, over the Atlantic) instead of in
  # the title (see the title note in the side chart).
  geom_text(
    data = distinct(anim_data, year),
    aes(x = map_xlim[1] + 0.7, y = ylim[2] - 1, label = paste("Year", year)),
    hjust = 0, vjust = 1, size = 9, fontface = "bold", color = "#002B5B"
  ) +
  # Animation configuration
  transition_manual(year)

# 8. Render
region_slug <- focal_region %>% str_to_lower() %>% str_replace_all("[^a-z0-9]+", "-")
animate(
  p,
  nframes = nrow(distinct(anim_data, year)) * 2,
  fps = 10,
  width = 1600,
  height = 900,
  renderer = gifski_renderer(paste0("historical_trade_links_", region_slug, ".gif"))
)
