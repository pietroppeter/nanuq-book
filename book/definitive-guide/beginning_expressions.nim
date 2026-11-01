import nanuqbook
bookInit()

nbText: "# Beginning expressions"

attribution definitiveGuide(7, "Beginning Expressions",
  "Data is read from `data/definitive-guide/`. Left out: the group-by on the last word of " &
  "`origin` (it needs `str.split` and lists), `meta.has_multiple_outputs`, top-level " &
  "`pl.select`, list literals, `repeat`/`zeros`/`ones`, the range functions, the `name` " &
  "methods other than `suffix`/`prefix`, and Series arithmetic (`fruit[\"weight\"] > 1000`).")

nbText: """
Expressions are the heart of Polars, and of Nanuq: almost everything you do to a
DataFrame is an expression handed to a method such as `select`, `withColumns`, `filter`,
`groupBy` or `sort`. This chapter follows the examples of the book's chapter on
expressions, on a small table of fruit.

## Expressions by example
"""

tabs """
import polars as pl

fruit = pl.read_csv("data/definitive-guide/fruit.csv")
fruit
""":
  nbCode:
    import nanuq

    let fruit = readCsv("data/definitive-guide/fruit.csv")
    nbShow fruit

nbText: """
### Selecting columns with expressions

One `select` can mix a plain column, a regular expression that matches several columns
(here `color` and `origin`), and a computed column.
"""

tabs """
fruit.select(
    pl.col("name"),
    pl.col("^.*or.*$"),
    pl.col("weight") / 1000,
    "is_round",
)
""":
  nbCode:
    nbShow fruit.select(
      col.name,
      col("^.*or.*$"),
      col.weight / 1000,
      col.is_round)

nanuq """
`col.name` is the 0.3 shorthand for `col("name")`, like Python's `pl.col.name`. Python also
accepts a bare string (`"is_round"`) where it expects an expression; Nim's `select` takes
expressions only. And `/` is true division, so the integer weights become floats, as in
Python.
"""

nbText: """
### Creating new columns with expressions

`withColumns` adds columns, or replaces them when the name already exists. A literal
becomes a column of the same value on every row.
"""

tabs """
fruit.with_columns(
    pl.lit(True).alias("is_fruit"),
    is_berry=pl.col("name").str.ends_with("berry"),
)
""":
  nbCode:
    nbShow fruit.withColumns(
      lit(true).alias("is_fruit"),
      col.name.str.endsWith("berry").alias("is_berry"))

nanuq """
Python's keyword arguments (`is_berry=...`) name a column; in Nim the name always comes
from `alias`.
"""

nbText: """
### Filtering rows with expressions

A predicate is an expression that gives a boolean per row. Predicates combine with `and`
and `or` (`&` and `|` in Python, whose `and` keyword can't be overloaded).
"""

tabs """
fruit.filter(
    (pl.col("weight") > 1000)
    & pl.col("is_round")
)
""":
  nbCode:
    nbShow fruit.filter(col.weight > 1000 and col.is_round)

nanuq """
The book next groups the fruit by the last word of their origin
(`pl.col("origin").str.split(" ").list.last()`). Nanuq has no lists yet, so that example is
left out.
"""

nbText: """
### Sorting rows with expressions

`sort` takes expressions too, not only column names: here the fruit sorted by the length
of their name, longest first.
"""

tabs """
fruit.sort(
    pl.col("name").str.len_bytes(),
    descending=True,
)
""":
  nbCode:
    nbShow fruit.sort([col.name.str.lenBytes], descending = [true])

nbText: """
## The definition of an expression

An expression is a recipe that turns one or more Series into a Series. It can stand for
several columns at once: `all()` below expands to every column of the frame, and
`name.suffix` gives each result a new name.
"""

tabs """
(
    pl.DataFrame({"a": [1, 2, 3], "b": [0.4, 0.5, 0.6]}).with_columns(
        pl.all().mul(10).name.suffix("_times_10")
    )
)
""":
  nbCode:
    let ab = newDataFrame:
      a: [1, 2, 3]
      b: [0.4, 0.5, 0.6]
    nbShow ab.withColumns((all() * 10).name.suffix("_times_10"))

nanuq """
Python's operators have method twins (`mul` for `*`); Nim just uses the operators. The
frame is built with the block syntax of `newDataFrame`, new in Nanuq 0.3.
"""

nbText: """
### Properties of expressions

An expression is a value: you can store it in a variable and use it in different
contexts, on different frames, as long as they have the columns it refers to.
"""

