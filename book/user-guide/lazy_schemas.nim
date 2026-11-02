import nanuqbook
bookInit()

nbText: "# Lazy: schemas"

attribution userGuide("Schema", "lazy/schemas",
  "The last result is shown as a table instead of printed.")

nbText: """
The schema of a Polars `DataFrame` or `LazyFrame` sets out the names of the columns and
their datatypes. You can see the schema with the `.collect_schema` method on a `DataFrame`
or `LazyFrame`
"""

tabs """
import polars as pl

lf = pl.LazyFrame({"foo": ["a", "b", "c"], "bar": [0, 1, 2]})

print(lf.collect_schema())
""":
  nbCode:
    import nanuq

    var lf = newDataFrame(
      series("foo", ["a", "b", "c"]),
      series("bar", [0, 1, 2])).lazy

    echo lf.collectSchema

nanuq """
A Nanuq `Schema` is an `OrderedTable[string, DataType]`, and its data types print as the
Nim code that makes them (`String`, `Int64`).
"""

nbText: """
The schema plays an important role in the lazy API.

## Type checking in the lazy API

One advantage of the lazy API is that Polars will check the schema before any data is
processed. This check happens when you execute your lazy query.

We see how this works in the following simple example where we call the `.round`
expression on the string column `foo`.

The `.round` expression is only valid for columns with a numeric data type. Calling
`.round` on a string column means the operation will raise an `InvalidOperationError` when
we evaluate the query with `collect`. This schema check happens before the data is
processed when we call `collect`.
"""

tabs """
lf = pl.LazyFrame({"foo": ["a", "b", "c"]}).with_columns(pl.col("foo").round(2))

try:
    print(lf.collect())
except Exception as e:
    print(f"{type(e).__name__}: {e}")
""":
  nbCode:
    lf = newDataFrame(series("foo", ["a", "b", "c"])).lazy
      .withColumns(col.foo.round(2))

    try:
      echo lf.collect
    except CatchableError as e:
      echo e.name, ": ", e.msg

nbText: """
If we executed this query in eager mode the error would only be found once the data had
been processed in all earlier steps.

When we execute a lazy query Polars checks for any potential `InvalidOperationError` before
the time-consuming step of actually processing the data in the pipeline.

## The lazy API must know the schema

In the lazy API the Polars query optimizer must be able to infer the schema at every step
of a query plan. This means that operations where the schema is not knowable in advance
cannot be used with the lazy API.

The classic example of an operation where the schema is not knowable in advance is a
`.pivot` operation. In a `.pivot` the new column names come from data in one of the
columns. As these column names cannot be known in advance a `.pivot` is not available in
the lazy API.

## Dealing with operations not available in the lazy API

If your pipeline includes an operation that is not available in the lazy API it is normally
best to:

- run the pipeline in lazy mode up until that point
- execute the pipeline with `.collect` to materialize a `DataFrame`
- do the non-lazy operation on the `DataFrame`
- convert the output back to a `LazyFrame` with `.lazy` and continue in lazy mode

We show how to deal with a non-lazy operation in this example where we:

- create a simple `DataFrame`
- convert it to a `LazyFrame` with `.lazy`
- do a transformation using `.with_columns`
- execute the query before the pivot with `.collect` to get a `DataFrame`
- do the `.pivot` on the `DataFrame`
- convert back in lazy mode
- do a `.filter`
- finish by executing the query with `.collect` to get a `DataFrame`
"""

tabs """
lazy_eager_query = (
    pl.LazyFrame(
        {
            "id": ["a", "b", "c"],
            "month": ["jan", "feb", "mar"],
            "values": [0, 1, 2],
        }
    )
    .with_columns((2 * pl.col("values")).alias("double_values"))
    .collect()
    .pivot(index="id", on="month", values="double_values", aggregate_function="first")
    .lazy()
    .filter(pl.col("mar").is_null())
    .collect()
)
lazy_eager_query
""":
  nbCode:
    let lazyEagerQuery = newDataFrame(
        series("id", ["a", "b", "c"]),
        series("month", ["jan", "feb", "mar"]),
        series("values", [0, 1, 2]))
      .lazy
      .withColumns((2 * col.values).alias("double_values"))
      .collect
      .pivot(index = "id", on = "month", values = "double_values",
             aggregateFunction = PivotAgg.First)
      .lazy
      .filter(col.mar.isNull)
      .collect
    nbShow lazyEagerQuery

nanuq """
Nanuq also has a lazy `pivot`, which takes the values of `on` up front as a frame
(`onColumns`), so the schema is known again.
"""

bookSave()
