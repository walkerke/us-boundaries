US Boundaries
================

This repo is to create scripts to turn US Census Bureau shapefiles into R sp objects for US counties and states.

The US Census Bureau cartographic shapefiles are available here

-   [County](https://www.census.gov/geo/maps-data/data/cbf/cbf_counties.html)
-   [State](https://www.census.gov/geo/maps-data/data/cbf/cbf_state.html)

Each has boundary files in three resolutions

-   500k = 1:500,000
-   5m = 1:5,000,000
-   20m = 1:20,000,000

We will store the data in the WGS 84, EPSG:4326 ([epsg.io](https://epsg.io/4326)) coordinate reference system.

Our naming convention is `cb_year_us_region_resolution.rds` where

-   year = 2015
-   region = county, state
-   resolution = 500k, 5m, 20m
