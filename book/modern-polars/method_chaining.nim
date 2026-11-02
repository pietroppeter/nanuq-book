import nanuqbook
bookInit()

nbText: "# Method Chaining"

attribution modernPolars("Method Chaining", "method_chaining",
  "The data is two days (1 and 2 January 2022, 34,910 flights) of the US Bureau of " &
  "Transportation Statistics' on-time flights table for January 2022 that the book downloads, " &
  "with only the 14 columns the chapter uses: `data/modern-polars/flights_2022_01_01-02.csv`. " &
  "Plots are shown as the tables they are drawn from.")

nbText: """
Many people don't need to be told why method chaining is nice. Many languages make it easy to
write `thing.min().abs().str()` instead of `str(abs(min(thing)))`.

But the Python standard library tends to prefer the ugly way, so if you've spent a lot of time
doing vanilla Python stuff, you may have become accustomed to writing nasty nested function
calls or declaring intermediate variables like `min_thing`. This is sad because a sensible degree
of method chaining can make code a lot easier to read.

It's not always easy for libraries to accommodate method chaining - in fancy terms, to be
[fluent interfaces](https://en.wikipedia.org/wiki/Fluent_interface).

Fortunately Polars is very fluent. The expression API provides a very elegant way to do a bunch
of stuff to a dataframe in one fell swoop, and Polars mostly doesn't mutate dataframes in-place
(method chaining with side effects is often a bad idea).

Let's see how this looks in practice by cleaning up the flight data.
"""

nanuq """
Nim makes it easy too: with its uniform function call syntax, `min(thing).abs.str` and
`str(abs(min(thing)))` are the same call, so any proc chains, and Nanuq needs no `pipe`.
"""

nbText: """
## Setup
"""

tabs """
import polars as pl

extracted = "data/modern-polars/flights_2022_01_01-02.csv"
""":
  nbCode:
    import nanuq

    let extracted = "data/modern-polars/flights_2022_01_01-02.csv"

nbText: """
## Extract city names

The dataset has two columns that look like `$city, $state`. Let's define a function that removes
the state part from these columns. There's no method chaining yet but we do have a few things to
talk about while we're here:
"""

tabs """
def extract_city_name_pl() -> pl.Expr:
    '''
    Chicago, IL -> Chicago for OriginCityName and DestCityName
    '''
    cols = ["OriginCityName", "DestCityName"]
    return pl.col(cols).str.split(",").list.get(0)
""":
  nbCode:
    proc extractCityNamePl(): Expr =
      ## Chicago, IL -> Chicago for OriginCityName and DestCityName
      let cols = ["OriginCityName", "DestCityName"]
      col(cols).str.split(",").list.get(0)

nbText: """
Some items to note:

1. Our Polars function simply generates a Polars *expression*. You'll find it's often easier to
   pass around `Expr`s than dataframes because:
    1. They work on both `DataFrame` and `LazyFrame`, and they aren't bound to any particular
       data.
    2. Polars performs better if you put everything in one `.select` or `.with_columns` call,
       rather than calling `.select` multiple times. If you pass around expressions, this
       pattern is easy.
2. Polars is fast and convenient for doing the same thing to multiple columns. We can pass a
   list of columns to `pl.col` and then call a method on that `pl.col` as if it were one column.
   When the expression gets executed it will be parallelized by Polars.
3. Calling `.str.split` in Polars creates a column where every element is a list. Polars has
   first class support for list columns, and they are fast **as long as they don't have mixed
   types.**
"""

tabs """
def time_col_pl(col: str) -> pl.Expr:
    col_expr = pl.col(col)
    return (
        pl.when(col_expr == "2400")
        .then(pl.lit("0000"))
        .otherwise(col_expr)
        .str.strptime(pl.Time, "%H%M", strict=True)
        .alias(col)
    )


def time_to_datetime_pl(columns: list[str]) -> list[pl.Expr]:
    '''
    Combine all time items into datetimes.

    2014-01-01,0914 -> 2014-01-01 09:14:00
    '''
    date_col = pl.col("FlightDate")
    return [
        date_col
        .dt.combine(time_col_pl(col))
        .alias(col)
        for col in columns
    ]
""":
  nbCode:
    proc timeColPl(name: string): Expr =
      let colExpr = col(name)
      choose(if colExpr == "2400": lit("0000") else: colExpr)
        .str.strptime(TimeOfDay, "%H%M", strict = true)
        .alias(name)

    proc timeToDatetimePl(columns: openArray[string]): seq[Expr] =
      ## Combine all time items into datetimes.
      ##
      ## 2014-01-01,0914 -> 2014-01-01 09:14:00
      let dateCol = col.FlightDate
      for name in columns:
        result.add dateCol
          .dt.combine(timeColPl(name))
          .alias(name)

