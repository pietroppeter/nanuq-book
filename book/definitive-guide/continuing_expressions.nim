import nanuqbook
bookInit()

nbText: "# Continuing expressions"

attribution definitiveGuide(8, "Continuing Expressions",
  "Data is read from `data/definitive-guide/` (the NVIDIA prices are the book's " &
  "`stock/nvda/2023.csv`). The book draws random numbers with numpy; here both sides draw " &
  "them with Polars' seeded `sample`, or use the penguins, so that they get the same ones. " &
  "Left out: the operations that need list or struct columns (`repeat_by`, `explode`, " &
  "`implode`, `reshape`, `rle`, `value_counts`), the timing cells, the plot, and `hash`, " &
  "`extend_constant`, `shuffle`, `sample` on an expression, `upper_bound` and `arg_true`, " &
  "which Nanuq does not have yet.")

nbText: """
The previous chapter introduced expressions; this one goes through the many methods an
expression has, grouped by what they do to the shape of a column.

## Types of operations

### Example A: element-wise operations

An element-wise operation computes one value for each value: the result has as many rows
as the input.
"""

nanuq """
Python names new columns with keyword arguments (`mass=...`); Nim with `alias`.
"""

tabs """
import math
import polars as pl

penguins = pl.read_csv("data/definitive-guide/penguins.csv", null_values="NA").select(
    "species",
    "island",
    "sex",
    "year",
    mass=pl.col("body_mass_g") / 1000,
)
penguins.with_columns(
    mass_sqrt=pl.col("mass").sqrt(),
    mass_exp=pl.col("mass").exp(),
)
""":
  nbCode:
    import std/math
    import nanuq

    let penguins = readCsv("data/definitive-guide/penguins.csv", nullValues = ["NA"]).select(
      col.species, col.island, col.sex, col.year,
      (col.body_mass_g / 1000).alias("mass"))
    nbShow penguins.withColumns(
      col.mass.sqrt.alias("mass_sqrt"),
      col.mass.exp.alias("mass_exp"))

nbText: """
### Example B: operations that summarize to one

An aggregation reduces a column to one value:
"""

tabs """
penguins.select(pl.col("mass").mean(), pl.col("island").first())
""":
  nbCode:
    nbShow penguins.select(col.mass.mean, col.island.first)

nbText: """
### Example C: operations that summarize to one or more

Some operations return a number of values that depends on the data, such as the distinct
values:
"""

nanuq """
Without `maintain_order`, `unique` returns the values in any order; the book compares the
rows of both sides as a set.
"""

tabs """
penguins.select(pl.col("island").unique())
""":
  nbCode:
    nbShow penguins.select(col.island.unique)

nanuq """
The book's “Example D”, operations that make a column longer, repeats each species with
`repeat_by` (a list per row), `explode`s the lists and adds a value with
`extend_constant`. Nanuq has none of them yet, so it is left out.
"""

nbText: """
## Element-wise operations

### Operations that perform mathematical transformations
"""

nanuq """
`log(2)` is the logarithm in base 2; `log` with no argument is the natural logarithm, as
in Python. The `math.e` of Python is `E` from std/math.
"""

tabs """
(
    pl.DataFrame({"x": [-2.0, 0.0, 0.5, 1.0, math.e, 1000.0]}).with_columns(
        abs=pl.col("x").abs(),
        exp=pl.col("x").exp(),
        log2=pl.col("x").log(2),
        log10=pl.col("x").log10(),
        log1p=pl.col("x").log1p(),
        sign=pl.col("x").sign(),
        sqrt=pl.col("x").sqrt(),
    )
)
""":
  nbCode:
    nbShow newDataFrame(series("x", [-2.0, 0.0, 0.5, 1.0, E, 1000.0])).withColumns(
      col.x.abs.alias("abs"),
      col.x.exp.alias("exp"),
      col.x.log(2).alias("log2"),
      col.x.log10.alias("log10"),
      col.x.log1p.alias("log1p"),
      col.x.sign.alias("sign"),
      col.x.sqrt.alias("sqrt"))

