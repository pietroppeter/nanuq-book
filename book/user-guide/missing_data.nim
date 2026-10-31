import nanuqbook
bookInit()

nbText: "# Missing data"

attribution userGuide("Missing data", "expressions/missing-data",
  "Left out: `interpolate` and `fill_nan` (not in Nanuq yet; the `fill_nan` example runs " &
  "on the Python side only). Nanuq has no frame-wide `null_count`, so the Nim side counts " &
  "with `isNull.sum`, and casts to `float` before dividing two integer columns (Nanuq's `/` " &
  "divides integers as integers).")

nbText: """
This section of the user guide teaches how to work with missing data in Polars.

## `null` and `NaN` values

In Polars, missing data is represented by the value `null`. This missing value `null` is
used for all data types, including numerical types.

Polars also supports the value `NaN` (“Not a Number”) for columns with floating point
numbers. The value `NaN` is considered to be a valid floating point value, which is
different from missing data.
[We discuss the value `NaN` separately below](#not-a-number-or-nan-values).

When creating a series or a dataframe, you can set a value to `null` by using the
appropriate construct for your language:
"""

nanuq """
In Python that is `None`; in Nim a column with missing values is built from `Option`
values, `some(x)` and `none(T)`.
"""

tabs """
import polars as pl

df = pl.DataFrame(
    {
        "value": [1, None],
    },
)
df
""":
  nbCode:
    import nanuq

    let df = newDataFrame(series("value", [some(1), none(int)]))
    nbShow df

nbText: """
> **Difference from pandas.** In pandas, the value used to represent missing data depends
> on the data type of the column. In Polars, missing data is always represented by the
> value `null`.

## Missing data metadata

Polars keeps track of some metadata regarding the missing data of each series. This
metadata allows Polars to answer some basic queries about missing values in a very
efficient way, namely how many values are missing and which ones are missing.

To determine how many values are missing from a column you can use the function
`null_count`:
"""

nanuq """
Nanuq has no `null_count` on a whole dataframe yet. `df.nullCount("value")` gives the count
for one column as an `int`; for the same dataframe as in Python, sum the `isNull` flags of
each column.
"""

tabs """
df.null_count()
""":
  nbCode:
    let nullCountDf = df.select(col("value").isNull.sum)
    nbShow nullCountDf

nbText: """
The function `null_count` can be called on a dataframe, a column from a dataframe, or on a
series directly. The function `null_count` is a cheap operation because the result is
already known.

Polars uses something called a “validity bitmap” to know which values are missing in a
series. The validity bitmap is memory efficient as it is bit encoded. If a series has length
*n*, then its validity bitmap will cost *n* / 8 bytes. The function `is_null` uses the
validity bitmap to efficiently report which values are `null` and which are not:
"""

nanuq """
In Nanuq it is `isNull`, and `fill_null` below is `fillNull`.
"""

tabs """
df.select(
    pl.col("value").is_null(),
)
""":
  nbCode:
    let isNullSeries = df.select(col("value").isNull)
    nbShow isNullSeries

nbText: """
The function `is_null` can be used on a column of a dataframe or on a series directly.
Again, this is a cheap operation because the result is already known by Polars.

> **Why does Polars waste memory on a validity bitmap?**
>
> It all comes down to a tradeoff. By using a bit more memory per column, Polars can be much
> more efficient when performing most operations on your columns. If the validity bitmap
> wasn't known, every time you wanted to compute something you would have to check each
> position of the series to see if a legal value was present or not. With the validity
> bitmap, Polars knows automatically the positions where your operations can be applied.

## Filling missing data

Missing data in a series can be filled with the function `fill_null`. You can specify how missing data is effectively filled in a couple of different ways:

- a literal of the correct data type;
- a Polars expression, such as replacing with values computed from another column;
- a strategy based on neighbouring values, such as filling forwards or backwards; and
- interpolation.

To illustrate how each of these methods work we start by defining a simple dataframe with
two missing values in the second column:
"""

tabs """
df = pl.DataFrame(
    {
        "col1": [0.5, 1, 1.5, 2, 2.5],
        "col2": [1, None, 3, None, 5],
    },
)
df
""":
  nbCode:
    let df2 = newDataFrame(
      series("col1", [0.5, 1, 1.5, 2, 2.5]),
      series("col2", [some(1), none(int), some(3), none(int), some(5)]))
    nbShow df2

nbText: """
### Fill with a specified literal value

You can fill the missing data with a specified literal value. This literal value will
replace all of the occurrences of the value `null`:
"""

tabs """
df.with_columns(
    pl.col("col2").fill_null(3),
)
""":
  nbCode:
    let fillLiteralDf = df2.withColumns(col("col2").fillNull(3))
    nbShow fillLiteralDf

