import nanuqbook
bookInit()

nbText: "# Time series: resampling"

attribution userGuide("Resampling", "transformations/time-series/resampling",
  "The results are shown as tables instead of printed.")

nbText: """
We can resample by either:

- upsampling (moving data to a higher frequency)
- downsampling (moving data to a lower frequency)
- combinations of these e.g. first upsample and then downsample

## Downsampling to a lower frequency

Polars views downsampling as a special case of the **group_by** operation and you can do
this with `group_by_dynamic` and `group_by_rolling` -
[see the temporal group by page for examples](time_series_grouping.html).

## Upsampling to a higher frequency

Let's go through an example where we generate data at 30 minute intervals:
"""

tabs """
from datetime import datetime

import polars as pl

df = pl.DataFrame(
    {
        "time": pl.datetime_range(
            start=datetime(2021, 12, 16),
            end=datetime(2021, 12, 16, 3),
            interval="30m",
            eager=True,
        ),
        "groups": ["a", "a", "a", "b", "b", "a", "a"],
        "values": [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
    }
)
df
""":
  nbCode:
    import std/times
    import nanuq

    let df = newDataFrame(
      series("groups", ["a", "a", "a", "b", "b", "a", "a"]),
      series("values", [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]),
    ).select(
      datetimeRange(
        dateTime(2021, mDec, 16, zone = utc()),
        dateTime(2021, mDec, 16, 3, zone = utc()),
        interval = "30m").alias("time"),
      col.groups,
      col.values)
    nbShow df

nanuq """
`datetimeRange` is an expression (Python's `eager=False`), so the `time` column comes in
with a `select`. The `DateTime` values are from `std/times`; their zone only says how to
read the clock time, and the column has no time zone, as in Python.
"""

nbText: """
Upsampling can be done by defining the new sampling interval. By upsampling we are adding in
extra rows where we do not have data. As such upsampling by itself gives a DataFrame with
nulls. These nulls can then be filled with a fill strategy or interpolation.

### Upsampling strategies

In this example we upsample from the original 30 minutes to 15 minutes and then use a
`forward` strategy to replace the nulls with the previous non-null value:
"""

tabs """
out1 = df.upsample(time_column="time", every="15m").fill_null(strategy="forward")
out1
""":
  nbCode:
    let out1 = df.upsample(timeColumn = "time", every = "15m")
      .fillNull(FillNullStrategy.Forward)
    nbShow out1

nbText: """
In this example we instead fill the nulls by linear interpolation:
"""

tabs """
out2 = (
    df.upsample(time_column="time", every="15m")
    .interpolate()
    .fill_null(strategy="forward")
)
out2
""":
  nbCode:
    let out2 = df.upsample(timeColumn = "time", every = "15m")
      .interpolate()
      .fillNull(FillNullStrategy.Forward)
    nbShow out2

bookSave()
