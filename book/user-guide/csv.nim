import nanuqbook
bookInit()

nbText: "# CSV"

attribution userGuide("CSV", "io/csv",
  "The file is `data/polars/path.csv` instead of `docs/assets/data/path.csv`, and each " &
  "example shows the dataframe it makes.")

nbText: """
## Read & write

Reading a CSV file should look familiar:
"""

tabs """
import polars as pl

df = pl.read_csv("data/polars/path.csv")
df
""":
  nbCode:
    import nanuq

    let df = readCsv("data/polars/path.csv")
    nbShow df

nbText: """
Writing a CSV file is similar with the `write_csv` function:
"""

tabs """
df = pl.DataFrame({"foo": [1, 2, 3], "bar": [None, "bak", "baz"]})
df.write_csv("data/polars/path.csv")
""":
  nbCode:
    let written = newDataFrame(
      series("foo", [1, 2, 3]),
      series("bar", [none(string), some("bak"), some("baz")]))
    written.writeCsv("data/polars/path.csv")

nanuq """
`readCsv` and `writeCsv` take Polars' options as named arguments: for example
`readCsv(path, separator = ';', hasHeader = false, nullValues = ["NA"])` and
`writeCsv(path, separator = '\t', quoteStyle = Always)`.
"""

nbText: """
## Scan

Polars allows you to *scan* a CSV input. Scanning delays the actual parsing of the file and
instead returns a lazy computation holder called a `LazyFrame`.
"""

tabs """
df = pl.scan_csv("data/polars/path.csv")
df.collect()
""":
  nbCode:
    let lazyDf = scanCsv("data/polars/path.csv")
    nbShow lazyDf.collect

nanuq """
`scanCsv` also takes a glob, such as `scanCsv("data/*.csv")`, to read many files as one.
"""

nbText: """
If you want to know why this is desirable, you can read more about these Polars
optimizations [here](lazy_api.html).
"""

bookSave()
