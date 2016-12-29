# Create boundaries of US counties and states in R sp format using US Census
# Bureau shapefiles

# Authors: Bill Behrman, Claudia Engel, and Kyle Walker
# Version: 2016-12-29

# Libraries
library(tidyverse)
library(rgdal)
library(stringr)

# Parameters
  # Boundary year
year <- "2015"
  # Boundary regions
regions <- c("county", "state")
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
  # Temporary directory
tmp <- str_c("/tmp/", Sys.time() %>% as.integer(), "/")
  # URL for US Census Bureau shapefiles
url_cb <- str_c("http://www2.census.gov/geo/tiger/GENZ", year, "/shp/")
  # Data directory
dir_data <- "data/"

#===============================================================================

# Create temporary directory for US Census Bureau shapefiles
v <- tmp %>% str_sub(end = -2L)
if (!file.exists(v)) {
  dir.create(v, recursive = TRUE)
}

# For region and resolution
for (region in regions) {
  for (resolution in resolutions) {
    
    # Boundary specification
    boundary <- str_c("cb_", year, "_us_", region, "_", resolution)
    
    # Download and unzip US Census Bureau shapefile
    url <- str_c(url_cb, boundary, ".zip")
    dest <- str_c(tmp, boundary, ".zip")
    if (download.file(url = url, destfile = dest, quiet = TRUE)) {
      print(str_c("Error: Download for ", boundary, " failed"))
      next
    }
    unzip(zipfile = dest, exdir = str_c(tmp, boundary))
    
    # Read shapefile into sp object, subset to states and District of Columbia,
    # convert to WGS84 coordinate reference system, and write out
    readOGR(dsn = str_c(tmp, boundary, "/", boundary, ".shp"),
            layer = boundary, stringsAsFactors = FALSE) %>%
      subset(STATEFP %in% fips_states) %>% 
      spTransform(CRSobj = CRS(proj4_wgs84)) %>% 
      write_rds(str_c(dir_data, boundary, "_sp.rds"))
  }
}

# Remove temporary directory
if (unlink(tmp, recursive = TRUE, force = TRUE)) {
  print("Error: Remove temporary directory failed")
}