nbText: """
We could concatenate the date and time strings and then parse the datetime string, but here we
use the `pl.Date` and `pl.Time` dtypes. We can then combine `pl.Date` and `pl.Time` with
`.dt.combine()`.

## Bringing It All Back Home

It's time for some method chaining. First, some common variables:
"""

tabs """
category_cols = [
    "Dest",
    "Tail_Number",
    "IATA_CODE_Reporting_Airline",
    "CancellationCode",
]
time_cols = ["DepTime", "ArrTime", "CRSArrTime", "CRSDepTime"]
cols = (
    category_cols
    + time_cols
    + [
        "FlightDate",
        "Flight_Number_Reporting_Airline",
        "OriginCityName",
        "DestCityName",
        "Origin",
        "DepDelay",
    ]
)
""":
  nbCode:
    let categoryCols = @[
      "Dest",
      "Tail_Number",
      "IATA_CODE_Reporting_Airline",
      "CancellationCode"]
    let timeCols = @["DepTime", "ArrTime", "CRSArrTime", "CRSDepTime"]
    let cols = categoryCols & timeCols & @[
      "FlightDate",
      "Flight_Number_Reporting_Airline",
      "OriginCityName",
      "DestCityName",
      "Origin",
      "DepDelay"]

nbText: """
Now to read the CSVs and use the functions we defined above:
"""

tabs """
dtypes_pl = (
    {col: pl.Categorical for col in category_cols}
    | {"FlightDate": pl.Date}
    | {col: pl.String for col in time_cols}
)
df_pl = (
    pl.scan_csv(extracted, schema_overrides=dtypes_pl, null_values="")
    .select(cols)
    .with_columns([extract_city_name_pl(), *time_to_datetime_pl(time_cols)])
    .collect()
)
df_pl.head()
""":
  nbCode:
    var dtypesPl: seq[(string, DataType)]
    for c in categoryCols: dtypesPl.add (c, Categorical)
    dtypesPl.add ("FlightDate", dataType(Date))
    for c in timeCols: dtypesPl.add (c, dataType(string))

    let dfPl = scanCsv(extracted, schemaOverrides = dtypesPl, nullValues = [""])
      .select(cols)
      .withColumns(@[extractCityNamePl()] & timeToDatetimePl(timeCols))
      .collect
    nbShow dfPl.head

nbText: """
Since `scan_csv` is lazy, using `scan_csv` followed by `.select`ing a subset of columns means
only those columns are read. This is why `pl.scan_csv` itself doesn't have a parameter for
choosing a subset of columns to read. Polars does have a `.pipe` method, but we don't use it in
this case since it's easier to work with expressions.

The `.with_columns` method is for adding new columns or overwriting existing ones. But `.select`
can also do those things, so you may be wondering: what's the difference? Basically the
`.with_columns` method is just convenient for when you don't want to reselect all the columns
you're not modifying.

## Example plots

### Daily Flights

Here's how the number of daily flights is computed for plotting:
"""

tabs """
# filter for the busiest airlines
filter_expr = pl.col("IATA_CODE_Reporting_Airline").is_in(
    pl.col("IATA_CODE_Reporting_Airline")
    .value_counts(sort=True)
    .struct.field("IATA_CODE_Reporting_Airline")
    .head(5)
    .implode()
)
(
    df_pl
    .drop_nulls(subset=["DepTime", "IATA_CODE_Reporting_Airline"])
    .filter(filter_expr)
    .sort("DepTime")
    .group_by_dynamic(
        "DepTime",
        every="1h",
        group_by="IATA_CODE_Reporting_Airline")
    .agg(pl.col("Flight_Number_Reporting_Airline").count())
    .pivot(
        index="DepTime",
        on="IATA_CODE_Reporting_Airline",
        values="Flight_Number_Reporting_Airline",
        sort_columns=True,
    )
    .sort("DepTime")
    # fill every missing hour with 0 so the plot looks better
    .upsample(time_column="DepTime", every="1h")
    .fill_null(0)
    .select([pl.col("DepTime"), pl.col(pl.UInt32).rolling_sum(24)])
)
""":
  nbCode:
    # filter for the busiest airlines
    let filterExpr = col.IATA_CODE_Reporting_Airline.isIn(
      col.IATA_CODE_Reporting_Airline
        .valueCounts(sort = true)
        .struct.field("IATA_CODE_Reporting_Airline")
        .head(5)
        .implode)
    nbShow dfPl
      .dropNulls("DepTime", "IATA_CODE_Reporting_Airline")
      .filter(filterExpr)
      .sort("DepTime")
      .groupByDynamic(
        "DepTime",
        every = "1h",
        groupBy = "IATA_CODE_Reporting_Airline")
      .agg(col.Flight_Number_Reporting_Airline.count)
      .pivot(
        index = "DepTime",
        on = "IATA_CODE_Reporting_Airline",
        values = "Flight_Number_Reporting_Airline",
        sortColumns = true)
      .sort("DepTime")
      # fill every missing hour with 0 so the plot looks better
      .upsample(timeColumn = "DepTime", every = "1h")
      .fillNull(0)
      .select(col.DepTime, col(uint32).rollingSum(24))

