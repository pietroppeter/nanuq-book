import nanuqbook
bookInit()

nbText: "# Polars internals"

attribution definitiveGuide(18, "Polars Internals",
  "Left out: the examples on the NYC taxi trips (several GB of Parquet files), `show_graph` " &
  "(it draws plans with Graphviz; the printed plan of `explain` is shown instead), " &
  "`pl.from_repr` and the timing of `%%time` cells. The profiling example runs on a small " &
  "query of the book's own.")

nbText: """
The last chapter of the book looks under the hood: how Polars stores data, how it
optimizes a query, how to inspect expressions and profile queries, and how to test them.
Nanuq runs the same engine, so all of it applies; this chapter keeps the parts with code.

## Query optimization

### Other optimizations

The optimizer finds a *common subplan* (here the doubled values, used by two branches) and
computes it once:
"""

tabs """
import polars as pl

values = pl.LazyFrame({"value": [10, 20, 30, 40, 50, 60]})

common_subplan = values.with_columns(pl.col("value") * 2)

branch1 = common_subplan.select(value2=pl.col("value") * 4)
branch2 = common_subplan.select(value3=pl.col("value") * 2)

combined = pl.concat([branch1, branch2])

print(combined.explain())
""":
  nbCode:
    import nanuq

    let values = newDataFrame(series("value", [10, 20, 30, 40, 50, 60])).lazy

    let commonSubplan = values.withColumns(col.value * 2)

    let branch1 = commonSubplan.select((col.value * 4).alias("value2"))
    let branch2 = commonSubplan.select((col.value * 2).alias("value3"))

    let combined = concat([branch1, branch2])

    echo combined.explain

nbText: """
Successive `with_columns` calls that don't depend on each other are merged into one, so
both versions of the BMI query below run as a single projection:
"""

tabs """
bmi = pl.LazyFrame(
    {"weight_kg": [70, 80, 60, 90], "length_cm": [175, 180, 160, 190]}
)

bmi = (
    bmi.with_columns(weight_per_cm=pl.col("weight_kg") / pl.col("length_cm"))
    .with_columns(weight_kg_average=pl.lit(0))
    .with_columns(length_m=pl.col("length_cm") / 100)
    .with_columns(weight_kg_average=pl.col("weight_kg").mean())
)
bmi.collect()
""":
  nbCode:
    var bmi = newDataFrame(
      series("weight_kg", [70, 80, 60, 90]),
      series("length_cm", [175, 180, 160, 190])).lazy

    bmi = bmi
      .withColumns((col.weight_kg / col.length_cm).alias("weight_per_cm"))
      .withColumns(lit(0).alias("weight_kg_average"))
      .withColumns((col.length_cm / 100).alias("length_m"))
      .withColumns(col.weight_kg.mean.alias("weight_kg_average"))
    nbShow bmi.collect

nbText: """
## Checking your expressions

### meta namespace examples

The `meta` namespace answers questions about an expression itself, without running it:
"""

tabs """
expr1 = pl.col("name")
expr2 = pl.lit("constant")

print(f"Is {expr1} a column: {expr1.meta.is_column()}")
print(f"Is {expr2} a column: {expr2.meta.is_column()}")
""":
  nbCode:
    var expr1 = col.name
    var expr2 = lit("constant")

    echo "Is ", expr1, " a column: ", expr1.meta.isColumn
    echo "Is ", expr2, " a column: ", expr2.meta.isColumn

tabs """
print(f"Is {expr1} a literal: {expr1.meta.is_literal()}")
print(f"Is {expr2} a literal: {expr2.meta.is_literal()}")
""":
  nbCode:
    echo "Is ", expr1, " a literal: ", expr1.meta.isLiteral
    echo "Is ", expr2, " a literal: ", expr2.meta.isLiteral

tabs """
expr1 = pl.col("age") * 2
expr2 = pl.col("name").alias("username")

# Get output names
print(f"{expr1} output name: {expr1.meta.output_name()}")
print(f"{expr2} output name: {expr2.meta.output_name()}")
""":
  nbCode:
    expr1 = col.age * 2
    expr2 = col.name.alias("username")

    # Get output names
    echo expr1, " output name: ", expr1.meta.outputName
    echo expr2, " output name: ", expr2.meta.outputName