nbText: """
### Operations related to trigonometry

The trigonometric functions work in radians; `degrees` and `radians` convert.
"""

tabs """
(
    pl.DataFrame(
        {"x": [-math.pi, 0.0, 1.0, math.pi, 2 * math.pi, 90.0, 180.0, 360.0]}
    ).with_columns(
        arccos=pl.col("x").arccos(),
        cos=pl.col("x").cos(),
        degrees=pl.col("x").degrees(),
        radians=pl.col("x").radians(),
        sin=pl.col("x").sin(),
    )
)
""":
  nbCode:
    nbShow newDataFrame(
      series("x", [-PI, 0.0, 1.0, PI, 2 * PI, 90.0, 180.0, 360.0])
    ).withColumns(
      col.x.arccos.alias("arccos"),
      col.x.cos.alias("cos"),
      col.x.degrees.alias("degrees"),
      col.x.radians.alias("radians"),
      col.x.sin.alias("sin"))

nbText: """
### Operations that round and categorize

`cut` puts each value in a bin between fixed breaks, `qcut` between quantiles of the data.
"""

nanuq """
`clip(-1, 1)` takes both bounds; with one, name it: `clip(lowerBound = 0)`. `round` rounds
half to even by default, like Python Polars.
"""

tabs """
(
    pl.DataFrame(
        {"x": [-6.0, -0.5, 0.0, 0.5, math.pi, 9.9, 9.99, 9.999]}
    ).with_columns(
        ceil=pl.col("x").ceil(),
        clip=pl.col("x").clip(-1, 1),
        cut=pl.col("x").cut([-1, 1], labels=["bad", "neutral", "good"]),
        floor=pl.col("x").floor(),
        qcut=pl.col("x").qcut([0.5], labels=["below median", "above median"]),
        round2=pl.col("x").round(2),
        round0=pl.col("x").round(0),
    )
)
""":
  nbCode:
    nbShow newDataFrame(
      series("x", [-6.0, -0.5, 0.0, 0.5, PI, 9.9, 9.99, 9.999])
    ).withColumns(
      col.x.ceil.alias("ceil"),
      col.x.clip(-1, 1).alias("clip"),
      col.x.cut([-1.0, 1.0], labels = ["bad", "neutral", "good"]).alias("cut"),
      col.x.floor.alias("floor"),
      col.x.qcut([0.5], labels = ["below median", "above median"]).alias("qcut"),
      col.x.round(2).alias("round2"),
      col.x.round(0).alias("round0"))

nbText: """
### Operations for missing or infinite values

A float column can hold missing values (`null`) and the special values NaN and infinity,
and each has its own tests and fills:
"""

nanuq """
In Nim a missing value is `none(float)`, and NaN and infinity are `NaN` and `Inf`.
"""

tabs """
x = [42.0, math.nan, None, math.inf, -math.inf]
(
    pl.DataFrame({"x": x}).with_columns(
        fill_nan=pl.col("x").fill_nan(999),
        fill_null=pl.col("x").fill_null(0),
        is_finite=pl.col("x").is_finite(),
        is_infinite=pl.col("x").is_infinite(),
        is_nan=pl.col("x").is_nan(),
        is_null=pl.col("x").is_null(),
    )
)
""":
  nbCode:
    let xs = newDataFrame(series("x", [some(42.0), some(NaN), none(float), some(Inf),
                                       some(-Inf)]))
    nbShow xs.withColumns(
      col.x.fillNan(999).alias("fill_nan"),
      col.x.fillNull(0).alias("fill_null"),
      col.x.isFinite.alias("is_finite"),
      col.x.isInfinite.alias("is_infinite"),
      col.x.isNan.alias("is_nan"),
      col.x.isNull.alias("is_null"))

nbText: "To treat NaN and null alike, combine them:"

