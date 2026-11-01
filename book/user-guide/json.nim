import nanuqbook
bookInit()

nbText: "# JSON files"

attribution userGuide("JSON files", "io/json",
  "The files are `data/polars/path.json` and `data/polars/path.ndjson` instead of " &
  "`docs/assets/data/path.json`. The guide reads them before it writes them; here the " &
  "frame is written first, so that there is something to read, and each example shows the " &
  "dataframe it makes.")

nbText: """
Polars can read and write both standard JSON and newline-delimited JSON (NDJSON).

## Write
"""

tabs """
import polars as pl

df = pl.DataFrame({"foo": [1, 2, 3], "bar": [None, "bak", "baz"]})
df.write_json("data/polars/path.json")
df.write_ndjson("data/polars/path.ndjson")
""":
  nbCode:
    import nanuq

    let written = newDataFrame:
      foo: [1, 2, 3]
      bar: [nil, "bak", "baz"]
    written.writeJson("data/polars/path.json")
    written.writeNdjson("data/polars/path.ndjson")

nanuq """
`toJson` and `toNdjson` give the same text as a string, and both writers also take a
`Stream`.
"""

nbText: """
## Read

### JSON

Reading a JSON file should look familiar:
"""

tabs """
df = pl.read_json("data/polars/path.json")
df
""":
  nbCode:
    let df = readJson("data/polars/path.json")
    nbShow df

nbText: """
### Newline Delimited JSON

JSON objects that are delimited by newlines can be read into Polars in a much more
performant way than standard json.

Polars can read an NDJSON file into a `DataFrame` using the `read_ndjson` function:
"""

tabs """
df = pl.read_ndjson("data/polars/path.ndjson")
df
""":
  nbCode:
    let dfNd = readNdjson("data/polars/path.ndjson")
    nbShow dfNd

nbText: """
## Scan

Polars allows you to _scan_ a NDJSON input. Scanning delays the actual parsing of the file
and instead returns a lazy computation holder called a `LazyFrame`.
"""

tabs """
df = pl.scan_ndjson("data/polars/path.ndjson")
df.collect()
""":
  nbCode:
    let lazyDf = scanNdjson("data/polars/path.ndjson")
    nbShow lazyDf.collect

bookSave()