tabs """
expr = pl.col("original_name").alias("new_name")

original_expr = expr.meta.undo_aliases()

original_expr.meta.output_name()
""":
  nbCode:
    var expr = col.original_name.alias("new_name")

    let originalExpr = expr.meta.undoAliases

    echo originalExpr.meta.outputName

tabs """
expr = pl.col("origin").alias("destination")

expr.meta.root_names()
""":
  nbCode:
    expr = col.origin.alias("destination")

    echo expr.meta.rootNames

nbText: """
## Profiling Polars

`profile` runs a query and also returns when each node of the plan started and ended, in
microseconds. The book profiles a query on the taxi trips; here it is a group-by on the
fruit table:
"""

tabs """
fruit_by_color = (
    pl.scan_csv("data/definitive-guide/fruit.csv")
    .filter(pl.col("weight") > 100)
    .group_by("color")
    .agg(total_weight=pl.col("weight").sum())
    .sort("total_weight", descending=True)
)

result, profiling_info = fruit_by_color.profile()
result
""":
  nbCode:
    let fruitByColor = scanCsv("data/definitive-guide/fruit.csv")
      .filter(col.weight > 100)
      .groupBy("color")
      .agg(col.weight.sum.alias("total_weight"))
      .sort("total_weight", descending = true)

    let (result, profilingInfo) = fruitByColor.profile
    nbShow result

tabs """
print(profiling_info.select("node"))
""":
  nbCode:
    echo profilingInfo.select("node")

nanuq """
Only the node names are printed: the times change from run to run, and the two engines
can name their nodes differently.
"""

nbText: """
## Tests in Polars

### Comparing DataFrames and Series

Polars has assertions to compare frames and series in tests. In Nanuq they are in the
module `nanuq/testing`, and they raise Nim's `AssertionDefect`, which `unittest` reports as
a failed check.
"""

tabs """
from polars.testing import (
    assert_series_equal,
    assert_frame_equal,
    assert_series_not_equal,
    assert_frame_not_equal,
)

floats = pl.DataFrame({"a": [1.0, 2.0, 3.0, 4.0]})

different_floats = pl.DataFrame({"a": [1.001, 2.0, 3.0, 4.0]})
""":
  nbCode:
    import nanuq/testing

    let floats = newDataFrame(series("a", [1.0, 2.0, 3.0, 4.0]))

    let differentFloats = newDataFrame(series("a", [1.001, 2.0, 3.0, 4.0]))

nbText: """
By default floats must be equal up to a tiny relative difference, so these two frames
differ:
"""

tabs """
try:
    assert_frame_equal(floats, different_floats)
except AssertionError as e:
    print(type(e).__name__)
""":
  nbCode:
    try:
      assertFrameEqual(floats, differentFloats)
    except AssertionDefect as e:
      echo e.name

nbText: """
With a relative tolerance of 1% they are equal:
"""

tabs """
assert_frame_equal(floats, different_floats, rel_tol=0.01)
print("The DataFrames are equal.")
""":
  nbCode:
    assertFrameEqual(floats, differentFloats, rtol = 0.01)
    echo "The DataFrames are equal."

nbText: """
The data types are compared too: an `Int8` frame equals only an `Int8` frame.
"""

tabs """
result = pl.DataFrame({"a": [1, 3], "b": [2, 4]}).cast(
    pl.Schema({"a": pl.Int8, "b": pl.Int8})
)

expected = pl.DataFrame(
    {"a": [1, 3], "b": [2, 4]}, schema={"a": pl.Int8, "b": pl.Int8}
)

assert_frame_equal(result, expected)
print("DataFrames are equal")
""":
  nbCode:
    block:
      let result = newDataFrame(series("a", [1, 3]), series("b", [2, 4]))
        .cast({"a": Int8, "b": Int8})

      let expected = newDataFrame:
        a: [1'i8, 3]
        b: [2'i8, 4]

      assertFrameEqual(result, expected)
      echo "DataFrames are equal"

nanuq """
The book builds `expected` from the printed table with `pl.from_repr`; both tabs here
build it from values.
"""

bookSave()
