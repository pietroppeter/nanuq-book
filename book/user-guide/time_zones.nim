import nanuqbook
bookInit()

nbText: "# Time zones"

attribution userGuide("Time zones", "transformations/time-series/timezones",
  "The two Series of the first example are built as the columns of a frame (both sides).")

nbText: """
> **Tom Scott:** You really should never, ever deal with time zones if you can help it.

The `Datetime` datatype can have a time zone associated with it. Examples of valid time
zones are:

- `None`: no time zone, also known as "time zone naive".
- `UTC`: Coordinated Universal Time.
- `Asia/Kathmandu`: time zone in "area/location" format. See the
  [list of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)
  to see what's available.

Caution: Fixed offsets such as +02:00, should not be used for handling time zones. It's
advised to use the "Area/Location" format mentioned above, as it can manage timezones more
effectively.

Note that, because a `Datetime` can only have a single time zone, it is impossible to have
a column with multiple time zones. If you are parsing data with multiple offsets, you may
want to pass `utc=True` to convert them all to a common time zone (`UTC`), see
[parsing dates and times](time_series_parsing.html).

The main methods for setting and converting between time zones are:

- `dt.convert_time_zone`: convert from one time zone to another.
- `dt.replace_time_zone`: set/unset/change time zone.

Let's look at some examples of common operations:
"""

nanuq """
Time zones are IANA names as strings, as in Polars, and the empty string `""` stands for
Python's `None`. Polars does the time zone work: Nim's std/times only knows the local zone
and UTC.
"""

tabs """
import polars as pl

ts = ["2021-03-27 03:00", "2021-03-28 03:00"]
time_zones_df = pl.DataFrame({"tz_naive": ts}).with_columns(
    pl.col("tz_naive").str.to_datetime()
).with_columns(pl.col("tz_naive").dt.replace_time_zone("UTC").alias("tz_aware"))
time_zones_df
""":
  nbCode:
    import nanuq

    let timeZonesDf = newDataFrame(series("tz_naive", ["2021-03-27 03:00", "2021-03-28 03:00"]))
      .withColumns(col.tz_naive.str.toDatetime)
      .withColumns(col.tz_naive.dt.replaceTimeZone("UTC").alias("tz_aware"))
    nbShow timeZonesDf

tabs """
time_zones_df.select(
    [
        pl.col("tz_aware")
        .dt.replace_time_zone("Europe/Brussels")
        .alias("replace time zone"),
        pl.col("tz_aware")
        .dt.convert_time_zone("Asia/Kathmandu")
        .alias("convert time zone"),
        pl.col("tz_aware").dt.replace_time_zone(None).alias("unset time zone"),
    ]
)
""":
  nbCode:
    nbShow timeZonesDf.select(
      col.tz_aware.dt.replaceTimeZone("Europe/Brussels").alias("replace time zone"),
      col.tz_aware.dt.convertTimeZone("Asia/Kathmandu").alias("convert time zone"),
      col.tz_aware.dt.replaceTimeZone("").alias("unset time zone"))

bookSave()
