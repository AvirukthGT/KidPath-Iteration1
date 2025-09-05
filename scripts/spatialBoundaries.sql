-- example source columns: name = 'SSC_NAME', LGA_NAME, geom in unknown SRID
CREATE OR REPLACE VIEW bronze.abs_suburbs_std AS
SELECT
  INITCAP(TRIM(ssc_name))      AS suburb_name,
  INITCAP(TRIM(lga_name))      AS lga_name,
  sa2_maincode_2016            AS sa2_code,
  ST_Multi(ST_Transform(geom, 4326))::geometry(MultiPolygon,4326) AS geom
FROM bronze.abs_suburbs_raw;

INSERT INTO silver.dim_suburb(suburb_name, lga_name, sa2_code, geom)
SELECT suburb_name, lga_name, sa2_code,
       ST_MakeValid(geom)       -- fix invalid polygons
FROM bronze.abs_suburbs_std
ON CONFLICT (suburb_name, lga_name) DO NOTHING;