tabs """
is_orange = (pl.col("color") == "orange").alias("is_orange")

fruit.with_columns(is_orange)
""":
  nbCode:
    let isOrange = (col.color == "orange").alias("is_orange")
    nbShow fruit.withColumns(isOrange)

tabs """
fruit.filter(is_orange)
""":
  nbCode:
    nbShow fruit.filter(isOrange)

tabs """
fruit.group_by(is_orange).len()
""":
  nbCode:
    nbShow fruit.groupBy(isOrange).agg(col.name.len.alias("len"))

nanuq """
Nanuq's group-by has no `len()` shortcut yet: it counts rows with `len` on any column.
"""

tabs """
flowers = pl.DataFrame(
    {
        "name": ["Tiger lily", "Blue flag", "African marigold"],
        "latin": ["Lilium columbianum", "Iris versicolor", "Tagetes erecta"],
        "color": ["orange", "purple", "orange"],
    }
)

flowers.filter(is_orange)
""":
  nbCode:
    let flowers = newDataFrame:
      name: ["Tiger lily", "Blue flag", "African marigold"]
      latin: ["Lilium columbianum", "Iris versicolor", "Tagetes erecta"]
      color: ["orange", "purple", "orange"]
    nbShow flowers.filter(isOrange)

nbText: """
## Creating expressions

### From existing columns

`col` takes a name, several names, a regular expression or data types.
"""

tabs """
fruit.select(pl.col("color")).columns
""":
  nbCode:
    echo fruit.select(col.color).columns

nbText: """
A name that is not in the frame is an error, raised when the query runs:
"""

tabs """
try:
    fruit.select(pl.col("is_smelly"))
except pl.exceptions.ColumnNotFoundError as e:
    print(type(e).__name__)
""":
  nbCode:
    try:
      discard fruit.select(col.is_smelly)
    except ColumnNotFoundError:
      echo "ColumnNotFoundError"

nanuq """
Since 0.3 Nanuq raises the same error types as Python Polars, all subtypes of
`PolarsError`. The book shows the error by leaving the cell commented out; here both sides
catch it.
"""

tabs """
fruit.select(pl.col("^.*or.*$")).columns
""":
  nbCode:
    echo fruit.select(col("^.*or.*$")).columns

tabs """
fruit.select(pl.all()).columns
""":
  nbCode:
    echo fruit.select(all()).columns

tabs """
fruit.select(pl.col(pl.String)).columns
""":
  nbCode:
    echo fruit.select(col(string)).columns

tabs """
fruit.select(pl.col(pl.Boolean, pl.Int64)).columns
""":
  nbCode:
    echo fruit.select(col(bool, int)).columns

tabs """
fruit.select(pl.col(["name", "color"])).columns
""":
  nbCode:
    echo fruit.select(col("name", "color")).columns

nanuq """
Data types are Nim types in `col`: `string` for `pl.String`, `bool` for `pl.Boolean`, `int`
for `pl.Int64`.
"""

nbText: """
### From literal values

A literal is broadcast to the height of the frame.
"""

tabs """
fruit.with_columns(planet=pl.lit("Earth"))
""":
  nbCode:
    nbShow fruit.withColumns(lit("Earth").alias("planet"))

nanuq """
Left out from this section: `pl.select` without a frame, list literals, `repeat`, `zeros`
and `ones`, and in the next sections the range functions (`int_range`, `date_range`,
`datetime_ranges`) and the `name` methods `to_uppercase`, `to_lowercase` and `map`. Nanuq
does not have them yet.
"""

nbText: """
## Renaming expressions

`alias` names the result of an expression.
"""

tabs """
df = pl.DataFrame({"text": "value", "An integer": 5040, "BOOLEAN": True})
df.select(pl.col("An integer").alias("int"))
""":
  nbCode:
    let df = newDataFrame:
      text: ["value"]
      "An integer": [5040]
      BOOLEAN: [true]
    nbShow df.select(col("An integer").alias("int"))

nbText: """
## Expressions are idiomatic

The book closes the chapter by contrasting expressions with Series computed up front:
expressions refer to columns by name, so they also work in a lazy query, where the data is
not there yet.
"""

tabs """
(
    fruit.lazy()
    .filter((pl.col("weight") > 1000) & pl.col("is_round"))
    .with_columns(is_berry=pl.col("name").str.ends_with("berry"))
    .collect()
)
""":
  nbCode:
    nbShow fruit.lazy
      .filter(col.weight > 1000 and col.is_round)
      .withColumns(col.name.str.endsWith("berry").alias("is_berry"))
      .collect

bookSave()
