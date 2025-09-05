ogr2ogr -f "PostgreSQL" PG:"host=<rds> user=<user> dbname=<db> password=<pwd>" \
  trees.geojson  -nln bronze.osm_trees_raw  -nlt POINT -lco GEOMETRY_NAME=geom
ogr2ogr -f "PostgreSQL" PG:"..." parks.geojson  -nln bronze.osm_parks_raw  -nlt MULTIPOLYGON -lco GEOMETRY_NAME=geom
