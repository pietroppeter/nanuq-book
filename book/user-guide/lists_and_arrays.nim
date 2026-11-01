import nanuqbook
bookInit()

nbText: "# Lists and arrays"

attribution userGuide("Lists and arrays", "expressions/lists-and-arrays",
  "Nim seqs become `List` columns and Nim arrays `Array` columns, so the `Array` example " &
  "needs no schema. Left out: the NumPy example.")

nbText: """
Polars has first-class support for two homogeneous container data types: `List` and `Array`.
Polars supports many operations with the two data types and their APIs overlap, so this
section of the user guide has the objective of clarifying when one data type should be
chosen in favour of the other.

## Lists vs arrays

### The data type `List`

The data type list is suitable for columns whose values are homogeneous 1D containers of
varying lengths.

The dataframe below contains three examples of columns with the data type `List`:
"""

tabs """
from datetime import datetime
import polars as pl

df = pl.DataFrame(
    {
        "names": [
            ["Anne", "Averill", "Adams"],
            ["Brandon", "Brooke", "Borden", "Branson"],
            ["Camila", "Campbell"],
            ["Dennis", "Doyle"],
        ],
        "children_ages": [
            [5, 7],
            [],
            [],
            [8, 11, 18],
        ],
        "medical_appointments": [
            [],
            [],
            [],
            [datetime(2022, 5, 22, 16, 30)],
        ],
    }
)
df
""":
  nbCode:
    import std/[times, sequtils]
    import nanuq

    let df = newDataFrame:
      names: [@["Anne", "Averill", "Adams"], @["Brandon", "Brooke", "Borden", "Branson"],
              @["Camila", "Campbell"], @["Dennis", "Doyle"]]
      children_ages: [@[5, 7], @[], @[], @[8, 11, 18]]
      medical_appointments: [newSeq[DateTime](), @[], @[],
                             @[dateTime(2022, mMay, 22, 16, 30, zone = utc())]]
    nbShow df

nanuq """
In the block the type of a column comes from its first value, so an empty first list needs
its type: `newSeq[DateTime]()`. The later `@[]` then take it from there.
"""

nbText: """
Note that the data type `List` is different from Python's type `list`, where elements can
be of any type. If you want to store true Python lists in a column, you can do so with the
data type `Object` and your column will not have the list manipulation features that we're
about to discuss.
"""

nanuq """
Nanuq has no `Object` data type: a column always holds Polars values.
"""

nbText: """
### The data type `Array`

The data type `Array` is suitable for columns whose values are homogeneous containers of an
arbitrary dimension with a known and fixed shape.

The dataframe below contains two examples of columns with the data type `Array`.
"""

tabs """
df = pl.DataFrame(
    {
        "bit_flags": [
            [True, True, True, True, False],
            [False, True, True, True, True],
        ],
        "tic_tac_toe": [
            [
                [" ", "x", "o"],
                [" ", "x", " "],
                ["o", "x", " "],
            ],
            [
                ["o", "x", "x"],
                [" ", "o", "x"],
                [" ", " ", "o"],
            ],
        ],
    },
    schema={
        "bit_flags": pl.Array(pl.Boolean, 5),
        "tic_tac_toe": pl.Array(pl.String, (3, 3)),
    },
)
df
""":
  nbCode:
    let arrays = newDataFrame:
      bit_flags: [[true, true, true, true, false], [false, true, true, true, true]]
      tic_tac_toe: [[[" ", "x", "o"], [" ", "x", " "], ["o", "x", " "]],
                    [["o", "x", "x"], [" ", "o", "x"], [" ", " ", "o"]]]
    nbShow arrays

nbText: """
The example above shows how to specify that the columns “bit_flags” and “tic_tac_toe” have
the data type `Array`, parametrised by the data type of the elements contained within and
by the shape of each array.
"""

nanuq """
In Nim the values say it already: `[true, true, ...]` is a Nim `array[5, bool]`, so the
column is an `Array(Boolean, 5)`, and nested arrays give the shape `(3, 3)`. Seqs (`@[...]`)
give lists. A list column can also be cast: `col("a").cast(Array(Boolean, 5))`.
"""

nbText: """
In general, Polars does not infer that a column has the data type `Array` for performance
reasons, and defaults to the appropriate variant of the data type `List`. In Python, an
exception to this rule is when you provide a NumPy array to build a column. In that case,
Polars has the guarantee from NumPy that all subarrays have the same shape, so an array of
$n + 1$ dimensions will generate a column of $n$ dimensional arrays.
"""

