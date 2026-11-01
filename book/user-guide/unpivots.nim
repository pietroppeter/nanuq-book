import nanuqbook
bookInit()

nbText: "# Unpivots"

attribution userGuide("Unpivots", "transformations/unpivot", "")

nbText: """
Unpivot unpivots a DataFrame from wide format to long format

## Dataset
"""

tabs """
import polars as pl

df = pl.DataFrame(
    {
        "A": ["a", "b", "a"],
        "B": [1, 3, 5],
        "C": [10, 11, 12],
        "D": [2, 4, 6],
    }
)
df
""":
  nbCode:
    import nanuq

    let df = newDataFrame:
      A: ["a", "b", "a"]
      B: [1, 3, 5]
      C: [10, 11, 12]
      D: [2, 4, 6]
    nbShow df

nbText: """
## Eager + lazy

`Eager` and `lazy` have the same API.
"""

tabs """
df.unpivot(["C", "D"], index=["A", "B"])
""":
  nbCode:
    let unpivoted = df.unpivot(["C", "D"], index = ["A", "B"])
    nbShow unpivoted

bookSave()
