import nanuqbook
bookInit()

nbText: "# Combining expressions"

attribution definitiveGuide(9, "Combining Expressions",
  "Data is read from `data/definitive-guide/`. Left out: " &
  "`tbl_cell_numeric_alignment` (the HTML tables don't use it).")

nbText: """
Expressions get interesting when they are combined: with arithmetic, comparisons, Boolean
logic, bitwise operators, and with functions that take several expressions at once. This
chapter goes through each kind, again on the table of fruit.
"""

tabs """
import polars as pl

fruit = pl.read_csv("data/definitive-guide/fruit.csv")
fruit.filter(pl.col("is_round") & (pl.col("weight") > 1000))
""":
  nbCode:
    import nanuq

    let fruit = readCsv("data/definitive-guide/fruit.csv")
    nbShow fruit.filter(col.is_round and col.weight > 1000)

nanuq """
Python overloads `&`, `|`, `~` and `^` for expressions because its `and`, `or` and `not`
can't be overloaded. Nim's can, so Nanuq uses the words: `and`, `or`, `not`, `xor`. They
bind more loosely than comparisons, so no parentheses are needed around `col.weight > 1000`.
"""

nbText: """
## Inline operators versus methods

Each operator is also a method: `*` is `mul`. In Nim an operator already is a proc, so
`col.i * col.j` is the call `` `*`(col.i, col.j) ``; Nanuq has the method names too, for
code ported from Python.
"""

tabs """
pl.DataFrame({"i": [6.0, 0, 2, 2.5], "j": [7.0, 1, 2, 3]}).with_columns(
    (pl.col("i") * pl.col("j")).alias("*"),
    pl.col("i").mul(pl.col("j")).alias("Expr.mul()"),
)
""":
  nbCode:
    let ij = newDataFrame:
      i: [6.0, 0, 2, 2.5]
      j: [7.0, 1, 2, 3]
    nbShow ij.withColumns(
      (col.i * col.j).alias("*"),
      col.i.mul(col.j).alias("Expr.mul()"))

nbText: """
## Arithmetic operations

Dividing the weight in grams by 1000 gives kilograms:
"""

tabs """
fruit.select(pl.col("name"), (pl.col("weight") / 1000))
""":
  nbCode:
    nbShow fruit.select(col.name, col.weight / 1000)

nbText: """
All the arithmetic operators side by side, with two decimals in the output. Python's floor
division `//` is Nim's `div`, its power `**` is `^`, and its modulo `%` is `mod`.
"""

tabs """
pl.Config(float_precision=2)

(
    pl.DataFrame({"i": [0.0, 2, 2, -2, -2], "j": [1, 2, 3, 4, -5]}).with_columns(
        (pl.col("i") + pl.col("j")).alias("i + j"),
        (pl.col("i") - pl.col("j")).alias("i - j"),
        (pl.col("i") * pl.col("j")).alias("i * j"),
        (pl.col("i") / pl.col("j")).alias("i / j"),
        (pl.col("i") // pl.col("j")).alias("i // j"),
        (pl.col("i") ** pl.col("j")).alias("i ** j"),
        (pl.col("j") % 2).alias("j % 2"),
        pl.col("i").dot(pl.col("j")).alias("i ⋅ j"),
    )
)
""":
  nbCode:
    setFloatPrecision(2)

    let arith = newDataFrame:
      i: [0.0, 2, 2, -2, -2]
      j: [1, 2, 3, 4, -5]
    nbShow arith.withColumns(
      (col.i + col.j).alias("i + j"),
      (col.i - col.j).alias("i - j"),
      (col.i * col.j).alias("i * j"),
      (col.i / col.j).alias("i / j"),
      (col.i div col.j).alias("i // j"),
      (col.i ^ col.j).alias("i ** j"),
      (col.j mod 2).alias("j % 2"),
      col.i.dot(col.j).alias("i ⋅ j"))

python """
pl.Config.set_float_precision()
"""
setFloatPrecision(none(int))

nbText: """
## Comparison operations

Strings compare alphabetically. `select` without a frame evaluates expressions that need
no input columns:
"""

tabs """
pl.select(pl.lit("a") > pl.lit("b"))
""":
  nbCode:
    nbShow select(lit("a") > lit("b"))