tabs """
(
    pl.DataFrame({"x": x}).with_columns(
        fill_both=pl.col("x").fill_nan(0).fill_null(0),
        is_either=(pl.col("x").is_nan() | pl.col("x").is_null()),
    )
)
""":
  nbCode:
    nbShow xs.withColumns(
      col.x.fillNan(0).fillNull(0).alias("fill_both"),
      (col.x.isNan or col.x.isNull).alias("is_either"))

nbText: """
### Other operations

`replace` maps some values to others and leaves the rest alone:
"""

nanuq """
The book also shows `hash` and `repeat_by` here; Nanuq has neither yet (`repeat_by`
returns lists), so this cell keeps `replace`. Nim writes the mapping as `{"a": "b"}`.
"""

tabs """
(
    pl.DataFrame({"x": ["here", "there", "their", "they're"]}).with_columns(
        replace=pl.col("x").replace(
            {
                "here": "there",
                "they're": "they are",
            }
        ),
    )
)
""":
  nbCode:
    nbShow newDataFrame(series("x", ["here", "there", "their", "they're"])).withColumns(
      col.x.replace({"here": "there", "they're": "they are"}).alias("replace"))

nbText: """
## Nonreducing series-wise operations

These keep the length of the column, but each result depends on other values of the
column, not only on its own.

### Operations that accumulate
"""

tabs """
import numpy as np

(
    pl.DataFrame(
        {"x": [0.0, 1.0, 2.0, None, 2.0, np.nan, -1.0, 2.0]}
    ).with_columns(
        cum_count=pl.col("x").cum_count(),
        cum_max=pl.col("x").cum_max(),
        cum_min=pl.col("x").cum_min(),
        cum_prod=pl.col("x").cum_prod(reverse=True),
        cum_sum=pl.col("x").cum_sum(),
        diff=pl.col("x").diff(),
        pct_change=pl.col("x").pct_change(),
    )
)
""":
  nbCode:
    nbShow newDataFrame(
      series("x", [some(0.0), some(1.0), some(2.0), none(float), some(2.0), some(NaN),
                   some(-1.0), some(2.0)])
    ).withColumns(
      col.x.cumCount.alias("cum_count"),
      col.x.cumMax.alias("cum_max"),
      col.x.cumMin.alias("cum_min"),
      col.x.cumProd(reverse = true).alias("cum_prod"),
      col.x.cumSum.alias("cum_sum"),
      col.x.diff.alias("diff"),
      col.x.pctChange.alias("pct_change"))

nbText: """
### Operations that fill and shift

Missing values can be filled from their neighbours, or interpolated; `shift` moves the
values down (or up, with a negative number).
"""

nanuq """
Python's `method` is `how` in Nanuq (as for `rank` and `corr`), a value of the enum
`InterpolationMethod`: `Linear` or `Nearest`.
"""

tabs """
(
    pl.DataFrame(
        {"x": [-1.0, 0.0, 1.0, None, None, 3.0, 4.0, math.nan, 6.0]}
    ).with_columns(
        backward_fill=pl.col("x").backward_fill(),
        forward_fill=pl.col("x").forward_fill(limit=1),
        interp1=pl.col("x").interpolate(method="linear"),
        interp2=pl.col("x").interpolate(method="nearest"),
        shift1=pl.col("x").shift(1),
        shift2=pl.col("x").shift(-2),
    )
)
""":
  nbCode:
    nbShow newDataFrame(
      series("x", [some(-1.0), some(0.0), some(1.0), none(float), none(float), some(3.0),
                   some(4.0), some(NaN), some(6.0)])
    ).withColumns(
      col.x.backwardFill.alias("backward_fill"),
      col.x.forwardFill(limit = 1).alias("forward_fill"),
      col.x.interpolate(how = InterpolationMethod.Linear).alias("interp1"),
      col.x.interpolate(how = InterpolationMethod.Nearest).alias("interp2"),
      col.x.shift(1).alias("shift1"),
      col.x.shift(-2).alias("shift2"))

nbText: "### Operations related to duplicate values"

