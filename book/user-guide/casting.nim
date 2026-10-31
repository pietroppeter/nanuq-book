import nanuqbook
bookInit()

nbText: "# Casting"

attribution userGuide("Casting", "expressions/casting",
  "Left out: the memory sizes in the downcasting example (`estimated_size` is not in Nanuq " &
  "yet; the dtypes are shown instead) and the section on temporal data types (Nanuq has no " &
  "dates yet).")

nbText: """
Casting converts the underlying data type of a column to a new one. Casting is available
through the function `cast`.

The function `cast` includes a parameter `strict` that determines how Polars behaves when it
encounters a value that cannot be converted from the source data type to the target data
type. The default behaviour is `strict=True`, which means that Polars will throw an error to
notify the user of the failed conversion while also providing details on the values that
couldn't be cast. On the other hand, if `strict=False`, any values that cannot be converted
to the target data type will be quietly converted to `null`.

In Nanuq the target is a data type constant with Polars' name (`Float32`, `Int32`) or a Nim
type (`float32`, `int32`), and `cast` is called after a dot, since `cast` is a Nim keyword.

## Basic example

Let's take a look at the following dataframe which contains both integers and floating point
numbers:
"""

tabs """
import polars as pl

df = pl.DataFrame(
    {
        "integers": [1, 2, 3],
        "big_integers": [10000002, 2, 30000003],
        "floats": [4.0, 5.8, -6.3],
    }
)
df
""":
  nbCode:
    import nanuq

    let df = newDataFrame(
      series("integers", [1, 2, 3]),
      series("big_integers", [10000002, 2, 30000003]),
      series("floats", [4.0, 5.8, -6.3]))
    nbShow df

nbText: """
To perform casting operations between floats and integers, or vice versa, we use the
function `cast`:
"""

tabs """
df.select(
    pl.col("integers").cast(pl.Float32).alias("integers_as_floats"),
    pl.col("floats").cast(pl.Int32).alias("floats_as_integers"),
)
""":
  nbCode:
    let numbers = df.select(
      col("integers").cast(Float32).alias("integers_as_floats"),
      col("floats").cast(Int32).alias("floats_as_integers"))
    nbShow numbers

nbText: """
Note that floating point numbers are truncated when casting to an integer data type.

## Downcasting numerical data types

You can reduce the memory footprint of a column by changing the precision associated with
its numeric data type. As an illustration, the code below casts from `Int64` to `Int16` and
from `Float64` to `Float32` (the original also prints the memory size before and after,
with `estimated_size`):
"""

tabs """
df.with_columns(
    pl.col("integers").cast(pl.Int16),
    pl.col("floats").cast(pl.Float32),
)
""":
  nbCode:
    let downcast = df.withColumns(
      col("integers").cast(int16),
      col("floats").cast(float32))
    nbShow downcast

nbText: """
When performing downcasting it is crucial to ensure that the chosen number of bits (such as
64, 32, or 16) is sufficient to accommodate the largest and smallest numbers in the column.
For example, a 32-bit signed integer (`Int32`) represents integers between -2147483648 and
2147483647, inclusive, while an 8-bit signed integer only represents integers between -128
and 127, inclusive. Attempting to downcast to a data type with insufficient precision
results in an error thrown by Polars, which arrives in Nanuq as a `NanuqError`:
"""

tabs """
from polars.exceptions import InvalidOperationError

try:
    result = df.select(pl.col("big_integers").cast(pl.Int8))
    print(result)
except InvalidOperationError as err:
    print(err)
""":
  nbCode:
    try:
      echo df.select(col("big_integers").cast(Int8))
    except NanuqError as err:
      echo err.msg

nbText: """
If you set the parameter `strict` to `False` the overflowing/underflowing values are
converted to `null`:
"""

tabs """
df.select(pl.col("big_integers").cast(pl.Int8, strict=False))
""":
  nbCode:
    let overflow = df.select(col("big_integers").cast(Int8, strict = false))
    nbShow overflow

nbText: """
## Converting strings to numeric data types

Strings that represent numbers can be converted to the appropriate data types via casting.
The opposite conversion is also possible:
"""

tabs """
df = pl.DataFrame(
    {
        "integers_as_strings": ["1", "2", "3"],
        "floats_as_strings": ["4.0", "5.8", "-6.3"],
        "floats": [4.0, 5.8, -6.3],
    }
)

df.select(
    pl.col("integers_as_strings").cast(pl.Int32),
    pl.col("floats_as_strings").cast(pl.Float64),
    pl.col("floats").cast(pl.String),
)
""":
  nbCode:
    let strings = newDataFrame(
      series("integers_as_strings", ["1", "2", "3"]),
      series("floats_as_strings", ["4.0", "5.8", "-6.3"]),
      series("floats", [4.0, 5.8, -6.3]))

    let parsed = strings.select(
      col("integers_as_strings").cast(Int32),
      col("floats_as_strings").cast(Float64),
      col("floats").cast(String))
    nbShow parsed

nbText: """
In case the column contains a non-numerical value, or a poorly formatted one, Polars will
throw an error with details on the conversion error. You can set `strict=False` to
circumvent the error and get a `null` value instead.
"""

tabs """
df = pl.DataFrame(
    {
        "floats": ["4.0", "5.8", "- 6 . 3"],
    }
)
try:
    result = df.select(pl.col("floats").cast(pl.Float64))
except InvalidOperationError as err:
    print(err)
""":
  nbCode:
    let badFloats = newDataFrame(series("floats", ["4.0", "5.8", "- 6 . 3"]))
    try:
      echo badFloats.select(col("floats").cast(Float64))
    except NanuqError as err:
      echo err.msg

nbText: """
## Booleans

Booleans can be expressed as either 1 (`True`) or 0 (`False`). It's possible to perform
casting operations between a numerical data type and a Boolean, and vice versa.

When converting numbers to Booleans, the number 0 is converted to `False` and all other
numbers are converted to `True`, in alignment with Python's Truthy and Falsy values for
numbers:
"""

tabs """
df = pl.DataFrame(
    {
        "integers": [-1, 0, 2, 3, 4],
        "floats": [0.0, 1.0, 2.0, 3.0, 4.0],
        "bools": [True, False, True, False, True],
    }
)

df.select(
    pl.col("integers").cast(pl.Boolean),
    pl.col("floats").cast(pl.Boolean),
    pl.col("bools").cast(pl.Int8),
)
""":
  nbCode:
    let mixed = newDataFrame(
      series("integers", [-1, 0, 2, 3, 4]),
      series("floats", [0.0, 1.0, 2.0, 3.0, 4.0]),
      series("bools", [true, false, true, false, true]))

    let booleans = mixed.select(
      col("integers").cast(Boolean),
      col("floats").cast(Boolean),
      col("bools").cast(Int8))
    nbShow booleans

bookSave()