tabs """
fruit.select(
    pl.col("name"),
    pl.col("weight"),
).filter(pl.col("weight") >= 1000)
""":
  nbCode:
    nbShow fruit.select(col.name, col.weight).filter(col.weight >= 1000)

nbText: """
Python chains comparisons (`3 < x < 5`), but not on expressions: those need two
comparisons joined with *and*, or `isBetween`. Nim has no chained comparisons at all, so
the expression version reads like the plain one.
"""

tabs """
x = 4
pl.select((pl.lit(3) < pl.lit(x)) & (pl.lit(x) < pl.lit(5))).item()
""":
  nbCode:
    let x = 4
    echo select(lit(3) < lit(x) and lit(x) < lit(5)).toSeries.item(bool)

tabs """
pl.select(pl.lit(x).is_between(3, 5)).item()
""":
  nbCode:
    echo select(lit(x).isBetween(3, 5)).toSeries.item(bool)

nbText: """
Every comparison operator, and two ways of saying "close enough" or "in a range":
"""

tabs """
pl.DataFrame(
    {"a": [-273.15, 0, 42, 100], "b": [1.4142, 2.7183, 42, 3.1415]}
).with_columns(
    (pl.col("a") == pl.col("b")).alias("a == b"),
    (pl.col("a") <= pl.col("b")).alias("a <= b"),
    (pl.all() > 0).name.suffix(" > 0"),
    ((pl.col("b") - pl.lit(2).sqrt()).abs() < 1e-3).alias("b ≈ √2"),
    ((1 < pl.col("b")) & (pl.col("b") < 3)).alias("1 < b < 3"),
)
""":
  nbCode:
    let ab = newDataFrame:
      a: [-273.15, 0, 42, 100]
      b: [1.4142, 2.7183, 42, 3.1415]
    nbShow ab.withColumns(
      (col.a == col.b).alias("a == b"),
      (col.a <= col.b).alias("a <= b"),
      (all() > 0).name.suffix(" > 0"),
      ((col.b - lit(2).sqrt).abs < 1e-3).alias("b ≈ √2"),
      (1 < col.b and col.b < 3).alias("1 < b < 3"))

nbText: """
Values of different types can be compared when Polars knows how to line them up: Booleans
with numbers, a time with a time, a datetime with a date. A string and a number cannot,
so the number is cast to a string first (and then `"5" < "3"` is false).
"""

tabs """
from datetime import date, datetime, time

pl.select(
    bool_num=pl.lit(True) > 0,
    time_time=pl.lit(time(23, 58)) > pl.lit(time(0, 0)),
    datetime_date=pl.lit(datetime(1969, 7, 21, 2, 56)) < pl.lit(date(1976, 7, 20)),
    str_num=pl.lit("5") < pl.lit(3).cast(pl.String),
    datetime_time=pl.lit(datetime(1999, 1, 1)).dt.time() != pl.lit(time(0, 0)),
).transpose(include_header=True, header_name="comparison", column_names=["allowed"])
""":
  nbCode:
    import std/times

    nbShow select(
      (lit(true) > 0).alias("bool_num"),
      (lit(timeOfDay(23, 58)) > lit(timeOfDay(0, 0))).alias("time_time"),
      (lit(dateTime(1969, mJul, 21, 2, 56, zone = utc())) <
        lit(date(1976, 7, 20))).alias("datetime_date"),
      (lit("5") < lit(3).cast(String)).alias("str_num"),
      (lit(dateTime(1999, mJan, 1, zone = utc())).dt.time != lit(timeOfDay(0, 0))).alias("datetime_time"),
    ).transpose(includeHeader = true, headerName = "comparison", columnNames = ["allowed"])

nanuq """
The book writes `pl.time(23, 58)`, `pl.datetime(…)` and `pl.date(…)`, expression
constructors; the Python tab here uses literals of Python's own `datetime` values, which
give the same frame. In Nim the values are `timeOfDay`, `dateTime` (from `std/times`) and
`date`, passed to `lit`.
"""

nbText: """
## Boolean algebra operations

With `x = 7`, *p* (3 < x) is true and *q* (x < 5) is false, so *p and q* is false:
"""

