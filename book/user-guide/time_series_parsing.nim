import nanuqbook
bookInit()

nbText: "# Time series: parsing"

attribution userGuide("Parsing", "transformations/time-series/parsing",
  "The mixed-offsets example builds a named one-column frame instead of a Series (both " &
  "sides), since Nanuq shows Series as frames.")

nbText: """
Polars has native support for parsing time series data and doing more sophisticated
operations such as temporal grouping and resampling.

## Datatypes

Polars has the following datetime datatypes:

- `Date`: Date representation e.g. 2014-07-08. It is internally represented as days since
  UNIX epoch encoded by a 32-bit signed integer.
- `Datetime`: Datetime representation e.g. 2014-07-08 07:00:00. It is internally
  represented as a 64 bit integer since the Unix epoch and can have different units such as
  ns, us, ms.
- `Duration`: A time delta type that is created when subtracting `Date/Datetime`. Similar
  to `timedelta` in Python.
- `Time`: Time representation, internally represented as nanoseconds since midnight.
"""

nanuq """
In Nim, the four types have these values: Nanuq's `Date` (`date(2014, 7, 8)`), std/times'
`DateTime` (`dateTime(2014, mJul, 8, 7, zone = utc())`) and `Duration`
(`initDuration(hours = 3)`), and Nanuq's `TimeOfDay` (`timeOfDay(7, 0)`), since Nim's
standard library has neither a date nor a time of day. `nanuq` exports `std/times`. A
`DateTime` is read and stored as a UTC instant.
"""

nbText: """
## Parsing dates from a file

When loading from a CSV file Polars attempts to parse dates and times if the
`try_parse_dates` flag is set to `True`:
"""

tabs """
import polars as pl

df = pl.read_csv("data/polars/apple_stock.csv", try_parse_dates=True)
df
""":
  nbCode:
    import nanuq

    var df = readCsv("data/polars/apple_stock.csv", tryParseDates = true)
    nbShow df

nbText: """
This flag will trigger schema inference on a number of rows, as configured by the
`infer_schema_length` setting (100 rows by default). Schema inference is computationally
expensive and can slow down file loading if a high number of rows is used.

On the other hand binary formats such as parquet have a schema that is respected by
Polars.

## Casting strings to dates

You can also cast a column of datetimes encoded as strings to a datetime type. You do this
by calling the string `str.to_date` method and passing the format of the date string:
"""

tabs """
df = pl.read_csv("data/polars/apple_stock.csv", try_parse_dates=False)

df = df.with_columns(pl.col("Date").str.to_date("%Y-%m-%d"))
df
""":
  nbCode:
    df = readCsv("data/polars/apple_stock.csv", tryParseDates = false)

    df = df.withColumns(col("Date").str.toDate("%Y-%m-%d"))
    nbShow df

nanuq """
The column is called `Date`, the name of a Nim type, so the shorthand `col.Date` would be
read as a conversion to `Date`: write `col("Date")`.
"""

nbText: """
[The format string specification can be found here.](https://docs.rs/chrono/latest/chrono/format/strftime/index.html).

## Extracting date features from a date column

You can extract data features such as the year or day from a date column using the `.dt`
namespace:
"""

tabs """
df_with_year = df.with_columns(pl.col("Date").dt.year().alias("year"))
df_with_year
""":
  nbCode:
    let dfWithYear = df.withColumns(col("Date").dt.year.alias("year"))
    nbShow dfWithYear

nbText: """
## Mixed offsets

If your data contains datetimes with mixed UTC offsets (for example due to daylight-saving
transitions), Polars parses them in UTC. You can either pass a target `time_zone` to
`str.to_datetime`, or call `str.convert_time_zone` after parsing:
"""

tabs """
data = [
    "2021-03-27T00:00:00+0100",
    "2021-03-28T00:00:00+0100",
    "2021-03-29T00:00:00+0200",
    "2021-03-30T00:00:00+0200",
]
mixed_parsed = (
    pl.Series("ts", data)
    .str.to_datetime("%Y-%m-%dT%H:%M:%S%z")
    .dt.convert_time_zone("Europe/Brussels")
)
mixed_parsed.to_frame()
""":
  nbCode:
    let data = newDataFrame:
      ts: ["2021-03-27T00:00:00+0100", "2021-03-28T00:00:00+0100",
           "2021-03-29T00:00:00+0200", "2021-03-30T00:00:00+0200"]
    let mixedParsed = data.select(
      col.ts
        .str.toDatetime("%Y-%m-%dT%H:%M:%S%z")
        .dt.convertTimeZone("Europe/Brussels"))
    nbShow mixedParsed

bookSave()
