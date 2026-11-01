import nanuqbook
bookInit()

nbText: "# Pivots"

attribution userGuide("Pivots", "transformations/pivot",
  "The aggregation is a value of the enum `PivotAgg` where Python uses a string, and the " &
  "lazy pivot's `on_columns` is a dataframe of the values to expect.")

nbText: """
Pivot a column in a `DataFrame` and perform one of the following aggregations:

- first
- last
- sum
- min
- max
- mean
- median
- len

The pivot operation consists of a group by one, or multiple columns (these will be the new
y-axis), the column that will be pivoted (this will be the new x-axis) and an aggregation.

## Dataset
"""

tabs """
import polars as pl

df = pl.DataFrame(
    {
        "foo": ["A", "A", "B", "B", "C"],
        "N": [1, 2, 2, 4, 2],
        "bar": ["k", "l", "m", "n", "o"],
    }
)
df
""":
  nbCode:
    import nanuq

    let df = newDataFrame:
      foo: ["A", "A", "B", "B", "C"]
      N: [1, 2, 2, 4, 2]
      bar: ["k", "l", "m", "n", "o"]
    nbShow df

nbText: """
## Eager
"""

nanuq """
In Nanuq the aggregation is a value of the enum `PivotAgg` (`Item`, the default, which
fails if a cell gets more than one value, `First`, `Last`, `Sum`, `Min`, `Max`, `Mean`,
`Median` and `Len`), or an expression on `element()`, the values that end up in one
cell: `aggregateFunction = element().sum`.
"""

tabs """
df.pivot("bar", index="foo", values="N", aggregate_function="first")
""":
  nbCode:
    let eager = df.pivot("bar", index = "foo", values = "N",
                         aggregateFunction = PivotAgg.First)
    nbShow eager

nbText: """
## Lazy

A Polars `LazyFrame` always need to know the schema of a computation statically (before
collecting the query). As a pivot's output schema depends on the data, and it is therefore
impossible to determine the schema without running the query.

Polars could have abstracted this fact for you just like Spark does, but we don't want you
to shoot yourself in the foot with a shotgun. The cost should be clear upfront.

You have two options if you wish to use lazy evaluation with a pivot. You may collect the
`DataFrame` before performing the pivot (sacrificing lazy evaluation benefits), or you may
specify the `on_columns` parameter upfront to declare the resulting schema statically.
"""

tabs """
q = (
    df.lazy()
    .collect()
    .pivot(index="foo", on="bar", values="N", aggregate_function="first")
    .lazy()
)
q.collect()
""":
  nbCode:
    let q = df.lazy
      .collect
      .pivot(index = "foo", on = "bar", values = "N", aggregateFunction = PivotAgg.First)
      .lazy
    nbShow q.collect

nanuq """
Nanuq's `onColumns` is a dataframe with the values of the `on` column to expect, one
column per `on` column (Polars itself takes a dataframe there; Python also accepts a
list).
"""

tabs """
q = df.lazy().pivot(
    index="foo",
    on="bar",
    on_columns=["k", "l", "m", "n", "o"],
    values="N",
    aggregate_function="first",
)
q.collect()
""":
  nbCode:
    let q2 = df.lazy.pivot(
      index = "foo",
      on = "bar",
      onColumns = newDataFrame(series("bar", ["k", "l", "m", "n", "o"])),
      values = "N",
      aggregateFunction = PivotAgg.First)
    nbShow q2.collect

bookSave()
