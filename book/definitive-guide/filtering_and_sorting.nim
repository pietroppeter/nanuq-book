import nanuqbook
bookInit()

nbText: "# Filtering and sorting rows"

attribution definitiveGuide(11, "Filtering and Sorting Rows",
  "Data is read from `data/definitive-guide/`. Left out: sorting nested data (lists and " &
  "structs), `pl.all_horizontal`, `gather_every` and `top_k`, which Nanuq does not have " &
  "yet. The sample uses a seed, so that both sides pick the same rows.")

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

nanuq """
The book goes on to sort lists and structs, and a group-by that collects each brand's tools
into a list of structs. Nanuq has no nested types yet, so those examples are left out.
"""

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