nanuq """
The book ends the chain with `.to_pandas().set_index("DepTime").plot()`, one line of flights per
day for each of the five busiest airlines; the port shows the table. With two days of data the
24-hour rolling sum is null for the first 23 hours. Both tabs add `sort_columns=True` to the
pivot: the airline columns would otherwise come in the order the groups do, which Python's
`group_by_dynamic` does not fix.
"""

nbText: """
Some notes:

1. To group by a time window and another value, we use `.group_by_dynamic`.
2. Polars has `.rolling_sum(n)`.
3. In Polars, `.value_counts` returns a `pl.Struct` column containing the value and the value
   count.
4. In Polars we need to select all the UInt32 cols at one point using pl.col(pl.UInt32).

### Planes With Multiple Daily Flights

Now let's see if planes with multiple flights per day tend to get delayed as the day goes on:
"""

tabs """
flights_pl = (
    df_pl.select(
        pl.col([
            "FlightDate",
            "Tail_Number",
            "DepTime",
            "DepDelay"
        ])
    )
    .drop_nulls()
    .sort("DepTime")
    .filter(pl.col("DepDelay") < 500)
    .with_columns(
        pl.col("DepTime")
        .rank()
        .over(["FlightDate", "Tail_Number"])
        .alias("turn")
    )
)
(
    flights_pl.group_by("turn")
    .agg(pl.len(), pl.col("DepDelay").median().alias("median_delay"))
    .sort("turn")
)
""":
  nbCode:
    let flightsPl = dfPl.select(
        col([
          "FlightDate",
          "Tail_Number",
          "DepTime",
          "DepDelay"]))
      .dropNulls
      .sort("DepTime")
      .filter(col.DepDelay < 500)
      .withColumns(
        col.DepTime
          .rank
          .over("FlightDate", "Tail_Number")
          .alias("turn"))
    nbShow flightsPl.groupBy("turn")
      .agg(len(), col.DepDelay.median.alias("median_delay"))
      .sort("turn")

nanuq """
The book draws a seaborn box plot of `DepDelay` for each `turn`; the port summarises each box by
its median and the number of flights in it.
"""

nbText: """
One new thing here: [window functions](https://docs.pola.rs/user-guide/expressions/window-functions/).
A per-group aggregation broadcast back to the rows looks like:

```python
pl.col("population").sum().over("country")
```

### Delay by hour of the day

Maybe later flights have longer delays:
"""

tabs """
(
    df_pl.select(
        pl.col(
            ["FlightDate", "Tail_Number", "DepTime", "DepDelay"],
        )
    )
    .drop_nulls()
    .filter(pl.col("DepDelay").is_between(5, 600, closed="none"))
    .with_columns(pl.col("DepTime").dt.hour().alias("hour"))
    .group_by("hour")
    .agg(pl.len(), pl.col("DepDelay").median().alias("median_delay"))
    .sort("hour")
)
""":
  nbCode:
    nbShow dfPl.select(
        col(["FlightDate", "Tail_Number", "DepTime", "DepDelay"]))
      .dropNulls
      .filter(col.DepDelay.isBetween(5, 600, closed = ClosedInterval.None))
      .withColumns(col.DepTime.dt.hour.alias("hour"))
      .groupBy("hour")
      .agg(len(), col.DepDelay.median.alias("median_delay"))
      .sort("hour")

nbText: """
## How much is too much?

The above examples have some fairly long method chains that could perhaps be split up. That
said, if I saw them in a PR I probably wouldn't mind. A chain can be too long, though: one that
is not hard to follow can still be visually shocking, which is often a hallmark of terrible
code. That's enough reason to avoid doing this. You don't want folks assuming you've lost your
mind.

It is often enough to just move long lists to their own variables. That makes it more obvious
that the code is really doing simple, menial things.

## Summary

- Method chaining is great but use it with care.
- I've noticed some people are under the impression that you should only use Polars when you
  need the performance, but I would argue the above examples show that it's better for small
  data too.
"""

bookSave()
