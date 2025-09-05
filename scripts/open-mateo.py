import requests, pandas as pd, sqlalchemy as sa, os

url = "https://api.open-meteo.com/v1/forecast"
params = dict(latitude=-37.8136, longitude=144.9631,
              hourly=["temperature_2m","wind_speed_10m","wind_gusts_10m","rain","uv_index"],
              timezone="UTC")
r = requests.get(url, params=params, timeout=30)
r.raise_for_status()
h = r.json()["hourly"]
df = pd.DataFrame(h)
df.rename(columns={"temperature_2m":"temp_c",
                   "wind_speed_10m":"windspeed_ms",
                   "wind_gusts_10m":"windgust_ms",
                   "rain":"rain_mm"}, inplace=True)
df["ts_utc"] = pd.to_datetime(df["time"])

engine = sa.create_engine("postgresql+psycopg2://user:pwd@host:5432/db")
df[["ts_utc","temp_c","windspeed_ms","windgust_ms","rain_mm","uv_index"]]\
  .assign(lat=-37.8136, lon=144.9631)\
  .to_sql("weather_hourly_raw", engine, schema="bronze", if_exists="append", index=False)
