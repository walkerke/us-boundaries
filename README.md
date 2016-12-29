US Boundaries
================

Boundaries of US counties, commuting zones, and states in R sf and sp formats.

County and state boundaries are provided in three resolutions

-   500k = 1:500,000
-   5m = 1:5,000,000
-   20m = 1:20,000,000

All boundaries use the WGS 84, EPSG:4326 ([epsg.io](https://epsg.io/4326)) coordinate reference system.

The county and state boundary files have this naming convention: `cb_year_us_region_resolution_format.rds` where

-   year = 2015
-   region = county, state
-   resolution = 500k, 5m, 20m
-   format = sf, sp

The commuting zone boundary files have this naming convention: `cb_year_us_cz_format.rds` where

-   year = 1990
-   format = sf, sp
