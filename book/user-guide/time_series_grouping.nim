import nanuqbook
bookInit()

nbText: "# Time series: grouping"

attribution userGuide("Grouping", "transformations/time-series/rolling",
  "The data is read from `data/polars/apple_stock.csv`. The column `day/eom` of the " &
  "month example is a list per month, and Nanuq has no lists yet, so that example runs " &
  "in Python first and then on both sides without it. Nanuq has no `pl.len()`: the Nim " &
  "side counts the rows of a group with `len` on a column.")

nbText: """
## Grouping by fixed windows

We can calculate temporal statistics using `group_by_dynamic` to group rows into
days/months/years etc.

### Annual average example

In following simple example we calculate the annual average closing price of Apple stock
prices. We first load the data from CSV:
"""

tabs """
from datetime import date, datetime

import polars as pl

df = pl.read_csv("data/polars/apple_stock.csv", try_parse_dates=True)
df = df.sort("Date")
df
""":
  nbCode:
    import std/times
    import nanuq

    var df = readCsv("data/polars/apple_stock.csv", tryParseDates = true)
    df = df.sort("Date")
    nbShow df

nbText: """
> **Info.** The dates are sorted in ascending order - if they are not sorted in this way
> the `group_by_dynamic` output will not be correct!

To get the annual average closing price we tell `group_by_dynamic` that we want to:

- group by the `Date` column on an annual (`1y`) basis
- take the mean values of the `Close` column for each year:

The annual average closing price is then:
"""

nanuq """
In Nanuq `groupByDynamic` returns a lazy group-by, so `agg` gives a `LazyFrame` to
`collect`. `every` is a Polars interval (`"1y"`) or a std/times one (`1.years`).
"""

tabs """
annual_average_df = df.group_by_dynamic("Date", every="1y").agg(pl.col("Close").mean())

df_with_year = annual_average_df.with_columns(pl.col("Date").dt.year().alias("year"))
df_with_year
""":
  nbCode:
    let annualAverageDf = df.groupByDynamic("Date", every = "1y")
      .agg(col("Close").mean).collect

    let dfWithYear = annualAverageDf.withColumns(col("Date").dt.year.alias("year"))
    nbShow dfWithYear

nbText: """
### Parameters for `group_by_dynamic`

A dynamic window is defined by a:

- **every**: indicates the interval of the window
- **period**: indicates the duration of the window
- **offset**: can be used to offset the start of the windows

The value for `every` sets how often the groups start. The time period values are flexible
- for example we could take:

- the average over 2 year intervals by replacing `1y` with `2y`
- the average over 18 month periods by replacing `1y` with `1y6mo`

We can also use the `period` parameter to set how long the time period for each group is.
For example, if we set the `every` parameter to be `1y` and the `period` parameter to be
`2y` then we would get groups at one year intervals where each groups spanned two years.

If the `period` parameter is not specified then it is set equal to the `every` parameter
so that if the `every` parameter is set to be `1y` then each group spans `1y` as well.

Because _**every**_ does not have to be equal to _**period**_, we can create many groups
in a very flexible way. They may overlap or leave boundaries between them.

Let's see how the windows for some parameter combinations would look. Let's start out
boring. 🥱

- every: 1 day -> `"1d"`
- period: 1 day -> `"1d"`

```text
this creates adjacent windows of the same size
|--|
   |--|
      |--|
```

- every: 1 day -> `"1d"`
- period: 2 days -> `"2d"`

```text
these windows have an overlap of 1 day
|----|
   |----|
      |----|
```

- every: 2 days -> `"2d"`
- period: 1 day -> `"1d"`

```text
this would leave gaps between the windows
data points that in these gaps will not be a member of any group
|--|
       |--|
              |--|
```

#### `truncate`

The `truncate` parameter is a Boolean variable that determines what datetime value is
associated with each group in the output. In the example above the first data point is on
23rd February 1981. If `truncate = True` (the default) then the date for the first year in
the annual average is 1st January 1981. However, if `truncate = False` then the date for
the first year in the annual average is the date of the first data point on 23rd February
1981. Note that `truncate` only affects what's shown in the `Date` column and does not
affect the window boundaries.
"""

nanuq """
Current Polars has no `truncate` parameter any more; its `label` parameter (`Label.Left`,
the default, `Right` or `DataPoint`) decides which date names a window, and Nanuq has it
too.
"""

