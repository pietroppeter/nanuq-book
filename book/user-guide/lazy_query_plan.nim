import nanuqbook
bookInit()

nbText: "# Lazy: query plan"

attribution userGuide("Query plan", "lazy/query-plan",
  "The Reddit CSV is `data/polars/reddit.csv`, the 100-row sample in the Polars " &
  "repository, and the printed plans are the ones the book's build produces. The Graphviz " &
  "pictures (`show_graph`) are left out: Nanuq has no `showGraph`.")

nbText: """
For any lazy query Polars has both:

- a non-optimized plan with the set of steps code as we provided it and
- an optimized plan with changes made by the query optimizer

We can understand both the non-optimized and optimized query plans with visualization and by
printing them as text.

Below we consider the following query:
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
## Non-optimized query plan

### Graphviz visualization

To create visualizations of the query plan,
[Graphviz should be installed](https://graphviz.org/download/) and added to your PATH.

First we visualize the non-optimized plan by setting `optimized=False`.

```python
q1.show_graph(plan_stage="ir", optimized=False)
```

The query plan visualization should be read from bottom to top. In the visualization:

- each box corresponds to a stage in the query plan
- the `sigma` stands for `SELECTION` and indicates any filter conditions
- the `pi` stands for `PROJECTION` and indicates choosing a subset of columns
"""

nanuq """
Nanuq has no `showGraph` yet: Polars draws these pictures from its Python side (it writes
Graphviz *dot* text, then calls `dot`). The printed plans below carry the same information.
"""

nbText: """
### Printed query plan

We can also print the non-optimized plan with `explain(optimized=False)`
"""

tabs """
print(q1.explain(optimized=False))
""":
  nbCode:
    echo q1.withOptimizations(QueryOptFlags.none).explain

nanuq """
Nanuq's `explain` takes no `optimized` flag: turning every optimization off with
`withOptimizations(QueryOptFlags.none)` gives the non-optimized plan (with one more pair of
parentheses around the filter).
"""

nbText: """
The printed plan should also be read from bottom to top. This non-optimized plan is roughly
equal to:

- read from the `data/reddit.csv` file
- read all 6 columns (where the * wildcard in PROJECT \*/6 COLUMNS means take all columns)
- transform the `name` column to uppercase
- apply a filter on the `comment_karma` column

## Optimized query plan

Now we visualize the optimized plan with `show_graph`.

```python
q1.show_graph(plan_stage="ir")
```

When using the streaming engine, we can also visualize the physical plan by setting
`plan_type="streaming"` (the default).

```python
q1.show_graph(plan_stage="physical")
```

We can also print the optimized plan with `explain`
"""

tabs """
print(q1.explain())
""":
  nbCode:
    echo q1.explain

nbText: """
The optimized plan is to:

- read the data from the Reddit CSV
- apply the filter on the `comment_karma` column while the CSV is being read line-by-line
- transform the `name` column to uppercase

In this case the query optimizer has identified that the `filter` can be applied while the CSV
is read from disk rather than reading the whole file into memory and then applying the filter.
This optimization is called _Predicate Pushdown_.
"""

bookSave()
