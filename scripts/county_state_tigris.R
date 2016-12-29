# Fetch boundaries of US counties and states in R sp format using US Census
# Bureau shapefiles with tigris

# Authors: Claudia Engel, Bill Behrman, and Kyle Walker
# Version: 2016-12-29

### The traditional (sp) way with tigris: 
library(tigris)
library(tidyverse)
library(rgdal)
library(stringr)

# Boundary regions
regions <- c("county", "state")
# Boundary resolutions
resolutions <- c("500k", "5m", "20m")
# WGS 1984
# A note: the NAD 83 CRS used by the TIGER/Line shapefiles and cartographic
# boundary files is _very_ similar to WGS 84 
proj4_wgs84 <- "+proj=longlat +datum=WGS84 +no_defs"

fips_states <- c(
  "01", "02", "04", "05", "06", "08", "09", "10", "11", "12", "13", "15", "16",
  "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29",
  "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42",
  "44", "45", "46", "47", "48", "49", "50", "51", "53", "54", "55", "56")

# By default, tigris creates a cache directory on the user's computer 
# so that data don't have to be re-downloaded in future sessions.  To mirror 
# your code below, this behavior can be turned off by uncommenting
# the following line of code: 

# options(tigris_use_cache = FALSE)

# tigris currently defaults to the 2015 shapefiles.  
for (region in regions) {
  for (resolution in resolutions) {
    if (region == "state") {
      states(cb = TRUE, resolution = resolution) %>%
        subset(!STUSPS %in% c("HI", "AK", "AS", "GU", 
                              "MP", "PR", "VI")) %>%
        spTransform(CRSobj = CRS(proj4_wgs84)) %>%
        write_rds(str_c("data/", region, "_", resolution,
                        "_tigris.rds"))
        
    } else if (region == "county") {
      counties(cb = TRUE, state = fips_states, resolution = resolution) %>%
        spTransform(CRSobj = CRS(proj4_wgs84)) %>%
        write_rds(str_c("data/", region, "_", resolution, 
                        "_tigris.rds"))
    }
  }
}