nbText: """
However, this is actually just a special case of the general case where
[the function `fill_null` replaces missing values with the corresponding values from the result of a Polars expression](#fill-with-a-strategy-based-on-neighbouring-values),
as seen next.

### Fill with an expression

In the general case, the missing data can be filled by extracting the corresponding values
from the result of a general Polars expression. For example, we can fill the second column
with values taken from the double of the first column:
"""

tabs """
df.with_columns(
    pl.col("col2").fill_null((2 * pl.col("col1")).cast(pl.Int64)),
)
""":
  nbCode:
    let fillExpressionDf = df2.withColumns(
      col("col2").fillNull((2 * col("col1")).cast(Int64)))
    nbShow fillExpressionDf

nbText: """
### Fill with a strategy based on neighbouring values

You can also fill the missing data by following a fill strategy based on the neighbouring
values. The two simpler strategies look for the first non-`null` value that comes
immediately before or immediately after the value `null` that is being filled:
"""

nanuq """
In Nanuq a strategy is a value of the enum `FillNullStrategy`, where Python uses a string.
"""

tabs """
df.with_columns(
    pl.col("col2").fill_null(strategy="forward").alias("forward"),
    pl.col("col2").fill_null(strategy="backward").alias("backward"),
)
""":
  nbCode:
    let fillForwardDf = df2.withColumns(
      col("col2").fillNull(Forward).alias("forward"),
      col("col2").fillNull(Backward).alias("backward"))
    nbShow fillForwardDf

nbText: """
You can find other fill strategies in the API docs.
"""

nanuq """
Nanuq's other strategies fill with the column's `Min`, `Max`, `Mean`, `Zero` or `One`. The
original's next section, “Fill with interpolation”, is left out: `interpolate` is not in
Nanuq yet.
"""

nbText: """
## Not a Number, or `NaN` values

Missing data in a series is only ever represented by the value `null`, regardless of the
data type of the series. Columns with a floating point data type can sometimes have the
value `NaN`, which might be confused with `null`.

The special value `NaN` can be created directly:
"""

tabs """
import numpy as np

nan_df = pl.DataFrame(
    {
        "value": [1.0, np.nan, float("nan"), 3.0],
    },
)
nan_df
""":
  nbCode:
    let nanDf = newDataFrame(series("value", [1.0, NaN, NaN, 3.0]))
    nbShow nanDf

nbText: """
And it might also arise as the result of a computation:
"""

nanuq """
In Nanuq 0.2, `/` between two integer columns is an integer division, as in Rust Polars,
while Python's `/` always divides as floats. So the Nim side casts the dividend to `float`
first. This choice is debated and may change in a later Nanuq: `/` could become a float
division, as in Python Polars and in Nim itself, leaving integer division to `div`.
"""

tabs """
df = pl.DataFrame(
    {
        "dividend": [1, 0, -1],
        "divisor": [1, 0, -1],
    }
)
df.select(pl.col("dividend") / pl.col("divisor"))
""":
  nbCode:
    let df3 = newDataFrame(series("dividend", [1, 0, -1]), series("divisor", [1, 0, -1]))
    let divided = df3.select(col("dividend").cast(float) / col("divisor"))
    nbShow divided

nbText: """
> By default, a `NaN` value in an integer column causes the column to be cast to a float
> data type in pandas. This does not happen in Polars; instead, an exception is raised.

`NaN` values are considered to be a type of floating point data and are **not considered to
be missing data** in Polars. This means:

- `NaN` values are **not** counted with the function `null_count`; and
- `NaN` values are filled when you use the specialised function `fill_nan` method but are
  **not** filled with the function `fill_null`.

Polars has the functions `is_nan` and `fill_nan`, which work in a similar way to the
functions `is_null` and `fill_null`. Unlike with missing data, Polars does not hold any
metadata regarding the `NaN` values, so the function `is_nan` entails actual computation.

One further difference between the values `null` and `NaN` is that numerical aggregating
functions, like `mean` and `sum`, skip the missing values when computing the result, whereas
the value `NaN` is considered for the computation and typically propagates into the result.
If desirable, this behavior can be avoided by replacing the occurrences of the value `NaN`
with the value `null`:
"""

nanuq """
Nanuq has no `fill_nan` yet, so this one runs in Python only.
"""

python """
nan_df.with_columns(
    pl.col("value").fill_nan(None).alias("replaced"),
).select(
    pl.all().mean().name.suffix("_mean"),
    pl.all().sum().name.suffix("_sum"),
)
"""

nbText: """
You can learn more about the value `NaN` in
[the section about floating point number data types](https://docs.pola.rs/user-guide/concepts/data-types-and-structures/#floating-point-numbers).
"""

bookSave()
