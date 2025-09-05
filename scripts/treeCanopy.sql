CREATE TABLE IF NOT EXISTS bronze.tree_canopy_raw (
  suburb_name TEXT,
  year        INT,
  canopy_pct  NUMERIC,  -- 0-100
  source_file TEXT,
  loaded_at   TIMESTAMP DEFAULT now()
);

-- normalize names and bind to dim_suburb
CREATE TABLE IF NOT EXISTS silver.tree_canopy AS
SELECT
  s.suburb_id,
  ds.dataset_id,
  r.year,
  ROUND(r.canopy_pct::numeric, 1) AS canopy_pct
FROM (
  SELECT INITCAP(TRIM(suburb_name)) AS suburb_name, year, canopy_pct
  FROM bronze.tree_canopy_raw
  WHERE canopy_pct BETWEEN 0 AND 100
) r
JOIN silver.dim_suburb s
  ON r.suburb_name = s.suburb_name
JOIN silver.dim_dataset ds
  ON ds.dataset_key = 'tree_canopy_com';

CREATE INDEX IF NOT EXISTS tree_canopy_idx ON silver.tree_canopy(suburb_id, year);
