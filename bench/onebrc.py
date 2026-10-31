"""The One Billion Row Challenge in Python Polars: the query."""
import polars as pl


def onebrc(path, engine="in-memory"):
    # Min, mean and max temperature per weather station, sorted by station.
    return (
        pl.scan_csv(
            path,
            separator=";",
            has_header=False,
            schema={"station": pl.String, "measurement": pl.Float64},
        )
        .group_by("station")
        .agg(
            pl.col("measurement").min().alias("min"),
            pl.col("measurement").mean().round(1).alias("mean"),
            pl.col("measurement").max().alias("max"),
        )
        .sort("station")
    )