tabs """
(
    pl.DataFrame({"x": ["A", "C", "D", "C"]}).with_columns(
        is_duplicated=pl.col("x").is_duplicated(),
        is_first_distinct=pl.col("x").is_first_distinct(),
        is_last_distinct=pl.col("x").is_last_distinct(),
        is_unique=pl.col("x").is_unique(),
    )
)
""":
  nbCode:
    nbShow newDataFrame(series("x", ["A", "C", "D", "C"])).withColumns(
      col.x.isDuplicated.alias("is_duplicated"),
      col.x.isFirstDistinct.alias("is_first_distinct"),
      col.x.isLastDistinct.alias("is_last_distinct"),
      col.x.isUnique.alias("is_unique"))

nbText: """
### Operations that compute rolling statistics

A rolling statistic looks at a window of neighbouring values; an exponentially weighted
mean (EWM) weighs all earlier values, the recent ones most. On NVIDIA's closing prices in
2023:
"""

nanuq """
`ewmMean` takes the decay by name, as one of `com`, `span`, `halfLife` or `alpha`. The
book then plots the three series with plotnine; the plot is left out.
"""

tabs """
stock = (
    pl.read_csv("data/definitive-guide/nvda_2023.csv", try_parse_dates=True)
    .select("date", "close")
    .with_columns(
        ewm_mean=pl.col("close").ewm_mean(com=7, ignore_nulls=True),
        rolling_mean=pl.col("close").rolling_mean(window_size=7),
        rolling_min=pl.col("close").rolling_min(window_size=7),
    )
)

stock
""":
  nbCode:
    let stock = readCsv("data/definitive-guide/nvda_2023.csv", tryParseDates = true)
      .select(col.date, col.close)
      .withColumns(
        col.close.ewmMean(com = 7, ignoreNulls = true).alias("ewm_mean"),
        col.close.rollingMean(windowSize = 7).alias("rolling_mean"),
        col.close.rollingMin(windowSize = 7).alias("rolling_min"))
    nbShow stock

nbText: "### Operations that sort"

nanuq """
The book also shuffles the column with `shuffle(seed=7)`; Nanuq has no `shuffle` on an
expression yet, so that column is left out.
"""

tabs """
(
    pl.DataFrame(
        {
            "x": [1, 3, None, 3, 7],
            "y": ["D", "I", "S", "C", "O"],
        }
    ).with_columns(
        arg_sort=pl.col("x").arg_sort(),
        sort=pl.col("x").sort(nulls_last=True),
        sort_by=pl.col("x").sort_by("y"),
        reverse=pl.col("x").reverse(),
        rank=pl.col("x").rank(),
    )
)
""":
  nbCode:
    nbShow newDataFrame(
      series("x", [some(1), some(3), none(int), some(3), some(7)]),
      series("y", ["D", "I", "S", "C", "O"])
    ).withColumns(
      col.x.argSort.alias("arg_sort"),
      col.x.sort(nullsLast = true).alias("sort"),
      col.x.sortBy("y").alias("sort_by"),
      col.x.reverse.alias("reverse"),
      col.x.rank.alias("rank"))

nbText: """
### Other operations

`rle_id` numbers the runs of equal values:
"""

tabs """
(
    pl.DataFrame({"x": [33, 33, 27, 33, 60, 60, 60, 33, 60]}).with_columns(
        rle_id=pl.col("x").rle_id(),
    )
)
""":
  nbCode:
    nbShow newDataFrame(series("x", [33, 33, 27, 33, 60, 60, 60, 33, 60])).withColumns(
      col.x.rleId.alias("rle_id"))

nbText: """
## Series-wise operations that summarize to one

An aggregation in `with_columns` is broadcast to every row; in a group-by it gives one
value per group.
"""

tabs """
(
    pl.DataFrame({"x": [1, 3, 3, 7]}).with_columns(
        mean=pl.col("x").mean(),
    )
)
""":
  nbCode:
    nbShow newDataFrame(series("x", [1, 3, 3, 7])).withColumns(col.x.mean.alias("mean"))

