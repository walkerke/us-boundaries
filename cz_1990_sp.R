# Create boundaries of US 1990 commuting zones in R sp format using US Census
# Bureau shapefiles

# The code below follows the example code in:
# Bivand R. Combining Spatial Data. 2016-11-15.
# https://cran.r-project.org/web/packages/maptools/vignettes/combine_maptools.pdf

# Authors: Claudia Engel and Bill Behrman
# Version: 2016-12-24

# Libraries
library(tidyverse)
library(readxl)
library(rgdal)
library(maptools)
library(stringr)

# Parameters
  # PROJ.4 string for NAD27 coordinate reference system
proj4_nad27 <- "+proj=longlat +datum=NAD27 +no_defs"
  # PROJ.4 string for WGS84 coordinate reference system
proj4_wgs84 <- "+proj=longlat +datum=WGS84 +no_defs"
  # Temporary directory
tmp <- str_c("/tmp/", Sys.time() %>% as.integer(), "/")
  # URL for US Census Bureau shapefile
url_cb <- "http://www2.census.gov/geo/tiger/PREVGENZ/co/co90shp/co99_d90_shp.zip"
  # URL for commuting zone county partition
url_cz <- "https://www.ers.usda.gov/webdocs/DataFiles/Commuting_Zones_and_Labor_Market_Areas__17970/czlma903.xls"
  # Output file
file_out <- "../data/cb_1990_us_cz_sp.rds"

#===============================================================================

# Ensure that rgeos is available
if (!rgeosStatus()) {
  stop("Error: rgeos not available")
}

# Create temporary directory
if (!file.exists(tmp)) {
  dir.create(tmp, recursive = TRUE)
}
  
# Download and unzip US Census Bureau shapefile
dest <- str_c(tmp, "co99_d90_shp.zip")
layer <- "co99_d90"
if (download.file(url = url_cb, destfile = dest, quiet = TRUE)) {
  stop("Error: Shapefile download failed")
}
unzip(zipfile = dest, exdir = str_c(tmp, layer, "/"))

# Read shapefile into sp object
us <- readOGR(dsn = str_c(tmp, layer, "/", layer, ".shp"),
              layer = layer, stringsAsFactors = FALSE)

# Set coordinate reference system to NAD27
proj4string(us) <- CRS(proj4_nad27)

# Create variable for FIPS county code
us_df <- 
  us@data %>% 
  transmute(fips_county = str_c(ST, CO))

# Restructure the SpatialPolygons object so that the Polygon objects for each
# county belong to the same Polygons object
us_sp <- unionSpatialPolygons(SpP = us, IDs = us_df$fips_county)

# Remove duplicate rows from data frame and combine with SpatialPolygons object
us_df <-
  us_df %>%
  filter(!duplicated(us_df$fips_county))
row.names(us_df) <- us_df$fips_county
us <- SpatialPolygonsDataFrame(Sr = us_sp, data = us_df)

# Check each Polygons object for internal consistency and clean, if necessary
us_sp <-
  SpatialPolygons(
    Srl = map(us@polygons, checkPolygonsHoles),
    proj4string = CRS(proj4string(us))
  )
us <- SpatialPolygonsDataFrame(Sr = us_sp, data = us_df)

# Download commuting zones county partition
dest <- str_c(tmp, "czlma903.xls")
if (download.file(url = url_cz, destfile = dest, quiet = TRUE)) {
  stop("Error: Commuting zones download failed")
}

# Read commuting zone county partition, add place and state variables
cz <- 
  read_excel(dest, sheet = "CZLMA903", na = ".") %>% 
  select(
    fips_county = contains("FIPS"),
    cz_1990 = CZ90,
    place_state = contains("largest place")
  ) %>% 
  mutate(
    place =
      place_state %>% 
      str_replace(" borough.*| CDP.*| city.*| town.*| \\(rem.*|,.*", ""),
    state = place_state %>% str_sub(start = -2L)
  )

# Join commuting zone county partition into map data
us_df <- 
  us@data %>% 
  left_join(cz, by = "fips_county")
row.names(us_df) <- us_df$fips_county
us <- SpatialPolygonsDataFrame(Sr = us_sp, data = us_df)

# Merge counties into commuting zones
us_sp <- unionSpatialPolygons(SpP = us, IDs = us$cz_1990)
us_df <- 
  us@data %>% 
  select(cz_1990, place, state) %>% 
  distinct()
row.names(us_df) <- us_df$cz_1990
us <- SpatialPolygonsDataFrame(Sr = us_sp, data = us_df)

# Convert to WGS84 coordinate reference system and write out
us %>% 
  spTransform(CRSobj = CRS(proj4_wgs84)) %>% 
  write_rds(file_out)

# Remove temporary directory
if (unlink(tmp, recursive = TRUE, force = TRUE)) {
  print("Error: Remove temporary directory failed")
}