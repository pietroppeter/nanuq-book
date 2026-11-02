import nanuqbook
bookInit()

nbText: "# Lazy: usage"

attribution userGuide("Usage", "lazy/using",
  "The Reddit CSV is `data/polars/reddit.csv`, the 100-row sample in the Polars " &
  "repository, and each query shows its result.")

nbText: """
With the lazy API, Polars doesn't run each query line-by-line but instead processes the full
query end-to-end. To get the most out of Polars it is important that you use the lazy API
because:

- the lazy API allows Polars to apply automatic query optimization with the query optimizer
- the lazy API allows you to work with larger than memory datasets using streaming
- the lazy API can catch schema errors before processing the data

Here we see how to use the lazy API starting from either a file or an existing `DataFrame`.

## Using the lazy API from a file

In the ideal case we would use the lazy API right from a file as the query optimizer may help
us to reduce the amount of data we read from the file.

We create a lazy query from the Reddit CSV data and apply some transformations.

By starting the query with `pl.scan_csv` we are using the lazy API.
"""

tabs """
import polars as pl

q1 = (
    pl.scan_csv("data/polars/reddit.csv")
    .with_columns(pl.col("name").str.to_uppercase())
    .filter(pl.col("comment_karma") > 0)
)
q1.collect()
""":
  nbCode:
    import nanuq

    let q1 = scanCsv("data/polars/reddit.csv")
      .withColumns(col.name.str.toUppercase)
      .filter(col.comment_karma > 0)
    nbShow q1.collect

nanuq """
`q1` is only a plan: the last line collects it here, so the page can show what it gives.
"""

nbText: """
A `pl.scan_` function is available for a number of file types including CSV, IPC, Parquet and
JSON.

In this query we tell Polars that we want to:

- load data from the Reddit CSV file
- convert the `name` column to uppercase
- apply a filter to the `comment_karma` column

The lazy query will not be executed at this point. See this page on
[executing lazy queries](lazy_execution.html) for more on running lazy queries.

## Using the lazy API from a `DataFrame`

An alternative way to access the lazy API is to call `.lazy` on a `DataFrame` that has already
been created in memory.
"""

tabs """
q3 = pl.DataFrame({"foo": ["a", "b", "c"], "bar": [0, 1, 2]}).lazy()
q3.collect()
""":
  nbCode:
    let q3 = newDataFrame(
      series("foo", ["a", "b", "c"]),
      series("bar", [0, 1, 2])).lazy
    nbShow q3.collect

nanuq """
Nanuq's scan functions are `scanCsv`, `scanParquet`, `scanIpc` and `scanNdjson`; each takes a
path, a glob or (for Parquet and IPC) a cloud URL.
"""

nbText: """
By calling `.lazy` we convert the `DataFrame` to a `LazyFrame`.
"""

bookSave()