tabs """
(
    pl.DataFrame({"cluster": ["a", "a", "b", "b"], "x": [1, 3, 3, 7]})
    .group_by("cluster")
    .agg(
        mean=pl.col("x").mean(),
    )
)
""":
  nbCode:
    nbShow newDataFrame(series("cluster", ["a", "a", "b", "b"]), series("x", [1, 3, 3, 7]))
      .groupBy("cluster")
      .agg(col.x.mean.alias("mean"))

nbText: """
### Operations that are quantifiers

`all` is true when every value is, `any` when at least one is:
"""


tabs """
df = pl.DataFrame(
    {
        "x": [True, False, False],
        "y": [True, True, True],
        "z": [False, False, False],
    }
)
print(df)
df.select(
    pl.all().all().name.suffix("_all"),
    pl.all().any().name.suffix("_any"),
)
""":
  nbCode:
    let bools = newDataFrame:
      x: [true, false, false]
      y: [true, true, true]
      z: [false, false, false]
    echo bools
    nbShow bools.select(
      all().all.name.suffix("_all"),
      all().any.name.suffix("_any"))

nbText: """
### Operations that compute statistics
"""

nanuq """
The book computes these on a million numbers drawn from a normal distribution with numpy.
Nanuq can't draw the same numbers, so both sides use the penguins' masses instead.
"""

tabs """
(
    penguins.select(
        max=pl.col("mass").max(),
        mean=pl.col("mass").mean(),
        quantile=pl.col("mass").quantile(quantile=0.95),
        skew=pl.col("mass").skew(),
        std=pl.col("mass").std(),
        sum=pl.col("mass").sum(),
        var=pl.col("mass").var(),
    )
)
""":
  nbCode:
    nbShow penguins.select(
      col.mass.max.alias("max"),
      col.mass.mean.alias("mean"),
      col.mass.quantile(0.95).alias("quantile"),
      col.mass.skew.alias("skew"),
      col.mass.std.alias("std"),
      col.mass.sum.alias("sum"),
      col.mass.var.alias("var"))

nbText: """
### Operations that count

1,729 random integers below 10,000, one of them made missing:
"""

nanuq """
The book draws the integers with numpy and sets value 403 to `None` in place. Here both
sides draw them with Polars' `sample` and a seed, and blank value 403 with a `when` that
has no `otherwise`.
"""

tabs """
df_ints = (
    pl.DataFrame({"x": range(10_000)})
    .sample(1_729, with_replacement=True, seed=1729)
    .with_row_index()
    .with_columns(x=pl.when(pl.col("index") != 403).then(pl.col("x")))
)
df_ints.slice(400, 6)
""":
  nbCode:
    import std/sequtils
    let dfInts = newDataFrame(series("x", toSeq(0 ..< 10_000)))
      .sample(1_729, withReplacement = true, seed = 1729)
      .withRowIndex()
      .withColumns(`when`(col("index") != 403).then(col.x).alias("x"))
    nbShow dfInts.slice(400, 6)

tabs """
df_ints.select(
    approx_n_unique=pl.col("x").approx_n_unique(),
    count=pl.col("x").count(),
    len=pl.col("x").len(),
    n_unique=pl.col("x").n_unique(),
    null_count=pl.col("x").null_count(),
)
""":
  nbCode:
    nbShow dfInts.select(
      col.x.approxNUnique.alias("approx_n_unique"),
      col.x.count.alias("count"),
      col.x.len.alias("len"),
      col.x.nUnique.alias("n_unique"),
      col.x.nullCount.alias("null_count"))

nbText: """
The book then times `n_unique` against `approx_n_unique` on ten million integers: the
approximation is several times faster. (Timings are left out of this book's builds.)

### Other operations
"""

nanuq """
Nanuq has no `get` on an expression yet: `gather([403])` takes the same value, as a
column of one row. `implode` (a list) and `upper_bound` are left out.
"""

tabs """
df_ints.select(
    arg_min=pl.col("x").arg_min(),
    first=pl.col("x").first(),
    get=pl.col("x").gather([403]),
    last=pl.col("x").last(),
)
""":
  nbCode:
    nbShow dfInts.select(
      col.x.argMin.alias("arg_min"),
      col.x.first.alias("first"),
      col.x.gather([403]).alias("get"),
      col.x.last.alias("last"))

