import nanuqbook
bookInit()

nbText: "# Eager and lazy APIs"

attribution definitiveGuide(5, "Eager and Lazy APIs",
  "Left out: the two timed queries on the NYC taxi trips (several GB of Parquet files). " &
  "The chapter's tables of DataFrame and LazyFrame methods are not repeated.")

nbText: """
Polars has two ways to run a query. The *eager* API works on a `DataFrame` and runs each
step as soon as it is called. The *lazy* API works on a `LazyFrame`: each step only adds
to a query plan, and nothing runs until `collect`. Nanuq has the same two types.

## Eager API: DataFrame

The book times a query on a year of New York taxi trips, first eagerly with
`read_parquet`, then lazily with `scan_parquet`, and the lazy one wins because the
optimizer reads only the columns it needs. The data is too big for this book; the
[Lazy API](../user-guide/lazy_api.html) chapter shows the same idea on a small file.

## Lazy API: LazyFrame

A lazy query is checked against the schema before it runs, so a mistake is caught before
any data is read. Slicing a string out of an integer column fails at `collect`:
"""

tabs """
import polars as pl

names_lf = pl.LazyFrame({"name": ["Alice", "Bob", "Charlie"], "age": [25, 30, 35]})

erroneous_query = names_lf.with_columns(
    sliced_age=pl.col("age").str.slice(1, 3)
)

try:
    erroneous_query.collect()
except Exception as e:
    print(type(e).__name__)
""":
  nbCode:
    import nanuq

    let namesLf = newDataFrame(
      series("name", ["Alice", "Bob", "Charlie"]),
      series("age", [25, 30, 35])).lazy

    let erroneousQuery = namesLf.withColumns(
      col.age.str.slice(1, 3).alias("sliced_age"))

    try:
      discard erroneousQuery.collect
    except PolarsError as e:
      echo e.name

nanuq """
Polars' errors are Nim exceptions of the same names (`SchemaError`,
`ColumnNotFoundError`, …), so `try`/`except` reads like Python's.
"""

nbText: """
## Performance differences

Collecting runs the whole plan again each time: a LazyFrame stores the recipe, not the
result.
"""

tabs """
lf = pl.LazyFrame({"col1": [1, 2, 3], "col2": [4, 5, 6]})

# ... Some heavy computation ...

print(lf.collect())

print(lf.with_columns(pl.col("col1") + 1).collect())
""":
  nbCode:
    let lf = newDataFrame(
      series("col1", [1, 2, 3]),
      series("col2", [4, 5, 6])).lazy

    # ... Some heavy computation ...

    echo lf.collect

    echo lf.withColumns(col.col1 + 1).collect

nbText: """
## Tips and tricks

### Joining a DataFrame with a LazyFrame

A LazyFrame joins only with another LazyFrame. Python raises a `TypeError` when it gets a
DataFrame; in Nim the call does not compile. Make the DataFrame lazy first:
"""

tabs """
big_sales_data = pl.LazyFrame(
    {"sale_id": [101, 102, 103], "amount": [250, 150, 300]}
)

sales_metadata = pl.DataFrame(
    {"sale_id": [101, 102, 103], "category": ["A", "B", "A"]}
)

big_sales_data.join(sales_metadata.lazy(), on="sale_id").collect()
""":
  nbCode:
    let bigSalesData = newDataFrame(
      series("sale_id", [101, 102, 103]),
      series("amount", [250, 150, 300])).lazy

    let salesMetadata = newDataFrame:
      sale_id: [101, 102, 103]
      category: ["A", "B", "A"]

    nbShow bigSalesData.join(salesMetadata.lazy, on = ["sale_id"]).collect

nbText: """
### Caching intermediate results

To run the expensive part once, collect it and go lazy again: the new LazyFrame starts
from the computed data.
"""

tabs """
lf = pl.LazyFrame({"col1": [1, 2, 3], "col2": [4, 5, 6]})

# ... Some heavy computation ...

lf = lf.collect().lazy()
print(lf.collect())

print(lf.with_columns(pl.col("col1") + 1).collect())
""":
  nbCode:
    block:
      var lf = newDataFrame(
        series("col1", [1, 2, 3]),
        series("col2", [4, 5, 6])).lazy

      # ... Some heavy computation ...

      lf = lf.collect.lazy
      echo lf.collect

      echo lf.withColumns(col.col1 + 1).collect

bookSave()
