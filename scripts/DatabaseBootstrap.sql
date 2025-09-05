-- connect with psql to your RDS instance
CREATE SCHEMA IF NOT EXISTS bronze;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Common reference tables
CREATE TABLE IF NOT EXISTS silver.dim_dataset (
  dataset_id  SERIAL PRIMARY KEY,
  dataset_key TEXT UNIQUE NOT NULL,         -- e.g., 'tree_canopy_com', 'fountains_com'
  source_name TEXT NOT NULL,
  source_url  TEXT,
  license     TEXT,
  as_of_date  DATE DEFAULT CURRENT_DATE
);

-- Normalized suburb dictionary (ABS/Vicmap)
-- geometry stored in WGS84 for web maps
CREATE TABLE IF NOT EXISTS silver.dim_suburb (
  suburb_id   SERIAL PRIMARY KEY,
  suburb_name TEXT NOT NULL,
  lga_name    TEXT,
  sa2_code    TEXT,
  geom        geometry(MultiPolygon, 4326) NOT NULL
);
CREATE INDEX IF NOT EXISTS dim_suburb_gix ON silver.dim_suburb USING GIST (geom);
CREATE UNIQUE INDEX IF NOT EXISTS dim_suburb_uq ON silver.dim_suburb(suburb_name, COALESCE(lga_name,''));