nbText: """
## Series-wise operations that summarize to one or more

### Operations related to unique values
"""

nanuq """
The book adds `value_counts`, which returns structs; Nanuq has no structs yet, so that
column is left out.
"""

tabs """
(
    pl.DataFrame({"x": ["A", "C", "D", "C"]}).select(
        arg_unique=pl.col("x").arg_unique(),
        unique=pl.col("x").unique(maintain_order=True),
        unique_counts=pl.col("x").unique_counts(),
    )
)
""":
  nbCode:
    nbShow newDataFrame(series("x", ["A", "C", "D", "C"])).select(
      col.x.argUnique.alias("arg_unique"),
      col.x.unique(maintainOrder = true).alias("unique"),
      col.x.uniqueCounts.alias("unique_counts"))

nbText: "### Operations that select"

nanuq """
The book also takes a random `sample(7)` of the column; Nanuq has `sample` on frames only,
so that column is left out.
"""

tabs """
df_ints.select(
    bottom_k=pl.col("x").bottom_k(7),
    head=pl.col("x").head(7),
    slice=pl.col("x").slice(400, 7),
    gather=pl.col("x").gather([1, 1, 2, 3, 5, 8, 13]),
    gather_every=pl.col("x").gather_every(247),
    top_k=pl.col("x").top_k(7),
)
""":
  nbCode:
    nbShow dfInts.select(
      col.x.bottomK(7).alias("bottom_k"),
      col.x.head(7).alias("head"),
      col.x.slice(400, 7).alias("slice"),
      col.x.gather([1, 1, 2, 3, 5, 8, 13]).alias("gather"),
      col.x.gatherEvery(247).alias("gather_every"),
      col.x.topK(7).alias("top_k"))

nbText: "### Operations that drop missing values"

tabs """
x = [None, 1.0, 2.0, 3.0, np.nan]
(
    pl.DataFrame({"x": x}).select(
        drop_nans=pl.col("x").drop_nans(), drop_nulls=pl.col("x").drop_nulls()
    )
)
""":
  nbCode:
    nbShow newDataFrame(
      series("x", [none(float), some(1.0), some(2.0), some(3.0), some(NaN)])
    ).select(
      col.x.dropNans.alias("drop_nans"), col.x.dropNulls.alias("drop_nulls"))

nbText: """
### Other operations

`mode` gives the most common values (more than one when they tie):
"""

nanuq """
The book first shows `arg_true`, the positions where a condition holds, which Nanuq does
not have yet. It can be written as a filter on the row numbers:
`intRange(col.x.len, dtype = UInt32).filter(col.x >= 60)`. `reshape` (to arrays) and
`rle` (structs) are left out.
"""

tabs """
numbers = [33, 33, 27, 33, 60, 60, 60, 33, 60]

(
    pl.DataFrame({"x": numbers}).select(
        mode=pl.col("x").mode().sort(),
    )
)
""":
  nbCode:
    let numbers = newDataFrame(series("x", [33, 33, 27, 33, 60, 60, 60, 33, 60]))
    nbShow numbers.select(col.x.mode.sort.alias("mode"))

nbText: """
`search_sorted` gives the position where a value would go in a sorted column:
"""

tabs """
(
    pl.DataFrame({"x": numbers}).select(
        rle=pl.col("x").sort().search_sorted(42),
    )
)
""":
  nbCode:
    nbShow numbers.select(col.x.sort.searchSorted(42).alias("rle"))

nanuq """
The chapter ends with series-wise operations that extend: `explode` turns each list into
rows.
"""

tabs """
(
    pl.DataFrame(
        {
            "x": [["a", "b"], ["c", "d"]],
        }
    ).select(explode=pl.col("x").explode())
)
""":
  nbCode:
    nbShow newDataFrame(series("x", [@["a", "b"], @["c", "d"]]))
      .select(col.x.explode.alias("explode"))

bookSave()
