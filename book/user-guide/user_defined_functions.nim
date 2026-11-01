import nanuqbook
bookInit()

nbText: "# User-defined functions"

attribution userGuide("User-defined Python functions", "expressions/user-defined-python-functions",
  "The functions are Nim procs, which compile to machine code like the guide's Numba " &
  "functions, so the NumPy and Numba examples become plain Nim; those cells show the " &
  "Python code without running it (the book's Python environment has no Numba). Left out: " &
  "the note on plugins and the streaming option `is_elementwise`.")

nbText: """
Polars expressions are quite powerful and flexible, so there is much less need for custom
Python functions compared to other libraries. Still, you may need to pass an expression's
state to a third party library or apply your black box function to data in Polars.

In this part of the documentation we'll be using two APIs that allows you to do this:

- `map_elements`: Call a function separately on each value in the `Series`.
- `map_batches`: Always passes the full `Series` to the function.
"""

nanuq """
In Nanuq they are `mapElements` and `mapBatches`, and the functions are Nim procs or
closures, typed: `proc (x: int): float` for `mapElements`, `proc (s: Series): Series` for
`mapBatches`. Polars calls them from its own threads.
"""

nbText: """
## Processing individual values with `map_elements()`

Let's start with the simplest case: we want to process each value in a `Series`
individually. Here is our data:
"""

tabs """
import math
import warnings

import polars as pl
from polars.exceptions import PolarsInefficientMapWarning

warnings.simplefilter("ignore", PolarsInefficientMapWarning)

df = pl.DataFrame(
    {
        "keys": ["a", "a", "b", "b"],
        "values": [10, 7, 1, 23],
    }
)
df
""":
  nbCode:
    import std/[math, sequtils]
    import nanuq

    let df = newDataFrame:
      keys: ["a", "a", "b", "b"]
      values: [10, 7, 1, 23]
    nbShow df

nbText: """
We'll call `math.log()` on each individual value:
"""

tabs """
def my_log(value):
    return math.log(value)


out = df.select(pl.col("values").map_elements(my_log, return_dtype=pl.Float64))
out
""":
  nbCode:
    proc myLog(value: int): float =
      ln(value.float)

    nbShow df.select(col("values").mapElements(myLog))

nanuq """
No `return_dtype`: the result type of the Nim proc, `float`, says it is `Float64`.
"""

nbText: """
While this works, `map_elements()` has two problems:

1. **Limited to individual items:** Often you'll want to have a calculation that needs to
   operate on the whole `Series`, rather than individual items one by one.
2. **Performance overhead:** Even if you do want to process each item individually, calling
   a function for each individual item is slow; all those extra function calls add a lot of
   overhead.

Let's start by solving the first problem, and then we'll see how to solve the second
problem.
"""

nanuq """
The second problem is smaller in Nim, where the function is compiled, but each call still
crosses from Polars into Nim.
"""

nbText: """
## Processing a whole `Series` with `map_batches()`

We want to run a custom function on the contents of a whole `Series`. For demonstration
purposes, let's say we want to calculate the difference between the mean of a `Series` and
each value.

We can use the `map_batches()` API to run this function on either the full `Series` or
individual groups in a `group_by()`:
"""

tabs """
def diff_from_mean(series):
    # This will be very slow for non-trivial Series, since it's all Python
    # code:
    total = 0
    for value in series:
        total += value
    mean = total / len(series)
    return pl.Series([value - mean for value in series])


# Apply our custom function to a full Series with map_batches():
out = df.select(pl.col("values").map_batches(diff_from_mean, return_dtype=pl.Float64))
out
""":
  nbCode:
    proc diffFromMean(series: Series): Series =
      # Nim compiles this to machine code, so it is fast already:
      let values = series.toList(int)
      var total = 0
      for value in values:
        total += value
      let mean = total / values.len
      series("", values.mapIt(it.float - mean))

    # Apply our custom function to a full Series with mapBatches:
    nbShow df.select(col("values").mapBatches(diffFromMean, Float64))

tabs """
# Apply our custom function per group:
out = df.group_by("keys").agg(
    pl.col("values").map_batches(diff_from_mean, return_dtype=pl.Float64)
)
out
""":
  nbCode:
    # Apply our custom function per group:
    nbShow df.groupBy("keys").agg(
      col("values").mapBatches(diffFromMean, Float64))