tabs """
x = 7
p = pl.lit(3) < pl.lit(x)
q = pl.lit(x) < pl.lit(5)
pl.select(p & q).item()
""":
  nbCode:
    block:
      let x = 7
      let p = lit(3) < lit(x)
      let q = lit(x) < lit(5)
      echo select(p and q).toSeries.item(bool)

nbText: """
The whole truth table, including *nand* (↑) and *nor* (↓), which are the negations of
*and* and *or*:
"""

tabs """
pl.DataFrame(
    {"p": [True, True, False, False], "q": [True, False, True, False]}
).with_columns(
    (pl.col("p") & pl.col("q")).alias("p & q"),
    (pl.col("p") | pl.col("q")).alias("p | q"),
    (~pl.col("p")).alias("~p"),
    (pl.col("p") ^ pl.col("q")).alias("p ^ q"),
    (~(pl.col("p") & pl.col("q"))).alias("p ↑ q"),
    ((pl.col("p").or_(pl.col("q"))).not_()).alias("p ↓ q"),
)
""":
  nbCode:
    let pq = newDataFrame:
      p: [true, true, false, false]
      q: [true, false, true, false]
    nbShow pq.withColumns(
      (col.p and col.q).alias("p & q"),
      (col.p or col.q).alias("p | q"),
      (not col.p).alias("~p"),
      (col.p xor col.q).alias("p ^ q"),
      (not (col.p and col.q)).alias("p ↑ q"),
      (not (col.p or col.q)).alias("p ↓ q"))

nbText: """
## Bitwise operations

On integers the same operators work bit by bit: 10 is `00001010` and 34 is `00100010`,
so 10 *or* 34 is `00101010`, which is 42.
"""

tabs """
pl.select(pl.lit(10) | pl.lit(34)).item()
""":
  nbCode:
    echo select(lit(10) or lit(34)).toSeries.item(int)

