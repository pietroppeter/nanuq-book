import nanuqbook
bookInit()

nbText: "# Structs"

attribution userGuide("Structs", "expressions/structs",
  "`pl.struct` is `asStruct` in Nanuq, and Nim named tuples (or objects) play the part of " &
  "Python dictionaries. Left out: the series built from dictionaries that do not agree.")

nbText: """
The data type `Struct` is a composite data type that can store multiple fields in a single
column.

> **Python analogy.** For Python users, the data type `Struct` is kind of like a Python
> dictionary. Even better, if you are familiar with Python typing, you can think of the data
> type `Struct` as `typing.TypedDict`.
"""

nanuq """
For Nim users the analogy is even closer: a `Struct` is a named tuple, or an object, with
the same fields in every row.
"""

nbText: """
In this page of the user guide we will see situations in which the data type `Struct`
arises, we will understand why it does arise, and we will see how to work with `Struct`
values.

Let's start with a dataframe that captures the average rating of a few movies across some
states in the US:
"""

tabs """
import polars as pl

ratings = pl.DataFrame(
    {
        "Movie": ["Cars", "IT", "ET", "Cars", "Up", "IT", "Cars", "ET", "Up", "Cars"],
        "Theatre": ["NE", "ME", "IL", "ND", "NE", "SD", "NE", "IL", "IL", "NE"],
        "Avg_Rating": [4.5, 4.4, 4.6, 4.3, 4.8, 4.7, 4.5, 4.9, 4.7, 4.6],
        "Count": [30, 27, 26, 29, 31, 28, 28, 26, 33, 28],
    }
)
ratings
""":
  nbCode:
    import nanuq

    let ratings = newDataFrame:
      Movie: ["Cars", "IT", "ET", "Cars", "Up", "IT", "Cars", "ET", "Up", "Cars"]
      Theatre: ["NE", "ME", "IL", "ND", "NE", "SD", "NE", "IL", "IL", "NE"]
      Avg_Rating: [4.5, 4.4, 4.6, 4.3, 4.8, 4.7, 4.5, 4.9, 4.7, 4.6]
      Count: [30, 27, 26, 29, 31, 28, 28, 26, 33, 28]
    nbShow ratings

nbText: """
## Encountering the data type `Struct`

A common operation that will lead to a `Struct` column is the ever so popular
`value_counts` function that is commonly used in exploratory data analysis. Checking the
number of times a state appears in the data is done as so:
"""

tabs """
result = ratings.select(pl.col("Theatre").value_counts(sort=True))
result
""":
  nbCode:
    nbShow ratings.select(col.Theatre.valueCounts(sort = true))

nbText: """
Quite unexpected an output, especially if coming from tools that do not have such a data
type. We're not in peril, though. To get back to a more familiar output, all we need to do
is use the function `unnest` on the `Struct` column:
"""

tabs """
result = ratings.select(pl.col("Theatre").value_counts(sort=True)).unnest("Theatre")
result
""":
  nbCode:
    nbShow ratings.select(col.Theatre.valueCounts(sort = true)).unnest("Theatre")

nbText: """
The function `unnest` will turn each field of the `Struct` into its own column.

> **Why `value_counts` returns a `Struct`.** Polars expressions always operate on a single
> series and return another series. `Struct` is the data type that allows us to provide
> multiple columns as input to an expression, or to output multiple columns from an
> expression. Thus, we can use the data type `Struct` to specify each value and its count
> when we use `value_counts`.

## Inferring the data type `Struct` from dictionaries

When building series or dataframes, Polars will convert dictionaries to the data type
`Struct`:
"""

tabs """
rating_series = pl.Series(
    "ratings",
    [
        {"Movie": "Cars", "Theatre": "NE", "Avg_Rating": 4.5},
        {"Movie": "Toy Story", "Theatre": "ME", "Avg_Rating": 4.9},
    ],
)
rating_series
""":
  nbCode:
    let ratingSeries = series("ratings", [
      (Movie: "Cars", Theatre: "NE", Avg_Rating: 4.5),
      (Movie: "Toy Story", Theatre: "ME", Avg_Rating: 4.9)])
    nbShow ratingSeries

nanuq """
Nanuq builds a `Struct` from named tuples and objects: the field names, types and order
come from the Nim type.
"""

nbText: """
The field count, names, types, and order are inferred from the first dictionary seen. This
field order is retained by the resulting `Struct`. Subsequent incongruences can result in
`null` values or in errors.
"""

nanuq """
Left out: the example with dictionaries that do not agree. In Nim all the values of a seq
have the same type, so they cannot disagree; a missing value is an `Option` field set to
`none`, which becomes a `null`.
"""