nbText: """
## Fast operations with user-defined functions

The problem with a pure-Python implementation is that it's slow. In general, you want to
minimize how much Python code you call if you want fast results.

To maximize speed, you'll want to make sure that you're using a function written in a
compiled language. For numeric calculations Polars supports a pair of interfaces defined by
NumPy called ["ufuncs"](https://numpy.org/doc/stable/reference/ufuncs.html) and
["generalized ufuncs"](https://numpy.org/neps/nep-0005-generalized-ufuncs.html). The former
runs on each item individually, and the latter accepts a whole NumPy array, which allows
for more flexible operations.

[NumPy](https://numpy.org/doc/stable/reference/ufuncs.html) and other libraries like
[SciPy](https://docs.scipy.org/doc/scipy/reference/special.html#module-scipy.special) come
with pre-written ufuncs you can use with Polars. For example:
"""

python """
import numpy as np

out = df.select(pl.col("values").map_batches(np.log, return_dtype=pl.Float64))
out
"""

nanuq """
Nim is the compiled language here: a Nim proc is as fast as the ufunc, and Polars has
`log` itself, `col("values").log`.
"""

nbText: """
Notice that we can use `map_batches()`, because `numpy.log()` is able to run on both
individual items and on whole NumPy arrays. This means it will run much faster than our
original example, since we only have a single Python call and then all processing happens
in a fast low-level language.

## Example: A fast custom function using Numba

The pre-written functions NumPy provides are helpful, but our goal is to write our own
functions. For example, let's say we want a fast version of our `diff_from_mean()` example
above. The easiest way to write this in Python is to use
[Numba](https://numba.readthedocs.io/en/stable/), which allows you to write custom
functions in (a subset) of Python while still getting the benefit of compiled code.
"""

nanuq """
The guide's Numba example compiles `diff_from_mean` with `@guvectorize`. In Nim there is
nothing to add: `diffFromMean` above is compiled already. The Numba cells are left out,
and so is the section on missing data in generalized ufuncs, which is about NumPy arrays.
A Nim proc can read a column with nulls as `Option` values:
`series.toList(Option[int])`.
"""

nbText: """
## Combining multiple column values

If you want to pass multiple columns to a user-defined function, you can use `Struct`s,
which are [covered in detail in a different section](structs.html). The basic idea is to
combine multiple columns into a `Struct`, and then the function can extract the columns
back out:
"""

nanuq """
The guide passes the two fields to a Numba function, `add`; the book's Python has no
Numba, so this cell runs in Nim only, with `+` on the two Series.
"""

nbCode:
  let df3 = newDataFrame:
    values_1: [1, 2, 3]
    values_2: [10, 20, 30]

  nbShow df3.select(
    # Create a struct that has two columns in it:
    asStruct("values_1", "values_2")
    # Pass the struct to a proc that then adds the individual columns:
    .mapBatches(
      proc (combined: Series): Series =
        combined.struct.field("values_1") + combined.struct.field("values_2"),
      Float64,
    )
    .alias("add_columns"))

nbText: """
## Return types

Custom Python functions are often black boxes; Polars doesn't know what your function is
doing or what it will return. The return data type is therefore automatically inferred. We
do that by waiting for the first non-null value. That value will then be used to determine
the type of the resulting `Series`.

The mapping of Python types to Polars data types is as follows:

- `int` -> `Int64`
- `float` -> `Float64`
- `bool` -> `Boolean`
- `str` -> `String`
- `list[tp]` -> `List[tp]` (where the inner type is inferred with the same rules)
- `dict[str, [tp]]` -> `struct`
- `Any` -> `object` (Prevent this at all times)

Rust types map as follows:

- `i32` or `i64` -> `Int64`
- `f32` or `f64` -> `Float64`
- `bool` -> `Boolean`
- `String` or `str` -> `String`
- `Vec<tp>` -> `List[tp]` (where the inner type is inferred with the same rules)

You can pass a `return_dtype` argument to `map_batches` if you want to override the
inferred type.
"""

nanuq """
In Nim nothing is inferred at run time: `mapElements` takes the type from the proc
(`int` is `Int64`, `float` `Float64`, `seq[T]` a `List`, an object or named tuple a
`Struct`), and `mapBatches` keeps the input type unless you pass one, as above with
`Float64`.
"""

bookSave()
