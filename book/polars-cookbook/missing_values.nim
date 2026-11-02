import nanuqbook
bookInit()

nbText: "# Handling missing values"

attribution polarsCookbook(5, "Handling Missing Values",
  "Data is read from `data/polars-cookbook/`. The Python side writes `float(\"nan\")` " &
  "where the book uses NumPy's `np.nan`.")

nbText: """
Data has holes. Polars has two kinds: **null**, a missing value of any type, and **NaN**,
a floating-point value meaning "not a number". They behave differently (`null_count` sees
only nulls, `is_nan` only NaNs), so each recipe here does things twice. The data is a
fortnight of daily temperatures with both kinds of holes.

## Identifying missing values
"""

tabs """
import polars as pl
from datetime import date

date_col = pl.date_range(date(2023, 1, 1), date(2023, 1, 15), '1d', eager=True)
nan = float("nan")
avg_temp_c_list = [-3,None,6,-1,nan,6,4,None,1,2,nan,7,9,-2,None]
df = pl.DataFrame({
    'date': date_col,
    'avg_temp_celsius': avg_temp_c_list
}, strict=False)
df.head()
""":
  nbCode:
    import std/[math, sugar]
    import nanuq

    var df = newDataFrame:
      avg_temp_celsius: [-3.0, nil, 6.0, -1.0, NaN, 6.0, 4.0, nil, 1.0, 2.0, NaN, 7.0, 9.0, -2.0, nil]
    df = df.select(
      dateRange(date(2023, 1, 1), date(2023, 1, 15), "1d").alias("date"),
      col.avg_temp_celsius)
    nbShow df.head()

nanuq """
A date range is an expression in Nanuq (Python's `eager=False`), so the frame gets its
`date` column from a `select`. In the column block, `nil` is a null and `NaN` (from
`std/math`) is a NaN.
"""

nbText: """
### How to do it...

Count the nulls of every column, of some columns, or of one expression:
"""

tabs """
df.null_count()
""":
  nbCode:
    nbShow df.nullCount()

tabs """
df.select('avg_temp_celsius').null_count()
""":
  nbCode:
    nbShow df.select("avg_temp_celsius").nullCount()

tabs """
df.select(pl.col('avg_temp_celsius').null_count())
""":
  nbCode:
    nbShow df.select(col.avg_temp_celsius.nullCount)

nbText: """
`is_null` gives a Boolean per row, and summing it counts the `true`s. Filtering on it and
counting the rows says the same:
"""

tabs """
df.select(
    pl.col('avg_temp_celsius')
    .is_null()
    .sum()
)
""":
  nbCode:
    nbShow df.select(col.avg_temp_celsius.isNull.sum)

tabs """
(
    df
    .filter(pl.col('avg_temp_celsius').is_null())
    .select(pl.len())
)
""":
  nbCode:
    nbShow df.filter(col.avg_temp_celsius.isNull).select(len())

tabs """
df.filter(pl.col('avg_temp_celsius').is_null()).shape[0]
""":
  nbCode:
    echo df.filter(col.avg_temp_celsius.isNull).shape[0]

nbText: """
NaNs are counted with `is_nan`:
"""

tabs """
df.select(
    pl.col('avg_temp_celsius')
    .is_nan()
    .sum()
)
""":
  nbCode:
    nbShow df.select(col.avg_temp_celsius.isNan.sum)

tabs """
(
    df
    .filter(pl.col('avg_temp_celsius').is_nan())
    .select(pl.len())
)
""":
  nbCode:
    nbShow df.filter(col.avg_temp_celsius.isNan).select(len())

nbText: """
## Deleting rows and columns containing missing values

### How to do it...

The same temperatures, now read from a CSV file (where the dates stay strings):
"""

tabs """
df = pl.read_csv('data/polars-cookbook/temperatures.csv')
df.head()
""":
  nbCode:
    df = readCsv("data/polars-cookbook/temperatures.csv")
    nbShow df.head()

nbText: """
`drop_nulls` drops every row with a null, on the frame or on a single expression:
"""

tabs """
df.drop_nulls().null_count()
""":
  nbCode:
    nbShow df.dropNulls().nullCount()

tabs """
df.select(
    pl.col('avg_temp_celsius')
    .drop_nulls()
    .null_count()
)
""":
  nbCode:
    nbShow df.select(col.avg_temp_celsius.dropNulls.nullCount)

tabs """
df.filter(pl.col('avg_temp_celsius').is_not_null())
""":
  nbCode:
    nbShow df.filter(col.avg_temp_celsius.isNotNull)

nbText: """
To drop the columns that have a null, ask each column whether it has any:
"""

tabs """
cols_to_drop = [column for column in df.columns if df.select(pl.col(column).is_null().any()).item()]
df.drop(cols_to_drop).columns
""":
  nbCode:
    block:
      let colsToDrop = sugar.collect:
        for column in df.columns:
          if df.select(col(column).isNull.any).toSeries.item(bool): column
      echo df.drop(colsToDrop).columns

nbText: """
The NaN versions: `drop_nans`, `is_not_nan`, and a selector for the float columns.
"""

