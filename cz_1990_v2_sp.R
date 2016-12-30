# Create boundaries of US 1990 commuting zones in R sp format using US Census
# Bureau shapefiles

# The code below follows the example code in:
# Bivand R. Combining Spatial Data. 2016-11-15.
# https://cran.r-project.org/web/packages/maptools/vignettes/combine_maptools.pdf

# Authors: Bill Behrman and Claudia Engel
# Version: 2016-12-29

# Libraries
library(tidyverse)
library(readxl)
library(rgdal)
library(maptools)
library(stringr)

# Parameters
  # Boundary year
year <- "2015"
  # Boundary resolutions
resolutions <- c("500k", "5m", "20m")
  # PROJ.4 string for WGS84 coordinate reference system
proj4_wgs84 <- "+proj=longlat +datum=WGS84 +no_defs"
  # FIPS codes for US states and District of Columbia
fips_states <- c(
  "01", "02", "04", "05", "06", "08", "09", "10", "11", "12", "13", "15", "16",
  "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29",
  "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42",
  "44", "45", "46", "47", "48", "49", "50", "51", "53", "54", "55", "56"
)
  # FIPS codes for counties deleted since 1990 census
counties_deleted <- c(
  "02201", "02231", "02270", "02280", "12025", "30113", "46113", "51515",
  "51560", "51780"
)
  # FIPS codes for counties added since 1990 census with 1990 commuting zone
counties_added <- tribble(
  ~fips_county, ~cz_1990,
  "02068", "34115",
  "02105", "34109",
  "02158", "34112",
  "02195", "34110",
  "02198", "34111",
  "02230", "34109",
  "02275", "34111",
  "02282", "34109",
  "08014", "28900",
  "12086", "07000",
  "46102", "27704"
)
  # Temporary directory
tmp <- str_c("/tmp/", Sys.time() %>% as.integer(), "/")
  # URL for US Census Bureau shapefiles
url_cb <- str_c("http://www2.census.gov/geo/tiger/GENZ", year, "/shp/")
  # URL for commuting zone county partition using 1990 counties
url_cz <- "https://www.ers.usda.gov/webdocs/DataFiles/Commuting_Zones_and_Labor_Market_Areas__17970/czlma903.xls"
  # Data directory
dir_data <- "data/"

#===============================================================================

# Ensure that rgeos is available
if (!rgeosStatus()) {
  stop("Error: rgeos not available")
}

# Create temporary directory
v <- tmp %>% str_sub(end = -2L)
if (!file.exists(v)) {
  dir.create(v, recursive = TRUE)
}

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
  ) %>% 
  select(-place_state)

# Adjust county partition for counties added and deleted since 1990
v <- 
  counties_added %>% 
  left_join(cz %>% select(-fips_county) %>% distinct(), by = "cz_1990")
cz <- 
  bind_rows(cz, v) %>% 
  filter(!(fips_county %in% counties_deleted)) %>% 
  arrange(cz_1990, fips_county)
  
# For resolution
for (resolution in resolutions) {
  
  # Boundary specification
  boundary <- str_c("cb_", year, "_us_county_", resolution)
  
  # Download and unzip US Census Bureau shapefile
  url <- str_c(url_cb, boundary, ".zip")
  dest <- str_c(tmp, boundary, ".zip")
  if (download.file(url = url, destfile = dest, quiet = TRUE)) {
    print(str_c("Error: Download for ", boundary, " failed"))
    next
  }
  unzip(zipfile = dest, exdir = str_c(tmp, boundary))
  
  # Read shapefile into sp object and subset to states and District of Columbia
  us <- 
    readOGR(dsn = str_c(tmp, boundary, "/", boundary, ".shp"),
            layer = boundary, stringsAsFactors = FALSE) %>%
    subset(STATEFP %in% fips_states)
  
  # Create variable for FIPS county code
  us_df <- 
    us@data %>% 
    transmute(fips_county = GEOID)
  
  # Restructure the SpatialPolygons object so that the Polygon objects for each
  # county belong to the same Polygons object
  us_sp <- unionSpatialPolygons(SpP = us, IDs = us_df$fips_county)
  
  # Remove duplicate rows from data frame and combine with SpatialPolygons
  # object
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
    write_rds(str_c(dir_data, "cb_", year, "_us_cz_", resolution, "_sp.rds"))
}

# Remove temporary directory
if (unlink(tmp, recursive = TRUE, force = TRUE)) {
  print("Error: Remove temporary directory failed")
}