nbText: """
## Extracting individual values of a `Struct`

Let's say that we needed to obtain just the field `"Movie"` from the `Struct` in the series
that we created above. We can use the function `field` to do so:
"""

tabs """
result = rating_series.struct.field("Movie")
result
""":
  nbCode:
    nbShow ratingSeries.struct.field("Movie")

nbText: """
## Renaming individual fields of a `Struct`

What if we need to rename individual fields of a `Struct` column? We use the function
`rename_fields`:
"""

tabs """
result = rating_series.struct.rename_fields(["Film", "State", "Value"])
result
""":
  nbCode:
    let renamed = ratingSeries.struct.renameFields(["Film", "State", "Value"])
    nbShow renamed

nbText: """
To be able to actually see that the field names were changed, we will create a dataframe
where the only column is the result and then we use the function `unnest` so that each
field becomes its own column. The column names will reflect the renaming operation we just
did:
"""

tabs """
result.to_frame().unnest("ratings")
""":
  nbCode:
    nbShow renamed.toFrame.unnest("ratings")

nbText: """
## Practical use-cases of `Struct` columns

### Identifying duplicate rows

Let's get back to the `ratings` data. We want to identify cases where there are duplicates
at a “Movie” and “Theatre” level.

This is where the data type `Struct` shines:
"""

tabs """
result = ratings.filter(pl.struct("Movie", "Theatre").is_duplicated())
result
""":
  nbCode:
    nbShow ratings.filter(asStruct("Movie", "Theatre").isDuplicated)

nanuq """
`pl.struct` is `asStruct` (the name of the Rust function): `struct` is taken by the
namespace, `col("a").struct.field("b")`.
"""

nbText: """
We can identify the unique cases at this level also with `is_unique`!

### Multi-column ranking

Suppose, given that we know there are duplicates, we want to choose which rating gets a
higher priority. We can say that the column “Count” is the most important, and if there is
a tie in the column “Count” then we consider the column “Avg_Rating”.

We can then do:
"""

tabs """
result = ratings.with_columns(
    pl.struct("Count", "Avg_Rating")
    .rank("dense", descending=True)
    .over("Movie", "Theatre")
    .alias("Rank")
).filter(pl.struct("Movie", "Theatre").is_duplicated())
result
""":
  nbCode:
    nbShow ratings.withColumns(
      asStruct("Count", "Avg_Rating")
        .rank(Dense, descending = true)
        .over(["Movie", "Theatre"])
        .alias("Rank")
    ).filter(asStruct("Movie", "Theatre").isDuplicated)

nbText: """
That's a pretty complex set of requirements done very elegantly in Polars! To learn more
about the function `over`, used above,
[see the user guide section on window functions](window_functions.html).

### Using multiple columns in a single expression

As mentioned earlier, the data type `Struct` is also useful if you need to pass multiple
columns as input to an expression. As an example, suppose we want to compute
[the Ackermann function](https://en.wikipedia.org/wiki/Ackermann_function) on two columns
of a dataframe. There is no way of composing Polars expressions to compute the Ackermann
function[^1], so we define a custom function:
"""

tabs """
def ack(m, n):
    if not m:
        return n + 1
    if not n:
        return ack(m - 1, 1)
    return ack(m - 1, ack(m, n - 1))
""":
  nbCode:
    proc ack(m, n: int): int =
      if m == 0:
        return n + 1
      if n == 0:
        return ack(m - 1, 1)
      ack(m - 1, ack(m, n - 1))

nbText: """
Now, to compute the values of the Ackermann function on those arguments, we start by
creating a `Struct` with fields `m` and `n` and then use the function `map_elements` to
apply the function `ack` to each value:
"""

tabs """
values = pl.DataFrame(
    {
        "m": [0, 0, 0, 1, 1, 1, 2],
        "n": [2, 3, 4, 1, 2, 3, 1],
    }
)
result = values.with_columns(
    pl.struct(["m", "n"])
    .map_elements(lambda s: ack(s["m"], s["n"]), return_dtype=pl.Int64)
    .alias("ack")
)
result
""":
  nbCode:
    let values = newDataFrame:
      m: [0, 0, 0, 1, 1, 1, 2]
      n: [2, 3, 4, 1, 2, 3, 1]

    nbShow values.withColumns(
      asStruct("m", "n")
        .mapElements(proc (s: tuple[m, n: int]): int = ack(s.m, s.n))
        .alias("ack"))

nanuq """
The Nim function gets each struct as a typed value, here a named tuple whose fields match
the struct's fields by name (an object works too), and its result type, `int`, gives the
column's `Int64`.
"""

nbText: """
Refer to
[this section of the user guide to learn more about applying user-defined Python functions to your data](user_defined_functions.html).

[^1]: To say that something cannot be done is quite a bold claim. If you prove us wrong,
please let us know!
"""

bookSave()