nbText: """
### Using expressions in `group_by_dynamic`

We aren't restricted to using simple aggregations like `mean` in a group by operation - we
can use the full range of expressions available in Polars.

In the snippet below we create a `date range` with every **day** (`"1d"`) in 2021 and turn
this into a `DataFrame`.

Then in the `group_by_dynamic` we create dynamic windows that start every **month**
(`"1mo"`) and have a window length of `1` month. The values that match these dynamic
windows are then assigned to that group and can be aggregated with the powerful expression
API.

Below we show an example where we use **group_by_dynamic** to compute:

- the number of days until the end of the month
- the number of days in a month
"""

nanuq """
The number of days until the end of the month, `day/eom`, keeps three values per month:
a list column, which Nanuq does not have yet. So the original runs in Python only, and
then both sides compute the number of days in a month.
"""

python """
df = (
    pl.date_range(
        start=date(2021, 1, 1),
        end=date(2021, 12, 31),
        interval="1d",
        eager=True,
    )
    .alias("time")
    .to_frame()
)

df.group_by_dynamic("time", every="1mo", period="1mo", closed="left").agg(
    pl.col("time").cum_count().reverse().head(3).alias("day/eom"),
    ((pl.col("time") - pl.col("time").first()).last().dt.total_days() + 1).alias(
        "days_in_month"
    ),
)
"""

nanuq """
`dateRange` is an expression, so Nanuq selects it from an empty frame (there is no
`eager=True`). The window's closed side is a value of the enum `ClosedWindow`.
"""

tabs """
df.group_by_dynamic("time", every="1mo", period="1mo", closed="left").agg(
    ((pl.col("time") - pl.col("time").first()).last().dt.total_days() + 1).alias(
        "days_in_month"
    ),
)
""":
  nbCode:
    let days = newDataFrame().select(
      dateRange(start = date(2021, 1, 1), stop = date(2021, 12, 31), interval = "1d")
        .alias("time"))

    let daysInMonth = days.groupByDynamic("time", every = "1mo", period = "1mo",
                                          closed = ClosedWindow.Left).agg(
      ((col("time") - col("time").first).last.dt.totalDays + 1).alias("days_in_month")
    ).collect
    nbShow daysInMonth

nbText: """
## Grouping by rolling windows

The rolling operation, `rolling`, is another entrance to the `group_by`/`agg` context. But
different from the `group_by_dynamic` where the windows are fixed by a parameter `every`
and `period`. In a `rolling`, the windows are not fixed at all! They are determined by the
values in the `index_column`.

So imagine having a time column with the values `{2021-01-06, 2021-01-10}` and a
`period="5d"` this would create the following windows:

```text
2021-01-01   2021-01-06
    |----------|

       2021-01-05   2021-01-10
             |----------|
```

Because the windows of a rolling group by are always determined by the values in the
`DataFrame` column, the number of groups is always equal to the original `DataFrame`.
"""

nanuq """
The original has no code for `rolling`. In Nanuq it is `df.rolling("time", period = "5d")`
followed by `agg`, like `groupByDynamic`.
"""

nbText: """
## Combining group by operations

Rolling and dynamic group by operations can be combined with normal group by operations.

Below is an example with a dynamic group by.
"""

tabs """
df = pl.DataFrame(
    {
        "time": pl.datetime_range(
            start=datetime(2021, 12, 16),
            end=datetime(2021, 12, 16, 3),
            interval="30m",
            eager=True,
        ),
        "groups": ["a", "a", "a", "b", "b", "a", "a"],
    }
)
df
""":
  nbCode:
    let df2 = newDataFrame().select(
      datetimeRange(start = dateTime(2021, mDec, 16, zone = utc()),
                    stop = dateTime(2021, mDec, 16, 3, zone = utc()),
                    interval = "30m").alias("time")
    ).withColumns(series("groups", ["a", "a", "a", "b", "b", "a", "a"]))
    nbShow df2

nanuq """
`group_by` within the windows is `groupBy`, a list of expressions.
"""

tabs """
df.group_by_dynamic(
    "time",
    every="1h",
    closed="both",
    group_by="groups",
    include_boundaries=True,
).agg(pl.len())
""":
  nbCode:
    let byHour = df2.groupByDynamic(
      "time",
      every = "1h",
      closed = ClosedWindow.Both,
      groupBy = [col("groups")],
      includeBoundaries = true,
    ).agg(col("time").len.alias("len")).collect
    nbShow byHour

bookSave()