tabs """
bits = pl.DataFrame(
    {"x": [1, 1, 0, 0, 7, 10], "y": [1, 0, 1, 0, 2, 34]},
    schema={"x": pl.UInt8, "y": pl.UInt8},
).with_columns(
    (pl.col("x") & pl.col("y")).alias("x & y"),
    (pl.col("x") | pl.col("y")).alias("x | y"),
    (~pl.col("x")).alias("~x"),
    (pl.col("x") ^ pl.col("y")).alias("x ^ y"),
)
bits
""":
  nbCode:
    let bits = newDataFrame(
      series("x", [1'u8, 1, 0, 0, 7, 10]),
      series("y", [1'u8, 0, 1, 0, 2, 34]),
    ).withColumns(
      (col.x and col.y).alias("x & y"),
      (col.x or col.y).alias("x | y"),
      (not col.x).alias("~x"),
      (col.x xor col.y).alias("x ^ y"))
    nbShow bits

nbText: """
To see the bits, each value goes through a formatting function. In Python that is
`"{0:08b}".format`; in Nim it is a proc from `std/strutils`, called by `mapElements`:
"""

tabs """
bits.select(pl.all().map_elements("{0:08b}".format, return_dtype=pl.String))
""":
  nbCode:
    import std/strutils

    nbShow bits.select(all().mapElements(proc (v: uint8): string = v.int.toBin(8)))

nbText: """
## Using functions

Some functions take several expressions and combine them into one: into a list, a struct,
a string, or a row-wise aggregate.
"""

tabs """
scientists = pl.DataFrame(
    {
        "first_name": ["George", "Grace", "John", "Kurt", "Ada"],
        "last_name": ["Boole", "Hopper", "Tukey", "Gödel", "Lovelace"],
        "country": [
            "England",
            "United States",
            "United States",
            "Austria-Hungary",
            "England",
        ],
    }
)
scientists
""":
  nbCode:
    let scientists = newDataFrame:
      first_name: ["George", "Grace", "John", "Kurt", "Ada"]
      last_name: ["Boole", "Hopper", "Tukey", "Gödel", "Lovelace"]
      country: ["England", "United States", "United States", "Austria-Hungary", "England"]
    nbShow scientists

tabs """
scientists.select(
    concat_list=pl.concat_list(pl.col("^*_name$")),
    struct=pl.struct(pl.all()),
)
""":
  nbCode:
    nbShow scientists.select(
      concatList(col("^*_name$")).alias("concat_list"),
      asStruct(all()).alias("struct"))

nanuq """
Python's keyword arguments (`concat_list=…`) name the new columns; in Nim that is
`.alias`. The struct constructor is `asStruct`, because `struct` is the namespace
(`.struct.field(…)`).
"""

tabs """
scientists.select(
    concat_str=pl.concat_str(pl.all(), separator=" "),
    format=pl.format("{}, {} from {}", "last_name", "first_name", "country"),
)
""":
  nbCode:
    nbShow scientists.select(
      concatStr([all()], separator = " ").alias("concat_str"),
      format("{}, {} from {}", col.last_name, col.first_name, col.country).alias("format"))

tabs """
prefs = pl.DataFrame(
    {
        "id": [1, 7, 42, 101, 999],
        "has_pet": [True, False, True, False, True],
        "likes_travel": [False, False, False, False, True],
        "likes_movies": [True, False, True, False, True],
        "likes_books": [False, False, True, True, True],
    }
).with_columns(
    all=pl.all_horizontal(pl.exclude("id")),
    any=pl.any_horizontal(pl.exclude("id")),
)

prefs
""":
  nbCode:
    let prefs = newDataFrame(
      series("id", [1, 7, 42, 101, 999]),
      series("has_pet", [true, false, true, false, true]),
      series("likes_travel", [false, false, false, false, true]),
      series("likes_movies", [true, false, true, false, true]),
      series("likes_books", [false, false, true, true, true]),
    ).withColumns(
      allHorizontal(all().exclude("id")).alias("all"),
      anyHorizontal(all().exclude("id")).alias("any"))
    nbShow prefs

tabs """
prefs.select(
    sum=pl.sum_horizontal(pl.all()),
    max=pl.max_horizontal(pl.all()),
    min=pl.min_horizontal(pl.all()),
)
""":
  nbCode:
    nbShow prefs.select(
      sumHorizontal(all()).alias("sum"),
      maxHorizontal(all()).alias("max"),
      minHorizontal(all()).alias("min"))

nbText: """
### When, then, otherwise

A conditional expression picks a value per row from the first condition that holds:
"""

tabs """
prefs.select(
    pl.col("id"),
    likes_what=pl.when(pl.all_horizontal(pl.col("^likes_.*$")))
    .then(pl.lit("Likes everything"))
    .when(pl.any_horizontal(pl.col("^likes_.*$")))
    .then(pl.lit("Likes something"))
    .otherwise(pl.lit("Likes nothing")),
)
""":
  nbCode:
    nbShow prefs.select(
      col.id,
      choose(
        if allHorizontal(col("^likes_.*$")): "Likes everything"
        elif anyHorizontal(col("^likes_.*$")): "Likes something"
        else: "Likes nothing").alias("likes_what"))

nanuq """
`choose` turns a Nim `if`/`elif`/`else` into Polars' `when/then/otherwise`; string
values are literals. The chained `` `when`(…).then(…).otherwise(…) `` works too, with
backticks because `when` is a Nim keyword.
"""

nbText: """
Without `otherwise`, rows that match no condition become null:
"""

tabs """
orders = pl.DataFrame(
    {
        "order_amount": [500, 750, 1200, 800, 1100],
        "status": ["Approved", "Processing", "Processing", "Declined", "Processing"],
    }
)
orders.with_columns(
    status=pl.when(pl.col("order_amount") > 1000).then(pl.lit("Flagged"))
)
""":
  nbCode:
    let orders = newDataFrame:
      order_amount: [500, 750, 1200, 800, 1100]
      status: ["Approved", "Processing", "Processing", "Declined", "Processing"]
    nbShow orders.withColumns(
      choose(if col.order_amount > 1000: "Flagged").alias("status"))

nbText: """
With `otherwise(col("status"))` they keep their old value:
"""

tabs """
orders.with_columns(
    status=pl.when(pl.col("order_amount") > 1000)
    .then(pl.lit("Flagged"))
    .otherwise(pl.col("status"))
)
""":
  nbCode:
    nbShow orders.withColumns(
      choose(if col.order_amount > 1000: "Flagged" else: col.status).alias("status"))

bookSave()
