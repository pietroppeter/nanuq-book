import nanuqbook
bookInit()

nbText: "# Timeseries"

attribution modernPolars("Timeseries", "timeseries",
  "The tables show 10 rows instead of 5. The data is the book's `ohlcv.pq` (daily Bitcoin prices for 2021, which the book " &
  "downloaded from Binance), read from `data/modern-polars/`; the download code is left " &
  "out. The two plots are shown as the tables they draw.")

nbText: """
Temporal data is an area in which Pandas actually far outshines R's dataframe libraries. Things
like resampling and rolling calculations are baked into the dataframe library and work quite
well. Fortunately this is also true of Polars!

## Get the data

We'll download a year's worth of daily price and volume data for Bitcoin:
"""

tabs """
from datetime import date
import polars as pl

ohlcv_pl = pl.read_parquet("data/modern-polars/ohlcv.pq").set_sorted("time")
ohlcv_pl
""":
  nbCode:
    import nanuq

    let ohlcvPl = readParquet("data/modern-polars/ohlcv.pq").setSorted("time")
    nbShow ohlcvPl

nanuq """
The book fetches the year from Binance's `klines` API the first time and keeps it as
`ohlcv.pq`; the port reads that file. The book also sets `pl.Config.set_tbl_rows(5)`; the port
keeps the default of 10 rows, because Nanuq's `setTblRows` changes printed frames but not yet
the HTML tables of `nbShow`.
"""

nbText: """
## Filtering

Since Polars doesn't have an index, we just use `.filter`:
"""

tabs """
ohlcv_pl.filter(
    pl.col("time").is_between(
        date(2021, 2, 1),
        date(2021, 3, 1),
        closed="left"
    )
)
""":
  nbCode:
    nbShow ohlcvPl.filter(
      col.time.isBetween(
        date(2021, 2, 1),
        date(2021, 3, 1),
        closed = ClosedInterval.Left))

nbText: """
## Resampling

Resampling is like a special case of `group_by` for a time column. You can of course use
regular `.group_by` with a time column, but it won't be as powerful because it doesn't
understand time like resampling methods do.

There are two kinds of resampling: *downsampling* and *upsampling*.

### Downsampling

Downsampling moves from a higher time frequency to a lower time frequency. This requires some
aggregation or subsetting, since we're reducing the number of rows in our data.

In Polars we use the
[`.group_by_dynamic`](https://docs.pola.rs/api/python/stable/reference/dataframe/api/polars.DataFrame.group_by_dynamic.html)
method for downsampling (we also use `group_by_dynamic` when we want to combine resampling with
regular group_by logic).
"""

tabs """
(
    ohlcv_pl
    .group_by_dynamic("time", every="5d")
    .agg(pl.col(pl.Float64).mean())
)
""":
  nbCode:
    nbShow ohlcvPl
      .groupByDynamic("time", every = "5d")
      .agg(col(float).mean)

nanuq """
`col(float)` selects the `Float64` columns, as `pl.col(pl.Float64)` does: Nanuq selects columns
by Nim type.
"""

nbText: """
Resampling and performing multiple aggregations to each column:
"""

tabs """
(
    ohlcv_pl
    .group_by_dynamic("time", every="1w", start_by="friday")
    .agg([
        pl.col(pl.Float64).mean().name.suffix("_mean"),
        pl.col(pl.Float64).sum().name.suffix("_sum")
    ])
)
""":
  nbCode:
    nbShow ohlcvPl
      .groupByDynamic("time", every = "1w", startBy = StartBy.Friday)
      .agg(
        col(float).mean.name.suffix("_mean"),
        col(float).sum.name.suffix("_sum"))

nbText: """
### Upsampling

Upsampling moves in the opposite direction, from low-frequency data to high frequency data.
Since we can't create new data by magic, upsampling defaults to filling the new rows with nulls
(which we could then interpolate, perhaps). In Polars we have a special
[`upsample`](https://docs.pola.rs/api/python/stable/reference/dataframe/api/polars.DataFrame.upsample.html)
method for this.
"""

tabs """
ohlcv_pl.upsample("time", every="6h")
""":
  nbCode:
    nbShow ohlcvPl.upsample("time", every = "6h")

nbText: """
## Rolling / Expanding / EW

Polars supports all three of these. Custom rolling and expanding aggregations are supported in
Polars using `expr.rolling_map` and `expr.cumulative_eval` respectively, but the docs recommend
against using them for performance reasons.
"""

tabs """
close = pl.col("close")
ohlcv_pl.select(
    [
        pl.col("time"),
        close.alias("Raw"),
        close.rolling_mean(28).alias("28D MA"),
        (close.cum_sum() / close.cum_count()).alias("Expanding Average"),
        close.ewm_mean(alpha=0.03).alias("EWMA($\\alpha=.03$)"),
    ]
)
""":
  nbCode:
    let close = col.close
    nbShow ohlcvPl.select(
      col.time,
      close.alias("Raw"),
      close.rollingMean(28).alias("28D MA"),
      (close.cumSum / close.cumCount).alias("Expanding Average"),
      close.ewmMean(alpha = 0.03).alias("EWMA($\\alpha=.03$)"))

nanuq """
The book plots these four lines (via pandas and matplotlib, with `plt.ylabel("Close ($)")`);
the port shows the table that the plot is drawn from.
"""

nbText: """
Polars doesn't have an `expanding_mean` or `cum_mean` yet so we make do by combining `cum_sum`
and `cum_count`. You could also use `cumulative_eval`, but it's much slower on large columns,
and the docs recommend against it for performance reasons.

### Combining rolling aggregations
"""

tabs """
mean_std_pl = ohlcv_pl.select(
    [
        "time",
        pl.col("close").rolling_mean(30, center=True).alias("mean"),
        pl.col("close").rolling_std(30, center=True).alias("std"),
    ]
)
mean_std_pl
""":
  nbCode:
    let meanStdPl = ohlcvPl.select(
      col.time,
      col.close.rollingMean(30, center = true).alias("mean"),
      col.close.rollingStd(30, center = true).alias("std"))
    nbShow meanStdPl

nanuq """
The book draws the mean as a line with a band of one standard deviation around it; the port
shows the two columns.
"""

nbText: """
## Grab Bag

### Offsets

Polars has a `Duration` type for datetime arithmetic, which respects absolute time arithmetic:
"""

tabs """
ohlcv_pl.select(pl.col("time") + pl.duration(days=80))
""":
  nbCode:
    nbShow ohlcvPl.select(col.time + duration(days = 80))

nbText: """
### Holiday calendars

Some functionality for working with business days is available in Polars in the
[`expr.dt` namespace](https://docs.pola.rs/api/python/stable/reference/expressions/temporal.html).

### Timezones

Suppose we know that our timestamps are UTC, and we want to see what time it was in
`US/Eastern`:
"""

tabs """
(
    ohlcv_pl
    .with_columns(
        pl.col("time")
        .cast(pl.Datetime)
        .dt.replace_time_zone("UTC")
        .dt.convert_time_zone("US/Eastern")
    )
)
""":
  nbCode:
    nbShow ohlcvPl
      .withColumns(
        col.time
          .cast(DateTime)
          .dt.replaceTimeZone("UTC")
          .dt.convertTimeZone("US/Eastern"))

nbText: """
## Conclusion

Polars has really good time series support, though expanding aggregations and holiday calendars
are niches in which it is somewhat lacking.
"""

bookSave()