nanuq """
Left out: the NumPy example. The Nim twin is the previous one: a Nim array has a fixed
shape too.
"""

nbText: """
### When to use each

In short, prefer the data type `Array` over `List` because it is more memory efficient and
more performant. If you cannot use `Array`, then use `List`:

- when the values within a column do not have a fixed shape; or
- when you need functions that are only available in the list API.

## Working with lists

### The namespace `list`

Polars provides many functions to work with values of the data type `List` and these are
grouped inside the namespace `list`. We will explore this namespace a bit now.

> **`arr` then, `list` now.** In previous versions of Polars, the namespace for list
> operations used to be `arr`. `arr` is now the namespace for the data type `Array`. If you
> find references to the namespace `arr` on StackOverflow or other sources, note that those
> sources _may_ be outdated.

The dataframe `weather` defined below contains data from different weather stations across
a region. When the weather station is unable to get a result, an error code is recorded
instead of the actual temperature at that time.
"""

tabs """
weather = pl.DataFrame(
    {
        "station": [f"Station {idx}" for idx in range(1, 6)],
        "temperatures": [
            "20 5 5 E1 7 13 19 9 6 20",
            "18 8 16 11 23 E2 8 E2 E2 E2 90 70 40",
            "19 24 E9 16 6 12 10 22",
            "E2 E0 15 7 8 10 E1 24 17 13 6",
            "14 8 E0 16 22 24 E1",
        ],
    }
)
weather
""":
  nbCode:
    var weather = newDataFrame:
      station: (1..5).mapIt("Station " & $it)
      temperatures: ["20 5 5 E1 7 13 19 9 6 20",
                     "18 8 16 11 23 E2 8 E2 E2 E2 90 70 40",
                     "19 24 E9 16 6 12 10 22",
                     "E2 E0 15 7 8 10 E1 24 17 13 6",
                     "14 8 E0 16 22 24 E1"]
    nbShow weather

nbText: """
### Programmatically creating lists

Given the dataframe `weather` defined previously, it is very likely we need to run some
analysis on the temperatures that are captured by each station. To make this happen, we
need to first be able to get individual temperature measurements. We
[can use the namespace `str`](strings.html#the-string-namespace) for this:
"""

tabs """
weather = weather.with_columns(
    pl.col("temperatures").str.split(" "),
)
weather
""":
  nbCode:
    weather = weather.withColumns(col.temperatures.str.split(" "))
    nbShow weather

nbText: """
A natural follow-up would be to explode the list of temperatures so that each measurement
is in its own row:
"""

tabs """
result = weather.explode("temperatures")
result
""":
  nbCode:
    nbShow weather.explode("temperatures")

nbText: """
However, in Polars we often do not need to do this to operate on the list elements.

### Operating on lists

Polars provides several standard operations on columns with the `List` data type.
[Similar to what you can do with strings](strings.html#slicing), lists can be sliced with
the functions `head`, `tail`, and `slice`:
"""

tabs """
result = weather.with_columns(
    pl.col("temperatures").list.head(3).alias("head"),
    pl.col("temperatures").list.tail(3).alias("tail"),
    pl.col("temperatures").list.slice(-3, 2).alias("two_next_to_last"),
)
result
""":
  nbCode:
    nbShow weather.withColumns(
      col.temperatures.list.head(3).alias("head"),
      col.temperatures.list.tail(3).alias("tail"),
      col.temperatures.list.slice(-3, 2).alias("two_next_to_last"))

nbText: """
### Element-wise computation within lists

If we need to identify the stations that are giving the most number of errors we need to

1. try to convert the measurements into numbers;
2. count the number of non-numeric values (i.e., `null` values) in the list, by row; and
3. rename this output column as “errors” so that we can easily identify the stations.

To perform these steps, we need to perform a casting operation on each measurement within
the list values. The function `eval` is used as the entry point to perform operations on the
elements of the list. Within it, you can use the context `element` to refer to each single
element of the list individually, and then you can use any Polars expression on the element:
"""

tabs """
result = weather.with_columns(
    pl.col("temperatures")
    .list.eval(pl.element().cast(pl.Int64, strict=False).is_null())
    .list.sum()
    .alias("errors"),
)
result
""":
  nbCode:
    let errors = weather.withColumns(
      col.temperatures
        .list.eval(element().cast(Int64, strict = false).isNull)
        .list.sum
        .alias("errors"))
    nbShow errors

nbText: """
Another alternative would be to use a regular expression to check if a measurement starts
with a letter:
"""

