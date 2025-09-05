CREATE TABLE IF NOT EXISTS bronze.pollen_raw (
  obs_date    DATE,
  level       TEXT,          -- e.g., Low/Moderate/High/Extreme or numeric index
  station     TEXT,
  loaded_at   TIMESTAMP DEFAULT now()
);

-- Normalize
CREATE TABLE IF NOT EXISTS silver.pollen_daily AS
SELECT
  obs_date,
  INITCAP(TRIM(level)) AS level,
  station
FROM bronze.pollen_raw
WHERE obs_date IS NOT NULL;

-- Risk flags for UI
ALTER TABLE silver.pollen_daily ADD COLUMN IF NOT EXISTS is_high_risk BOOLEAN;
UPDATE silver.pollen_daily
SET is_high_risk = (level IN ('High','Extreme'));
