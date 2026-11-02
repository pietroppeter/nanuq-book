import nanuqbook
bookInit()

nbText: "# Streaming"

attribution userGuide("Streaming", "concepts/streaming",
  "The iris dataset is read from `data/polars/`, the query shows its result, and the " &
  "picture of the physical plan (`show_graph`) is left out: Nanuq has no `showGraph`. The " &
  "section on monitoring through Polars Cloud is left out too.")

nbText: """
One additional benefit of the lazy API is that it allows queries to be executed in a streaming
manner. Instead of processing all the data at once, Polars can execute the query in batches
allowing you to process datasets that do not fit in memory. Besides memory pressure, the
streaming engine also is more performant than Polars' in-memory engine.

To tell Polars we want to execute a query in streaming mode we pass the `engine="streaming"`
argument to `collect`:
"""

tabs """
import polars as pl

q1 = (
    pl.scan_csv("data/polars/iris.csv")
    .filter(pl.col("sepal_length") > 5)
    .group_by("species")
    .agg(pl.col("sepal_width").mean())
)
df = q1.collect(engine="streaming")
df
""":
  nbCode:
    import nanuq

    let q1 = scanCsv("data/polars/iris.csv")
      .filter(col.sepal_length > 5)
      .groupBy("species")
      .agg(col.sepal_width.mean)
    let df = q1.collect(Engine.Streaming)
    nbShow df

nanuq """
Nanuq's `collect` with no engine uses `Engine.Auto`, which is Polars' default. The other
engines are `Engine.Streaming` and `Engine.InMemory`; `collectAll` and the sinks take one too
(sinks always stream).
"""

nbText: """
## Inspecting a streaming query

Polars can run many operations in a streaming manner. Some operations are inherently
non-streaming, or are not implemented in a streaming manner (yet). In the latter case, Polars
will fall back to the in-memory engine for those operations. A user doesn't have to know about
this, but it can be interesting for debugging memory or performance issues.

To inspect the physical plan of streaming query, you can plot the physical graph. The legend
shows how memory intensive the operation can be.

```python
q1 = (
    pl.scan_csv("docs/assets/data/iris.csv")
    .filter(pl.col("sepal_length") > 5)
    .group_by("species")
    .agg(
        mean_width=pl.col("sepal_width").mean(),
        mean_width2=pl.col("sepal_width").sum() / pl.col("sepal_length").count(),
    )
    .show_graph(plan_stage="physical", engine="streaming")
)
```
"""

nanuq """
There is no `showGraph` in Nanuq 0.6, so no picture of the physical plan; `explain` prints the
optimized logical plan.
"""

bookSave()