tabs """
df.select(
    pl.col('avg_temp_celsius')
    .drop_nans()
    .is_nan()
    .sum()
)
""":
  nbCode:
    nbShow df.select(col.avg_temp_celsius.dropNans.isNan.sum)

tabs """
df.filter(pl.col('avg_temp_celsius').is_not_nan())
""":
  nbCode:
    nbShow df.filter(col.avg_temp_celsius.isNotNan)

tabs """
import polars.selectors as cs
cols_to_drop = df.select(cs.float().is_nan().any()).columns
df.drop(cols_to_drop).columns
""":
  nbCode:
    let colsToDrop = df.select(col(float).isNan.any).columns
    echo df.drop(colsToDrop).columns

tabs """
df.select(pl.exclude(cols_to_drop)).columns
""":
  nbCode:
    echo df.select(all().exclude(colsToDrop)).columns

nbText: """
### There is more...

Turning NaNs into nulls first lets one `drop_nulls` remove both kinds:
"""

tabs """
df.fill_nan(None).drop_nulls()
""":
  nbCode:
    nbShow df.fillNan(nil).dropNulls()

nbText: """
## Filling missing values

### How to do it...

A constant fills nulls. Here it is the string `'1'`, so the column becomes a string
column:
"""

tabs """
df.select(
    'avg_temp_celsius',
    avg_temp_nulls_filled=pl.col('avg_temp_celsius').fill_null(pl.lit('1'))
)
""":
  nbCode:
    nbShow df.select(
      col.avg_temp_celsius,
      col.avg_temp_celsius.fillNull(lit("1")).alias("avg_temp_nulls_filled"))

nbText: """
Or a strategy: the previous or next value, or the mean, minimum or maximum of the column.
"""

tabs """
df.select(
    'avg_temp_celsius',
    forward_filled=pl.col('avg_temp_celsius').fill_null(strategy='forward'),
    backward_filled=pl.col('avg_temp_celsius').fill_null(strategy='backward'),
    mean_filled=pl.col('avg_temp_celsius').fill_null(strategy='mean'),
    min_filled=pl.col('avg_temp_celsius').fill_null(strategy='min'),
    max_filled=pl.col('avg_temp_celsius').fill_null(strategy='max'),
)
""":
  nbCode:
    nbShow df.select(
      col.avg_temp_celsius,
      col.avg_temp_celsius.fillNull(FillNullStrategy.Forward).alias("forward_filled"),
      col.avg_temp_celsius.fillNull(FillNullStrategy.Backward).alias("backward_filled"),
      col.avg_temp_celsius.fillNull(FillNullStrategy.Mean).alias("mean_filled"),
      col.avg_temp_celsius.fillNull(FillNullStrategy.Min).alias("min_filled"),
      col.avg_temp_celsius.fillNull(FillNullStrategy.Max).alias("max_filled"))

nbText: """
Interpolation draws a line between the neighbours (`linear`) or takes the nearest one:
"""

tabs """
df.select(
    'avg_temp_celsius',
    interpolated_linear=pl.col('avg_temp_celsius').interpolate(),
    interpolated_nearest=pl.col('avg_temp_celsius').interpolate(method='nearest')
)
""":
  nbCode:
    nbShow df.select(
      col.avg_temp_celsius,
      col.avg_temp_celsius.interpolate.alias("interpolated_linear"),
      col.avg_temp_celsius.interpolate(InterpolationMethod.Nearest).alias("interpolated_nearest"))

nbText: """
The fill value can be any expression, such as the median, or the range of the column:
"""

tabs """
df.select(
    'avg_temp_celsius',
    avg_temp_median=pl.col('avg_temp_celsius')
        .fill_null(
            pl.col('avg_temp_celsius').median()
        ),
    avg_temp_max_minus_min=pl.col('avg_temp_celsius')
        .fill_null(
            pl.col('avg_temp_celsius').max() - pl.col('avg_temp_celsius').min()
        )
)
""":
  nbCode:
    nbShow df.select(
      col.avg_temp_celsius,
      col.avg_temp_celsius.fillNull(col.avg_temp_celsius.median).alias("avg_temp_median"),
      col.avg_temp_celsius.fillNull(
        col.avg_temp_celsius.max - col.avg_temp_celsius.min).alias("avg_temp_max_minus_min"))

nbText: """
### There is more...

`forward_fill` and `backward_fill` take a `limit`: how many nulls in a row to fill.
"""

tabs """
df = pl.DataFrame(
    {'values': [1,2,None,None,None,3,4,None,5]}
)
df
""":
  nbCode:
    df = newDataFrame:
      values: [1, 2, nil, nil, nil, 3, 4, nil, 5]
    nbShow df

tabs """
df.select(
    'values',
    forward_fill=pl.col('values').forward_fill(),
    forward_fill_1=pl.col('values').forward_fill(limit=1),
    backward_fill=pl.col('values').backward_fill(),
    backward_fill_2=pl.col('values').backward_fill(limit=2),
)
""":
  nbCode:
    nbShow df.select(
      col.values,
      col.values.forwardFill.alias("forward_fill"),
      col.values.forwardFill(limit = 1).alias("forward_fill_1"),
      col.values.backwardFill.alias("backward_fill"),
      col.values.backwardFill(limit = 2).alias("backward_fill_2"))

bookSave()
