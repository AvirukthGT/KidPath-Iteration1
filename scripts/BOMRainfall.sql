CREATE TABLE IF NOT EXISTS bronze.rainfall_raw (
  region_name TEXT,
  year        INT,
  month       INT,  -- 1-12 (if seasonal in source, expand or keep season)
  rainfall_mm NUMERIC,
  loaded_at   TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bronze.wind_raw (
  region_name TEXT,
  year        INT,
  month       INT,
  mean_wind_ms NUMERIC,
  loaded_at   TIMESTAMP DEFAULT now()
);

CREATE OR REPLACE FUNCTION gold.fn_month_to_season(m INT)
RETURNS TEXT AS $$
  SELECT CASE
    WHEN m IN (12,1,2) THEN 'Summer'
    WHEN m IN (3,4,5)  THEN 'Autumn'
    WHEN m IN (6,7,8)  THEN 'Winter'
    WHEN m IN (9,10,11) THEN 'Spring'
    ELSE 'Unknown' END;
$$ LANGUAGE sql IMMUTABLE;

CREATE TABLE IF NOT EXISTS silver.rainfall_seasonal AS
SELECT
  region_name,
  year,
  gold.fn_month_to_season(month) AS season,
  ROUND(AVG(rainfall_mm)::numeric, 1) AS rainfall_mm
FROM bronze.rainfall_raw
WHERE year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10
GROUP BY region_name, year, gold.fn_month_to_season(month);

CREATE TABLE IF NOT EXISTS silver.wind_seasonal AS
SELECT
  region_name,
  year,
  gold.fn_month_to_season(month) AS season,
  ROUND(AVG(mean_wind_ms)::numeric, 2) AS mean_wind_ms
FROM bronze.wind_raw
WHERE year >= EXTRACT(YEAR FROM CURRENT_DATE) - 10
GROUP BY region_name, year, gold.fn_month_to_season(month);
