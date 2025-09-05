CREATE TABLE IF NOT EXISTS bronze.fountains_raw (
  fountain_id TEXT,
  name        TEXT,
  status      TEXT,
  installed_on DATE,
  lon         DOUBLE PRECISION,
  lat         DOUBLE PRECISION,
  properties  JSONB,
  geom        geometry(Point,4326),
  loaded_at   TIMESTAMP DEFAULT now()
);
-- near-duplicate points collapsed by 2 meters
CREATE TABLE IF NOT EXISTS silver.fountains AS
SELECT DISTINCT ON (ROUND(lon::numeric,6), ROUND(lat::numeric,6))
  COALESCE(NULLIF(TRIM(name),''),'Fountain') AS name,
  CASE
    WHEN LOWER(status) IN ('working','active','operational') THEN 'operational'
    WHEN LOWER(status) IN ('removed','inactive','decommissioned') THEN 'removed'
    ELSE 'unknown'
  END AS status,
  installed_on,
  ST_SetSRID(ST_MakePoint(lon, lat),4326) AS geom
FROM bronze.fountains_raw
WHERE lon BETWEEN -180 AND 180 AND lat BETWEEN -90 AND 90;

CREATE INDEX IF NOT EXISTS fountains_gix ON silver.fountains USING GIST (geom);

ALTER TABLE silver.fountains ADD COLUMN IF NOT EXISTS suburb_id INT;
UPDATE silver.fountains f
SET suburb_id = s.suburb_id
FROM silver.dim_suburb s
WHERE f.suburb_id IS NULL AND ST_Intersects(f.geom, s.geom);

-- Aggregate
CREATE TABLE IF NOT EXISTS silver.fountain_counts_by_suburb AS
SELECT suburb_id, COUNT(*) AS fountain_count
FROM silver.fountains
WHERE status <> 'removed'
GROUP BY suburb_id;

CREATE INDEX IF NOT EXISTS fcnt_suburb_idx ON silver.fountain_counts_by_suburb(suburb_id);
