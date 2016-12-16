US Boundaries
================

This repo is to create scripts to turn US Census Bureau shapefiles into R objects for composite maps of the US, with insets for Alaska and Hawaii.

The US Census Bureau cartographic shapefiles are available here

-   [County](https://www.census.gov/geo/maps-data/data/cbf/cbf_counties.html)
-   [State](https://www.census.gov/geo/maps-data/data/cbf/cbf_state.html)

Each has boundary files in three resolutions

-   500k = 1:500,000
-   5m = 1:5,000,000
-   20m = 1:20,000,000

In addition to counties and states, we will create boundary files for commuting zones. [Commuting zones](https://www.ers.usda.gov/data-products/commuting-zones-and-labor-market-areas/) are comprised of one or more counties. We will make boundaries for the 1990 commuting zones as specified in this Excel spreadsheet

-   [1980 and 1990 commuting zones and labor market areas](https://www.ers.usda.gov/webdocs/DataFiles/Commuting_Zones_and_Labor_Market_Areas__17970/czlma903.xls?v=40961)

We will create the R objects in two formats: sp and sf.

Our naming convention is `cb_year_us_region_resolution_format.rds` where

-   year = 2015
-   region = county, cz, state
-   resolution = 500k, 5m, 20m
-   format = sp, sf
