import nanuqbook
bookInit()

nbText: "# Lazy API"

attribution userGuide("Lazy API", "concepts/lazy-api",
  "The iris dataset is read from `data/polars/` (a copy of the one in the Polars " &
  "repository), and the eager example shows its result instead of printing it.")

nbText: """
Polars supports two modes of operation: lazy and eager. The examples so far have used the
eager API, in which the query is executed immediately. In the lazy API, the query is only
evaluated once it is *collected*. Deferring the execution to the last minute can have
significant performance advantages and is why the lazy API is preferred in most cases. Let
us demonstrate this with an example:
"""

tabs """
import polars as pl

df = pl.read_csv("data/polars/iris.csv")
df_small = df.filter(pl.col("sepal_length") > 5)
df_agg = df_small.group_by("species").agg(pl.col("sepal_width").mean())
df_agg
""":
  nbCode:
    import nanuq

    let df = readCsv("data/polars/iris.csv")
    let dfSmall = df.filter(col("sepal_length") > 5)
    let dfAgg = dfSmall.groupBy("species").agg(col("sepal_width").mean)
    nbShow dfAgg

nanuq """
The groups come in the order they are first seen; in Python their order
can change from run to run (the book compares the two tables row by row, in any order).
"""

nbText: """
In this example we use the eager API to:

1. Read the iris [dataset](https://archive.ics.uci.edu/dataset/53/iris).
1. Filter the dataset based on sepal length.
1. Calculate the mean of the sepal width per species.

Every step is executed immediately returning the intermediate results. This can be very
wasteful as we might do work or load extra data that is not being used. If we instead used
the lazy API and waited on execution until all the steps are defined then the query planner
could perform various optimizations. In this case:

- Predicate pushdown: Apply filters as early as possible while reading the dataset, thus
  only reading rows with sepal length greater than 5.
- Projection pushdown: Select only the columns that are needed while reading the dataset,
  thus removing the need to load additional columns (e.g., petal length and petal width).
"""

tabs """
q = (
    pl.scan_csv("data/polars/iris.csv")
    .filter(pl.col("sepal_length") > 5)
    .group_by("species")
    .agg(pl.col("sepal_width").mean())
)

df = q.collect()
df
""":
  nbCode:
    let q = scanCsv("data/polars/iris.csv")
      .filter(col("sepal_length") > 5)
      .groupBy(col("species"))
      .agg(col("sepal_width").mean)

    let lazyDf = q.collect
    nbShow lazyDf

nbText: """
These will significantly lower the load on memory & CPU thus allowing you to fit bigger
datasets in memory and process them faster. Once the query is defined you call `collect` to
inform Polars that you want to execute it. You can
[learn more about the lazy API in its dedicated chapter](https://docs.pola.rs/user-guide/lazy/).

> **Eager API**
>
> In many cases the eager API is actually calling the lazy API under the hood and
> immediately collecting the result. This has the benefit that within the query itself
> optimization(s) made by the query planner can still take place.
"""

nanuq """
That is also how Nanuq's eager functions work: `df.filter(e)` is `df.lazy.filter(e).collect`.
"""

nbText: """
## When to use which

In general, the lazy API should be preferred unless you are either interested in the
intermediate results or are doing exploratory work and don't know yet what your query is
going to look like.

## Previewing the query plan

When using the lazy API you can use the function `explain` to ask Polars to create a
description of the query plan that will be executed once you collect the results. This can
be useful if you want to see what types of optimizations Polars performs on your queries.
We can ask Polars to explain the query `q` we defined above:
"""

tabs """
print(q.explain())
""":
  nbCode:
    echo q.explain

nanuq """
The two plans are the same but for `maintain_order: true`: Nanuq's `groupBy` keeps the
groups in the order they are first seen, as Python's `group_by(..., maintain_order=True)`
does.
"""

nbText: """
Immediately, we can see in the explanation that Polars did apply predicate pushdown, as it
is only reading rows where the sepal length is greater than 5, and it did apply projection
pushdown, as it is only reading the columns that are needed by the query.

The function `explain` can also be used to see how expression expansion will unfold in the
context of a given schema. Consider the example expression from the
[section on expression expansion](expression_expansion.html):

```python
(pl.col(pl.Float64) * 1.1).name.suffix("*1.1")
```

We can use `explain` to see how this expression would evaluate against an arbitrary schema:
"""

nanuq """
Nanuq can't make a `LazyFrame` from a schema alone yet, so the Nim version builds an empty
dataframe with those column types and makes it lazy.
"""

tabs """
schema = pl.Schema(
    {
        "int_1": pl.Int16,
        "int_2": pl.Int32,
        "float_1": pl.Float64,
        "float_2": pl.Float64,
        "float_3": pl.Float64,
    }
)

print(
    pl.LazyFrame(schema=schema)
    .select((pl.col(pl.Float64) * 1.1).name.suffix("*1.1"))
    .explain()
)
""":
  nbCode:
    let noInts: seq[int] = @[]
    let noFloats: seq[float] = @[]
    let empty = newDataFrame(
      series("int_1", noInts), series("int_2", noInts),
      series("float_1", noFloats), series("float_2", noFloats), series("float_3", noFloats))
      .`cast`({"int_1": Int16, "int_2": Int32})

    echo empty.lazy
      .select((col(float) * 1.1).name.suffix("*1.1"))
      .explain

bookSave()
