#!/bin/bash

# Download Shapefiles from Natural Earth
curl -LOk -O http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_0_countries.zip
curl -LOk -O http://www.naturalearthdata.com/http//www.naturalearthdata.com/download/10m/cultural/ne_10m_admin_1_states_provinces.zip

# Unzip downloaded files
unzip ne_10m_admin_0_countries.zip
unzip ne_10m_admin_1_states_provinces.zip

# Convert Shapefile to NDJSON
shp2json -n ne_10m_admin_0_countries.shp > world_countries.ndjson
shp2json -n ne_10m_admin_1_states_provinces.shp > world_provinces.ndjson

# Extract Chinese mainland provinces, Taiwan, Hong Kong, and Macau
ndjson-filter "d.properties.adm0_a3=='CHN'" < world_provinces.ndjson > china_mainland_provinces.ndjson
ndjson-filter "['TWN','HKG','MAC'].includes(d.properties.ADM0_A3)" < world_countries.ndjson > china_other_provinces.ndjson


# Simplify the NDJSON files, to include only provice name and geometry
ndjson-map 'd.properties = {name: d.properties.name}, d' < china_mainland_provinces.ndjson > china_mainland_provinces_simplified.ndjson
ndjson-map 'd.properties = {name: d.properties.NAME}, d' < china_other_provinces.ndjson > china_other_provinces_simplified.ndjson

# Combine mainland provinces and other provinces
cat china_mainland_provinces_simplified.ndjson china_other_provinces_simplified.ndjson > china_all_provinces.ndjson

# Generate GeoJSON from NDJSON
ndjson-reduce 'p.features.push(d), p' '{type: "FeatureCollection", features:[]}' < china_all_provinces.ndjson > china_all_provinces.geojson 

# Convert GeoJSON to TopoJSON
geo2topo provinces=china_all_provinces.geojson > china_topo.json