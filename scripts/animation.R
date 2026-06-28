library(tidyverse)
library(maps)
library(gganimate)

# 1. Load the dataset
trade_data <- read_delim("data/annual-regional-links.csv", delim = ";", show_col_types = FALSE)

# 2. Define coordinates for your specific dataset regions
# Anchored to modern main cities. Expanded to include more of your specific list.
regions_coords <- tribble(
  ~region, ~lon, ~lat,
  "Iberian Peninsula", -3.7038, 40.4168, # Madrid
  "Gallia", 2.3522, 48.8566,             # Paris
  "Britannia", -0.1276, 51.5072,         # London
  "Italia", 12.4964, 41.9028,            # Rome
  "Germany", 10.4515, 51.1657,           # Central Germany
  "Greece", 23.7275, 37.9838,            # Athens
  "Egypt", 31.2333, 30.0444,             # Cairo
  "Anatolia", 32.8597, 39.9334,          # Ankara
  "Hungary", 19.0402, 47.4979,           # Budapest
  "Austria", 16.3738, 48.2082,           # Vienna
  "Algeria", 3.0588, 36.7538,            # Algiers
  "Tunisia", 10.1658, 36.8065,           # Tunis (Carthage)
  "Syria", 36.2913, 33.5138,             # Damascus
  "Palestina", 35.2137, 31.7683          # Jerusalem
  # You can continue adding the remaining regions from your list here using the exact spelling
)

# 3. Data Wrangling
map_data <- trade_data %>%
  # Filter out intra-regional trade and any region starting with "Unknown"
  filter(
    region1 != region2,
    !str_starts(region1, "Unknown"),
    !str_starts(region2, "Unknown")
  ) %>%
  left_join(regions_coords, by = c("region1" = "region")) %>%
  rename(lon1 = lon, lat1 = lat) %>%
  left_join(regions_coords, by = c("region2" = "region")) %>%
  rename(lon2 = lon, lat2 = lat) %>%
  drop_na() # Drops regions not yet defined in regions_coords

# 4. The Time Warp (Slowing down 350-500 AD)
anim_data <- map_data %>%
  mutate(frame_repeats = if_else(year >= 350 & year <= 500, 5, 1)) %>%
  uncount(frame_repeats)

# 5. Fetch basic polygon map data (No sf/GDAL required!)
world_map <- map_data("world")

# 6. Build the plot
p <- ggplot() +
  # Map layer: using standard polygons instead of sf objects
  geom_polygon(
    data = world_map,
    aes(x = long, y = lat, group = group),
    fill = "#f4f1e1", color = "#cccccc", linewidth = 0.2
  ) +
  # Trade links layer
  geom_curve(
    data = anim_data,
    aes(x = lon1, y = lat1, xend = lon2, yend = lat2, linewidth = value, color = value),
    curvature = 0.2, alpha = 0.8
  ) +
  scale_linewidth_continuous(range = c(0.5, 4), guide = "none") +
  scale_color_viridis_c(option = "magma", direction = -1, guide = "none") +
  # Frame the map and fix the aspect ratio so it doesn't look stretched
  coord_fixed(xlim = c(-15, 45), ylim = c(30, 60), ratio = 1.3, expand = FALSE) +
  theme_void() +
  theme(
    panel.background = element_rect(fill = "#cce5df", color = NA),
    plot.title = element_text(size = 20, face = "bold", hjust = 0.5, margin = margin(t = 15, b = 15))
  ) +
  # Animation configuration
  labs(title = "Trade Link Probabilities\nYear: {current_frame}") +
  transition_manual(year)

# 7. Render
animate(
  p,
  nframes = nrow(distinct(anim_data, year)) * 2,
  fps = 10,
  width = 900,
  height = 600,
  renderer = gifski_renderer("historical_trade_links.gif")
)
