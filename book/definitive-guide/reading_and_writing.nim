import nanuqbook
bookInit()

nbText: "# Reading and writing data"

attribution definitiveGuide(6, "Reading and Writing Data",
  "Data is read from `data/definitive-guide/` (penguins, the Pokédex JSON and the " &
  "Wikimedia NDJSON, from the book's repository); the `cat` cells show the start of the " &
  "files with Nim. Left out: other encodings than UTF-8 (Nanuq's `readCsv` has no " &
  "`encoding`), Excel, the stock-price files of the multiple-files section and the taxi " &
  "Parquet files (too big to ship), pandas and databases.")

nbText: """
Data comes from files, and goes back into them. This chapter reads CSV, JSON and NDJSON,
and writes CSV and Parquet.

## Reading CSV Files
"""

nbCode:
  import std/strutils
  echo readFile("data/definitive-guide/penguins.csv").splitLines[0 .. 4].join("\n")

tabs """
import polars as pl

penguins = pl.read_csv("data/definitive-guide/penguins.csv")
penguins
""":
  nbCode:
    import nanuq

    var penguins = readCsv("data/definitive-guide/penguins.csv")
    nbShow penguins

nbText: """
## Parsing Missing Values Correctly

The file writes missing values as `NA`, so the numeric columns with one came out as
strings. `null_values` says how missing values look:
"""

tabs """
penguins = pl.read_csv("data/definitive-guide/penguins.csv", null_values="NA")
penguins
""":
  nbCode:
    penguins = readCsv("data/definitive-guide/penguins.csv", nullValues = ["NA"])
    nbShow penguins

tabs """
penguins.null_count().transpose(
    include_header=True, column_names=["null_count"]
)
""":
  nbCode:
    nbShow penguins.select(all().nullCount).transpose(
      includeHeader = true, columnNames = ["null_count"])

nanuq """
Nanuq's frame `nullCount(column)` counts one column; for all of them, select
`all().nullCount`.
"""

nbText: """
## Reading JSON and NDJSON

### JSON

The Pokédex is one JSON object, with a list of Pokémon:
"""

nbCode:
  echo readFile("data/definitive-guide/pokedex.json").splitLines[0 .. 15].join("\n")

tabs """
pokedex = pl.read_json("data/definitive-guide/pokedex.json")
pokedex
""":
  nbCode:
    let pokedex = readJson("data/definitive-guide/pokedex.json")
    nbShow pokedex

nbText: "So the frame has one row, with a list of structs. `explode` and `unnest` make it a table:"

tabs """
(
    pokedex.explode("pokemon")
    .unnest("pokemon")
    .select("id", "name", "type", "height", "weight")
)
""":
  nbCode:
    nbShow pokedex.explode("pokemon")
      .unnest("pokemon")
      .select("id", "name", "type", "height", "weight")

nbText: """
### NDJSON

Newline-delimited JSON has one object per line, here edits to Wikipedia:
"""

nbCode:
  echo readFile("data/definitive-guide/wikimedia.ndjson").splitLines[0][0 .. 300], "..."

nanuq """
The book prints the first object with `pprint`; here the start of the first line is
enough.
"""

tabs """
wikimedia = pl.read_ndjson("data/definitive-guide/wikimedia.ndjson")
wikimedia
""":
  nbCode:
    let wikimedia = readNdjson("data/definitive-guide/wikimedia.ndjson")
    nbShow wikimedia

tabs """
(
    wikimedia.rename({"id": "edit_id"})
    .unnest("meta")
    .select("timestamp", "title", "user", "comment")
)
""":
  nbCode:
    nbShow wikimedia.rename({"id": "edit_id"})
      .unnest("meta")
      .select("timestamp", "title", "user", "comment")

nbText: """
## Writing Data

### CSV Format
"""

tabs """
all_stocks = pl.read_csv("data/definitive-guide/all_stocks.csv")
all_stocks.write_csv("data/definitive-guide/all_stocks_copy.csv")
""":
  nbCode:
    let allStocks = readCsv("data/definitive-guide/all_stocks.csv")
    allStocks.writeCsv("data/definitive-guide/all_stocks_copy.csv")

nanuq """
The book's `all_stocks` comes from the multiple-files section, left out here; the book
ships the result, `all_stocks.csv`, which both sides read and write to a copy.
"""

nbText: "### Parquet Format"

tabs """
all_stocks.write_parquet("data/definitive-guide/all_stocks.parquet")
""":
  nbCode:
    allStocks.writeParquet("data/definitive-guide/all_stocks.parquet")

bookSave()
