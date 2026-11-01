import nanuqbook
bookInit()

nbText: "# Time series: filtering"

attribution userGuide("Filtering", "transformations/time-series/filter",
  "The negative dates are built in a frame instead of a Series (both sides).")

nbText: """
Filtering date columns works in the same way as with other types of columns using the
`.filter` method.

Polars uses Python's native `datetime`, `date` and `timedelta` for equality comparisons
between the datatypes `pl.Datetime`, `pl.Date` and `pl.Duration`.

In the following example we use a time series of Apple stock prices.
"""

nanuq """
In Nim the values to compare with are Nanuq's `Date` (`date(1995, 10, 16)`), std/times'
`DateTime` and `Duration`, and Nanuq's `TimeOfDay`.
"""

tabs """
import polars as pl
from datetime import datetime

df = pl.read_csv("data/polars/apple_stock.csv", try_parse_dates=True)
df
""":
  nbCode:
    import nanuq

    let df = readCsv("data/polars/apple_stock.csv", tryParseDates = true)
    nbShow df

nbText: """
## Filtering by single dates

We can filter by a single date using an equality comparison in a filter expression:
"""

tabs """
filtered_df = df.filter(
    pl.col("Date") == datetime(1995, 10, 16),
)
filtered_df
""":
  nbCode:
    let filteredDf = df.filter(col("Date") == date(1995, 10, 16))
    nbShow filteredDf

nbText: """
Note we are using the lowercase `datetime` method rather than the uppercase `Datetime`
data type.
"""

nanuq """
The column holds dates, so Nim compares it with a `Date`. Python's `datetime` works too,
because Polars casts the column for the comparison.
"""

nbText: """
## Filtering by a date range

We can filter by a range of dates using the `is_between` method in a filter expression with
the start and end dates:
"""

tabs """
filtered_range_df = df.filter(
    pl.col("Date").is_between(datetime(1995, 7, 1), datetime(1995, 11, 1)),
)
filtered_range_df
""":
  nbCode:
    let filteredRangeDf = df.filter(
      col("Date").isBetween(date(1995, 7, 1), date(1995, 11, 1)))
    nbShow filteredRangeDf

nbText: """
## Filtering with negative dates

Say you are working with an archeologist and are dealing in negative dates. Polars can
parse and store them just fine, but the Python `datetime` library does not. So for
filtering, you should use attributes in the `.dt` namespace:
"""

tabs """
negative_dates_df = pl.DataFrame(
    {"ts": ["-1300-05-23", "-1400-03-02"], "values": [3, 4]}
).with_columns(pl.col("ts").str.to_date())

negative_dates_filtered_df = negative_dates_df.filter(pl.col("ts").dt.year() < -1300)
negative_dates_filtered_df
""":
  nbCode:
    let negativeDatesDf = newDataFrame(
        series("ts", ["-1300-05-23", "-1400-03-02"]), series("values", [3, 4]))
      .withColumns(col.ts.str.toDate)

    let negativeDatesFilteredDf = negativeDatesDf.filter(col.ts.dt.year < -1300)
    nbShow negativeDatesFilteredDf

bookSave()
