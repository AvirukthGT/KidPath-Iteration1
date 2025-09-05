-- Latest canopy by suburb with rank
CREATE OR REPLACE VIEW gold.vw_canopy_latest AS
SELECT s.suburb_id, s.suburb_name, c.year, c.canopy_pct,
       RANK() OVER (ORDER BY c.canopy_pct DESC) AS rank_desc
FROM silver.dim_suburb s
JOIN LATERAL (
  SELECT * FROM silver.tree_canopy tc
  WHERE tc.suburb_id = s.suburb_id
  ORDER BY year DESC
  LIMIT 1
) c ON TRUE;

-- Fountain counts joined to suburb geometry (for choropleth / list)
CREATE OR REPLACE VIEW gold.vw_fountains_by_suburb AS
SELECT d.suburb_id, d.suburb_name, COALESCE(f.fountain_count,0) AS fountain_count, d.geom_simplified AS geom
FROM silver.dim_suburb d
LEFT JOIN silver.fountain_counts_by_suburb f USING (suburb_id);

-- Parameterized function for "nearby fountains" (radius meters)
CREATE OR REPLACE FUNCTION gold.fn_fountains_within(lat DOUBLE PRECISION, lon DOUBLE PRECISION, radius_m INT)
RETURNS TABLE(name TEXT, status TEXT, distance_m DOUBLE PRECISION, lon DOUBLE PRECISION, lat DOUBLE PRECISION) AS $$
  SELECT
    f.name, f.status,
    ST_DistanceSphere(f.geom, ST_SetSRID(ST_MakePoint(lon,lat),4326)) AS distance_m,
    ST_X(f.geom) AS lon, ST_Y(f.geom) AS lat
  FROM silver.fountains f
  WHERE ST_DWithin(f.geom::geography, ST_SetSRID(ST_MakePoint(lon,lat),4326)::geography, radius_m)
  ORDER BY distance_m ASC;
$$ LANGUAGE sql STABLE;

-- Seasonal rainfall for last 10y for UI chart
CREATE OR REPLACE VIEW gold.vw_rainfall_seasonal_10y AS
SELECT * FROM silver.rainfall_seasonal;

-- Seasonal wind for last 10y
CREATE OR REPLACE VIEW gold.vw_wind_seasonal_10y AS
SELECT * FROM silver.wind_seasonal;

-- Recent pollen with risk flag
CREATE OR REPLACE VIEW gold.vw_pollen_recent AS
SELECT * FROM silver.pollen_daily WHERE obs_date >= CURRENT_DATE - INTERVAL '365 days';
