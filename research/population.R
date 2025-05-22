# Install if necessary
install.packages(c("osmdata", "sf", "tidyverse", "sp", "tmap"))

# Load libraries
library(osmdata)
library(sf)
library(tidyverse)
library(sp)
library(tmap)


# Get bounding box for Winchester
winchester_bb <- getbb("Winchester, Hampshire, UK")
winchesterCity_bb <- matrix(c(-1.390800, 51.033622, -1.274071, 51.117101), byrow = FALSE, ncol = 2)
rownames(winchesterCity_bb) <- c("x", "y")
colnames(winchesterCity_bb) <- c("min", "max")

# Convert to sf polygon (envelope)
bbox_poly <- st_as_sfc(st_bbox(c(
  xmin = winchesterCity_bb["x", "min"],
  ymin = winchesterCity_bb["y", "min"],
  xmax = winchesterCity_bb["x", "max"],
  ymax = winchesterCity_bb["y", "max"]
), crs = 4326)) %>%
  st_transform(27700)  # Match projected CRS

# Set new location of Abbott Barton Barn
new_location <- data.frame(
  name = "Proposed Location",
  lon = -1.3107350275768364,   # Longitude
  lat = 51.07385013114209    # Latitude
)

# Convert to sf and project
new_location_sf <- st_as_sf(new_location, coords = c("lon", "lat"), crs = 4326) %>%
  st_transform(27700)

# Get post offices
post_offices <- opq(bbox = winchesterCity_bb) %>%
  add_osm_feature(key = "amenity", value = "post_office") %>%
  osmdata_sf()

post_office_points <- post_offices$osm_points %>%
  st_transform(27700) %>%
  filter(osm_id!=1128156734) # exclude the one at the top of the high street



# Get convenience stores
shops <- opq(bbox = winchesterCity_bb) %>%
  add_osm_feature(key = "shop", value = c("convenience", "supermarket")) %>%
  osmdata_sf()

# Create a vector of the osm_ids you want to keep.
valid_osm_ids <- c(10226029450, 1125043208, 1144883523, 1144898171, 1145311638, 2637642860, 3036707698, 4591539888, 4962824327, 7659372464, 8200177873)

# Points (already in point format)
shop_points <- shops$osm_points %>%
  st_transform(27700) %>%
  filter(osm_id %in% valid_osm_ids)

# Polygons – convert to centroids
shop_polygons <- shops$osm_polygons %>%
  st_transform(27700) %>%
  st_centroid() %>%
  filter(osm_id != 206006971) # exclude the Hyde Newsagents which is now closed

shop_geometries <- c(
  st_geometry(shop_points),
  st_geometry(shop_polygons),
  st_geometry(new_location_sf)
)

all_shops <- st_sf(geometry = shop_geometries)


# Combine existing post offices with new location
# Ensure both are sf objects with only geometry
post_office_geom <- st_geometry(post_office_points)
new_location_geom <- st_geometry(new_location_sf)

# Combine them into a single sf object
all_post_offices <- st_sf(geometry = c(post_office_geom, new_location_geom))

# post offices first
bbox_post <- st_as_sfc(st_bbox(all_post_offices))

voronoi_post <- st_voronoi(st_union(all_post_offices), envelope = bbox_poly)
voronoi_post_sf <- st_collection_extract(st_sfc(voronoi_post), "POLYGON") %>%
  st_sf() %>%
  st_intersection(bbox_poly)

# Optionally clip to boundary (use the earlier `boundary_poly`)
# voronoi_post_clipped <- st_intersection(voronoi_post_sf, boundary_poly)

# Convenience store
bbox_con <- st_as_sfc(st_bbox(all_shops))

voronoi_con <- st_voronoi(st_union(all_shops), envelope = bbox_poly)
voronoi_con_sf <- st_collection_extract(st_sfc(voronoi_con), "POLYGON") %>%
  st_sf() %>%
  st_intersection(bbox_poly)

# Plot stuff
tmap_mode("view")

# tm_shape(boundary_poly) +
  # tm_borders(lwd = 2) +
  
  # Post Office Areas
  tm_shape(voronoi_post_sf) +
  tm_polygons(col = "skyblue", alpha = 0.3, border.col = "blue", title = "Post Office Areas") +
  
  # Convenience Store Areas
  tm_shape(voronoi_con_sf) +
  tm_polygons(col = "lightgreen", alpha = 0.3, border.col = "green", title = "Convenience Areas") +
  
  # Facilities (points)
  tm_shape(all_post_offices) +
  tm_dots(col = "red", size = 0.1, title = "Post Offices") +
  
  tm_shape(all_shops) +
  tm_dots(col = "darkgreen", size = 0.1, title = "Convenience Stores")


# Find the polygon which contains the proposed location

containing_poly_post <- voronoi_post_sf[st_contains(voronoi_post_sf, new_location_sf, sparse = FALSE), ] %>%
st_transform(4326)

st_write(containing_poly_post, "proposed_location_post_voronoi.geojson", driver = "GeoJSON", delete_dsn = TRUE)

containing_poly_shops <- voronoi_con_sf[st_contains(voronoi_con_sf, new_location_sf, sparse = FALSE), ] %>%
st_transform(4326)

st_write(containing_poly_shops, "proposed_location_shop_voronoi.geojson", driver = "GeoJSON", delete_dsn = TRUE)



# figure out 10 minute walk isochrone
# install.packages("openrouteservice")
# library(openrouteservice)

# ors_api_key("5b3ce3597851110001cf62489e841a6319174b9da2297329777e3d3d")

# Create the isochrone
# iso <- ors_isochrones(
#   coordinates = list(c(-1.3107350275768364, 51.07385013114209)),  # lon, lat
#   profile = "foot-walking",
#   range = 600  # seconds (10 minutes)
# )

# Convert to sf object
# iso_sf <- st_as_sf(iso)
# plot(iso_sf["value"])
# export
# st_write(iso_sf, "walk_isochrone.geojson", driver = "GeoJSON", delete_dsn = TRUE)


# Export points
# Add a type column to each
post_office_points <- post_office_points %>% mutate(type = "post_office")
shop_points <- shop_points %>%
  mutate(type = "shops")
shop_polygons <- shop_polygons %>%
  mutate(type = "shops")
new_location_sf <- new_location_sf %>%
  mutate(type = "proposed_location", name = "Proposed Location")

standard_cols <- c("name", "type", "operator", "geometry")

# Ensure all layers have the same columns (fill missing if needed)
post_office_points <- post_office_points %>% select(any_of(standard_cols))
shop_points_clean <- shop_points %>% select(any_of(standard_cols))
shop_polygons_clean <- shop_polygons %>% select(any_of(standard_cols))
new_location_sf <- new_location_sf %>% select(any_of(standard_cols))


all_shops <- bind_rows(shop_points_clean, shop_polygons_clean)

all_facilities <- bind_rows(
  post_office_points,
  all_shops,
  new_location_sf
)

# Transform and export
all_facilities_wgs84 <- st_transform(all_facilities, 4326)
st_write(all_facilities_wgs84, "all_facilities.geojson", driver = "GeoJSON", delete_dsn = TRUE)
