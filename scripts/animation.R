library(tidyverse)
library(sf)
library(rnaturalearth)
library(gganimate)

# 1. Load the dataset
# Based on your data structure, it uses a semicolon delimiter
trade_data <- read_delim("annual-regional-links.csv", delim = ";", show_col_types = FALSE)

# 2. Define coordinates for ancient regions
# Anchored to modern main cities. You can add more regions here as needed for your full dataset.
regions_coords <- tribble(
  ~region, ~lon, ~lat,
  "Iberian Peninsula", -3.7038, 40.4168, # Madrid
  "Gallia", 2.3522, 48.8566,             # Paris
  "Britannia", -0.1276, 51.5072,         # London
  "Italia", 12.4964, 41.9028,            # Rome
  "Germania", 10.4515, 51.1657,          # Central Germany
  "Achaea", 23.7275, 37.9838,            # Athens
  "Carthago", 10.1658, 36.8065,          # Tunis
  "Aegyptus", 29.9245, 31.2001,          # Alexandria
  "Anatolia", 32.8597, 39.9334           # Ankara
)

# 3. Data Wrangling
map_data <- trade_data %>%
  # Filter out intra-regional trade (e.g., Iberia to Iberia) to prevent drawing errors with curves
  filter(region1 != region2) %>%
  # Attach coordinates for the origin region
  left_join(regions_coords, by = c("region1" = "region")) %>%
  rename(lon1 = lon, lat1 = lat) %>%
  # Attach coordinates for the destination region
  left_join(regions_coords, by = c("region2" = "region")) %>%
  rename(lon2 = lon, lat2 = lat) %>%
  drop_na() # Ensures we only plot regions we have coordinates for

# 4. The Time Warp (Slowing down 350-500 AD)
# By duplicating the rows for the years 350-500, gganimate will natively spend more frames on them.
# The 'uncount' function repeats rows 'n' times without altering the actual year label.
anim_data <- map_data %>%
  mutate(frame_repeats = if_else(year >= 350 & year <= 500, 5, 1)) %>%
  uncount(frame_repeats)

# 5. Fetch basemap
# Cropping to Europe/Mediterranean naturally places the Iberian Peninsula on the far left.
europe_map <- ne_countries(scale = "medium", returnclass = "sf")

# 6. Build the plot
p <- ggplot() +
  # Map layer
  geom_sf(data = europe_map, fill = "#f4f1e1", color = "#cccccc") +
  # Trade links layer
  geom_curve(
    data = anim_data,
    aes(x = lon1, y = lat1, xend = lon2, yend = lat2, linewidth = value, color = value),
    curvature = 0.2, alpha = 0.8
  ) +
  # Map the connection value to linewidth (and add a subtle color gradient for visual depth)
  scale_linewidth_continuous(range = c(0.5, 4), guide = "none") +
  scale_color_viridis_c(option = "magma", direction = -1, guide = "none") +
  # Frame the map around the classical world
  coord_sf(xlim = c(-15, 45), ylim = c(30, 60), expand = FALSE) +
  theme_void() +
  theme(
    panel.background = element_rect(fill = "#cce5df", color = NA),
    plot.title = element_text(size = 20, face = "bold", hjust = 0.5, margin = margin(t = 15, b = 15))
  ) +
  # Animation configuration
  labs(title = "Trade Link Probabilities\nYear: {current_frame}") +
  transition_manual(year)

# 7. Render and save the animation
# Adjust nframes based on your total distinct years + the extra frames from the 350-500 multiplier
animate(
  p,
  nframes = nrow(distinct(anim_data, year)) * 2, # Adjust multiplier for overall smoothness
  fps = 10,
  width = 900,
  height = 600,
  renderer = gifski_renderer("historical_trade_links.gif")
)
