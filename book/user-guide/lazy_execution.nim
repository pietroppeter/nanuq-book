import nanuqbook
bookInit()

nbText: "# Lazy: query execution"

attribution userGuide("Query execution", "lazy/execution",
  "The Reddit CSV is `data/polars/reddit.csv`, the 100-row sample in the Polars " &
  "repository (the guide's tables come from a 10-million-row file), and each query shows " &
  "its result.")

nbText: """
Our example query on the Reddit dataset is:
"""

tabs """
import polars as pl

q1 = (
    pl.scan_csv("data/polars/reddit.csv")
    .with_columns(pl.col("name").str.to_uppercase())
    .filter(pl.col("comment_karma") > 0)
)
""":
  nbCode:
    import nanuq

    let q1 = scanCsv("data/polars/reddit.csv")
      .withColumns(col.name.str.toUppercase)
      .filter(col.comment_karma > 0)

nbText: """
If we were to run the code above on the Reddit CSV the query would not be evaluated. Instead
Polars takes each line of code, adds it to the internal query graph and optimizes the query
graph.

When we execute the code Polars executes the optimized query graph by default.

### Execution on the full dataset

We can execute our query on the full dataset by calling the `.collect` method on the query.
"""

tabs """
q4 = (
    pl.scan_csv("data/polars/reddit.csv")
    .with_columns(pl.col("name").str.to_uppercase())
    .filter(pl.col("comment_karma") > 0)
    .collect()
)
q4
""":
  nbCode:
    let q4 = scanCsv("data/polars/reddit.csv")
      .withColumns(col.name.str.toUppercase)
      .filter(col.comment_karma > 0)
      .collect
    nbShow q4

nbText: """
Above we see that from the 100 rows of the sample there are 27 rows that match our predicate
(the guide's full file gives 14,029 of 10 million).

With the default `collect` method Polars processes all of your data as one batch. This means
that all the data has to fit into your available memory at the point of peak memory usage in
your query.
"""

nanuq """
**Reusing `LazyFrame` objects.** Remember that `LazyFrame`s are query plans i.e. a promise on
computation and is not guaranteed to cache common subplans. This means that every time you
reuse it in separate downstream queries after it is defined, it is computed all over again. If
you define an operation on a `LazyFrame` that doesn't maintain row order (such as a
`group_by`), then the order will also change every time it is run. To avoid this, use
`maintain_order=True` arguments for such operations.

(The guide's warning box. In Nanuq `groupBy` always keeps the order of first appearance, so
that last point does not bite.)
"""

nbText: """
### Execution on larger-than-memory data

If your data requires more memory than you have available Polars may be able to process the
data in batches using _streaming_ mode. To use streaming mode you simply pass the
`engine="streaming"` argument to `collect`
"""

tabs """
q5 = (
    pl.scan_csv("data/polars/reddit.csv")
    .with_columns(pl.col("name").str.to_uppercase())
    .filter(pl.col("comment_karma") > 0)
    .collect(engine="streaming")
)
q5
""":
  nbCode:
    let q5 = scanCsv("data/polars/reddit.csv")
      .withColumns(col.name.str.toUppercase)
      .filter(col.comment_karma > 0)
      .collect(Engine.Streaming)
    nbShow q5

nbText: """
### Execution on a partial dataset

While you're writing, optimizing or checking your query on a large dataset, querying all
available data may lead to a slow development process.

Instead, you can scan a subset of your partitions or use `.head`/`.collect` at the beginning
and end of your query, respectively. Keep in mind that the results of aggregations and filters
on subsets of your data may not be representative of the result you would get on the full
data.
"""

tabs """
q9 = (
    pl.scan_csv("data/polars/reddit.csv")
    .head(10)
    .with_columns(pl.col("name").str.to_uppercase())
    .filter(pl.col("comment_karma") > 0)
    .collect()
)
q9
""":
  nbCode:
    let q9 = scanCsv("data/polars/reddit.csv")
      .head(10)
      .withColumns(col.name.str.toUppercase)
      .filter(col.comment_karma > 0)
      .collect
    nbShow q9

nbText: """
## Diverging queries

It is very common that a query diverges at one point. In these cases it is recommended to use
`collect_all` as they will ensure that diverging queries execute only once.
"""

tabs """
# Some expensive LazyFrame
lf = pl.scan_csv("data/polars/reddit.csv").filter(pl.col("comment_karma") > 0)

lf_1 = lf.select(pl.col("comment_karma", "link_karma").sum())

lf_2 = lf.group_by((pl.col("link_karma") > 0).alias("has_links")).len().sort("has_links")

pl.collect_all([lf_1, lf_2])[1]  # this will execute lf only once!
""":
  nbCode:
    # Some expensive LazyFrame
    let lf = scanCsv("data/polars/reddit.csv").filter(col.comment_karma > 0)

    let lf1 = lf.select(col(["comment_karma", "link_karma"]).sum)

    let lf2 = lf.groupBy((col.link_karma > 0).alias("has_links")).len.sort("has_links")

    let both = collectAll([lf1, lf2])  # this will execute lf only once!
    nbShow both[1]

nanuq """
The guide shows this pattern on a placeholder `lf` with `some_other_computation`; here both
branches are real queries on the Reddit sample, and the page shows the second result.
"""

bookSave()