tabs """
result2 = weather.with_columns(
    pl.col("temperatures")
    .list.eval(pl.element().str.contains("(?i)[a-z]"))
    .list.sum()
    .alias("errors"),
)
result.equals(result2)
""":
  nbCode:
    let errors2 = weather.withColumns(
      col.temperatures
        .list.eval(element().str.contains("(?i)[a-z]"))
        .list.sum
        .alias("errors"))
    echo errors.equals(errors2)

nbText: """
If you are unfamiliar with the namespace `str` or the notation `(?i)` in the regex, now is a
good time to
[look at how to work with strings and regular expressions in Polars](strings.html#check-for-the-existence-of-a-pattern).

### Aggregation & sorting

Like `select` on data frames, the two related functions `eval` and `agg` can also be used to
aggregate over or sort the list elements.

We'll reuse a slightly modified version of the example data from the very beginning:
"""

tabs """
df = pl.DataFrame(
    {
        "children": [
            [
                {"name": "Anne", "age": 5},
                {"name": "Averill", "age": 7},
            ],
            [
                {"name": "Brandon", "age": 12},
                {"name": "Brooke", "age": 9},
                {"name": "Branson", "age": 11},
            ],
            [{"name": "Camila", "age": 19}],
            [
                {"name": "Dennis", "age": 8},
                {"name": "Doyle", "age": 11},
                {"name": "Dina", "age": 18},
            ],
        ],
    }
)
df
""":
  nbCode:
    let children = newDataFrame:
      children: [
        @[(name: "Anne", age: 5), (name: "Averill", age: 7)],
        @[(name: "Brandon", age: 12), (name: "Brooke", age: 9), (name: "Branson", age: 11)],
        @[(name: "Camila", age: 19)],
        @[(name: "Dennis", age: 8), (name: "Doyle", age: 11), (name: "Dina", age: 18)]]
    nbShow children

nanuq """
A Python dict is a named tuple in Nim (or an object): its field names become the field
names of the struct.
"""

nbText: """
Using `eval`, we can sort the list elements or compute some aggregations:
"""

tabs """
result = df.select(
    pl.col("children")
    .list.eval(
        pl.element()
        .sort_by(pl.element().struct.field("age"), descending=True)
        .struct.field("name")
    )
    .alias("names_by_age"),
    pl.col("children")
    .list.eval(pl.element().struct.field("age").min())
    .alias("min_age"),
    pl.col("children")
    .list.eval(pl.element().struct.field("age").max())
    .alias("max_age"),
)
result
""":
  nbCode:
    nbShow children.select(
      col.children
        .list.eval(element()
          .sortBy(element().struct.field("age"), descending = true)
          .struct.field("name"))
        .alias("names_by_age"),
      col.children
        .list.eval(element().struct.field("age").min)
        .alias("min_age"),
      col.children
        .list.eval(element().struct.field("age").max)
        .alias("max_age"))

nbText: """
`eval` will always return a list. Use `agg` to get `min_age` and `max_age` as scalar values
instead of single-element lists:
"""

tabs """
result = df.select(
    pl.col("children")
    .list.eval(
        pl.element()
        .sort_by(pl.element().struct.field("age"), descending=True)
        .struct.field("name")
    )
    .alias("names_by_age"),
    pl.col("children")
    .list.agg(pl.element().struct.field("age").min())
    .alias("min_age"),
    pl.col("children")
    .list.agg(pl.element().struct.field("age").max())
    .alias("max_age"),
)
result
""":
  nbCode:
    nbShow children.select(
      col.children
        .list.eval(element()
          .sortBy(element().struct.field("age"), descending = true)
          .struct.field("name"))
        .alias("names_by_age"),
      col.children
        .list.agg(element().struct.field("age").min)
        .alias("min_age"),
      col.children
        .list.agg(element().struct.field("age").max)
        .alias("max_age"))

nbText: """
If the evaluated expression is statically determined to return only one value, `agg` will
automatically explode the resulting list into the inner values. This matches what
`df.group_by(...).agg(...)` does, hence the name. This is in contrast with `eval`, which
will not perform such unwrapping.

While some aggregation functions like `.list.sum()` are directly available in the `list`
namespace, you can access more exotic aggregations like `entropy` via `agg`/`eval` only:
"""

tabs """
result = df.with_columns(
    pl.col("children")
    .list.agg(pl.element().struct.field("age").entropy())
    .alias("age_entropy"),
)
result
""":
  nbCode:
    nbShow children.withColumns(
      col.children
        .list.agg(element().struct.field("age").entropy)
        .alias("age_entropy"))

