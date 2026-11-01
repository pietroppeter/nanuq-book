import nanuqbook
bookInit()

nbText: "# Filtering and sorting rows"

attribution definitiveGuide(11, "Filtering and Sorting Rows",
  "Data is read from `data/definitive-guide/`. The sample uses a seed, so that both sides " &
  "pick the same rows.")

nbText: """
Two verbs decide which rows you keep and in which order: `filter` and `sort`. This
chapter follows the book's examples on a small table of power tools.
"""

tabs """
import polars as pl

tools = pl.read_csv("data/definitive-guide/tools.csv")
tools
""":
  nbCode:
    import nanuq

    let tools = readCsv("data/definitive-guide/tools.csv")
    nbShow tools

nbText: """
## Filtering rows

### Filtering based on expressions

`filter` keeps the rows where a boolean expression is true: here the cordless tools made
by Makita.
"""

tabs """
tools.filter(pl.col("cordless") & (pl.col("brand") == "Makita"))
""":
  nbCode:
    nbShow tools.filter(col.cordless and col.brand == "Makita")

nanuq """
Python's `filter` also takes several predicates, which it combines with `&`, a bare column
name (`tools.filter("cordless")`) and keyword constraints (`filter(cordless=True,
brand="Makita")`). Nanuq's `filter` takes one expression, so all three are the one above.
"""

nbText: """
## Sorting rows

### Sorting based on a single column
"""

tabs """
tools.sort("price")
""":
  nbCode:
    nbShow tools.sort("price")

nbText: "### Sorting in reverse"

tabs """
tools.sort("price", descending=True)
""":
  nbCode:
    nbShow tools.sort("price", descending = true)

nbText: """
### Sorting based on multiple columns

With several keys, the second one breaks the ties of the first. `descending` can be set
per key.
"""

tabs """
tools.sort("brand", "price")
""":
  nbCode:
    nbShow tools.sort(["brand", "price"])

tabs """
tools.sort("brand", "price", descending=[False, True])
""":
  nbCode:
    nbShow tools.sort(["brand", "price"], descending = [false, true])

nbText: """
### Sorting based on expressions

The key can be computed: here the tools sorted by revolutions per minute per dollar.
"""

tabs """
tools.sort(pl.col("rpm") / pl.col("price"))
""":
  nbCode:
    nbShow tools.sort([col.rpm / col.price])

nbText: """
### Sorting nested data types

Lists sort value by value, like words letter by letter:
"""

tabs """
lists = pl.DataFrame({"lists": [[2, 2], [2, 1, 3], [1]]})
lists.sort("lists")
""":
  nbCode:
    let lists = newDataFrame:
      lists: [@[2, 2], @[2, 1, 3], @[1]]
    nbShow lists.sort("lists")

nbText: "Structs sort field by field:"

tabs """
structs = pl.DataFrame(
    {
        "structs": [
            {"a": 1, "b": 2, "c": 3},
            {"a": 1, "b": 3, "c": 1},
            {"a": 1, "b": 1, "c": 2},
        ]
    }
)
structs.sort("structs")
""":
  nbCode:
    let structs = newDataFrame:
      structs: [(a: 1, b: 2, c: 3), (a: 1, b: 3, c: 1), (a: 1, b: 1, c: 2)]
    nbShow structs.sort("structs")

nbText: "A group-by can collect each brand's tools into a list of structs:"

tabs """
tools_collection = tools.group_by("brand").agg(collection=pl.struct(pl.all()))
tools_collection
""":
  nbCode:
    let toolsCollection = tools.groupBy("brand").agg(asStruct(all()).alias("collection"))
    nbShow toolsCollection

nbText: "To sort by such a column, compute a key from it, such as the length of each list:"

tabs """
tools_collection.sort(pl.col("collection").list.len(), descending=True)
""":
  nbCode:
    nbShow toolsCollection.sort([col.collection.list.len], descending = [true])

tabs """
tools_collection.sort(
    pl.col("collection")
    .list.eval(pl.element().struct.field("price"))
    .list.mean()
)
""":
  nbCode:
    nbShow toolsCollection.sort([
      col.collection
        .list.eval(element().struct.field("price"))
        .list.mean])

tabs """
tools_collection.with_columns(
    mean_price=pl.col("collection")
    .list.eval(pl.element().struct.field("price"))
    .list.mean()
).sort("mean_price")
""":
  nbCode:
    nbShow toolsCollection.withColumns(
      col.collection
        .list.eval(element().struct.field("price"))
        .list.mean
        .alias("mean_price")
    ).sort("mean_price")

nbText: """
## Related row operations

### Filtering missing values

`dropNulls` drops the rows with a missing value, in the columns you name or in any column.
"""

tabs """
tools.drop_nulls("rpm").height
""":
  nbCode:
    echo tools.dropNulls("rpm").height

nbText: """
The same check across all columns, spelled out: `all_horizontal` is true for a row when
all of its expressions are, here when no column is null.
"""

nanuq """
Nanuq's `allHorizontal` takes a list of expressions or, as here, a selector expression.
"""

tabs """
tools.filter(pl.all_horizontal(pl.all().is_not_null())).height
""":
  nbCode:
    echo tools.filter(allHorizontal(all().isNotNull)).height

nbText: """
### Slicing

`head`, `tail` and `slice` take consecutive rows; `gather_every` takes every *n*th row.
`with_row_index` shows which rows were taken.
"""

tabs """
tools.with_row_index().gather_every(2).head(3)
""":
  nbCode:
    nbShow tools.withRowIndex().gatherEvery(2).head(3)

nbText: """
### Top and bottom

`top_k` gives the *k* rows with the largest values of a column, largest first, and
`bottom_k` the smallest.
"""

tabs """
tools.top_k(3, by="price")
""":
  nbCode:
    nbShow tools.topK(3, by = "price")

nbText: """
### Sampling

`sample` picks random rows, by count or by fraction. With a seed it picks the same rows on
every run.
"""

tabs """
tools.sample(fraction=0.2, seed=42)
""":
  nbCode:
    nbShow tools.sample(fraction = 0.2, seed = 42)

nbText: """
### Semi-joins

A semi-join filters a frame by another one: it keeps the rows whose key appears in the
other frame, without adding its columns. Here, the tools that are saws.
"""

tabs """
saws = pl.DataFrame(
    {
        "tool": [
            "Table Saw",
            "Plunge Cut Saw",
            "Miter Saw",
            "Jigsaw",
            "Bandsaw",
            "Chainsaw",
            "Seesaw",
        ]
    }
)
tools.join(saws, how="semi", on="tool")
""":
  nbCode:
    let saws = newDataFrame:
      tool: ["Table Saw", "Plunge Cut Saw", "Miter Saw", "Jigsaw", "Bandsaw",
             "Chainsaw", "Seesaw"]
    nbShow tools.join(saws, on = ["tool"], how = Semi)

bookSave()