nbText: """
### Row-wise computations

`pl.all()` can be combined with `pl.concat_list(...)` to perform row-wise aggregations over
a subset of columns.

To show this in action, we will start by creating another dataframe with some more weather
data:
"""

tabs """
weather_by_day = pl.DataFrame(
    {
        "station": [f"Station {idx}" for idx in range(1, 11)],
        "day_1": [17, 11, 8, 22, 9, 21, 20, 8, 8, 17],
        "day_2": [15, 11, 10, 8, 7, 14, 18, 21, 15, 13],
        "day_3": [16, 15, 24, 24, 8, 23, 19, 23, 16, 10],
    }
)
weather_by_day
""":
  nbCode:
    let weatherByDay = newDataFrame:
      station: (1..10).mapIt("Station " & $it)
      day_1: [17, 11, 8, 22, 9, 21, 20, 8, 8, 17]
      day_2: [15, 11, 10, 8, 7, 14, 18, 21, 15, 13]
      day_3: [16, 15, 24, 24, 8, 23, 19, 23, 16, 10]
    nbShow weatherByDay

nbText: """
Now, we will calculate the percentage rank of the temperatures by day, measured across
stations. Polars does not provide a function to do this directly, but because expressions
are so versatile we can create our own percentage rank expression for highest temperature.
Let's try that:
"""

tabs """
rank_pct = (pl.element().rank(descending=True) / pl.element().count()).round(2)

result = weather_by_day.with_columns(
    # create the list of homogeneous data
    pl.concat_list(pl.all().exclude("station")).alias("all_temps")
).select(
    # select all columns except the intermediate list
    pl.all().exclude("all_temps"),
    # compute the rank by calling `list.eval`
    pl.col("all_temps").list.eval(rank_pct, parallel=True).alias("temps_rank"),
)
result
""":
  nbCode:
    let rankPct = (element().rank(descending = true) / element().count).round(2)

    nbShow weatherByDay.withColumns(
      # create the list of homogeneous data
      concatList(all().exclude("station")).alias("all_temps")
    ).select(
      # select all columns except the intermediate list
      all().exclude("all_temps"),
      # compute the rank by calling `list.eval`
      col.all_temps.list.eval(rankPct).alias("temps_rank"))

nanuq """
Nanuq's `list.eval` has no `parallel` option: Polars' Rust API runs it the same way
without it.
"""

nbText: """
## Working with arrays

### Creating an array column

As [we have seen above](#the-data-type-array), Polars usually does not infer the data type
`Array` automatically. You have to specify the data type `Array` when creating a
series/dataframe or [cast a column](casting.html) explicitly unless you create the column
out of a NumPy array.

### The namespace `arr`

The data type `Array` was recently introduced and is still pretty nascent in features that
it offers. Even so, the namespace `arr` aggregates several functions that you can use to
work with arrays.

The API documentation should give you a good overview of the functions in the namespace
`arr`, of which we present a couple:
"""

tabs """
df = pl.DataFrame(
    {
        "first_last": [
            ["Anne", "Adams"],
            ["Brandon", "Branson"],
            ["Camila", "Campbell"],
            ["Dennis", "Doyle"],
        ],
        "fav_numbers": [
            [42, 0, 1],
            [2, 3, 5],
            [13, 21, 34],
            [73, 3, 7],
        ],
    },
    schema={
        "first_last": pl.Array(pl.String, 2),
        "fav_numbers": pl.Array(pl.Int32, 3),
    },
)

result = df.select(
    pl.col("first_last").arr.join(" ").alias("name"),
    pl.col("fav_numbers").arr.sort(),
    pl.col("fav_numbers").arr.max().alias("largest_fav"),
    pl.col("fav_numbers").arr.sum().alias("summed"),
    pl.col("fav_numbers").arr.contains(3).alias("likes_3"),
)
result
""":
  nbCode:
    let favs = newDataFrame:
      first_last: [["Anne", "Adams"], ["Brandon", "Branson"], ["Camila", "Campbell"],
                   ["Dennis", "Doyle"]]
      fav_numbers: [[42'i32, 0, 1], [2'i32, 3, 5], [13'i32, 21, 34], [73'i32, 3, 7]]

    nbShow favs.select(
      col.first_last.arr.join(" ").alias("name"),
      col.fav_numbers.arr.sort,
      col.fav_numbers.arr.max.alias("largest_fav"),
      col.fav_numbers.arr.sum.alias("summed"),
      col.fav_numbers.arr.contains(3).alias("likes_3"))

nanuq """
Nim integers are `Int64`; `42'i32` makes the arrays `array[3, int32]`, the guide's
`Array(Int32, 3)`.
"""

bookSave()
