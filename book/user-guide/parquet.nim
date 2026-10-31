import nanuqbook
bookInit()

nbText: "# Parquet"

attribution userGuide("Parquet", "io/parquet",
  "The file is `data/polars/path.parquet` instead of `docs/assets/data/path.parquet`. The " &
  "write example comes first, so that the file exists when it is read, and each example " &
  "shows the dataframe it makes.")

nbText: """
Loading or writing [`Parquet` files](https://parquet.apache.org/) is lightning fast as the
layout of data in a Polars `DataFrame` in memory mirrors the layout of a Parquet file on
disk in many respects.

Unlike CSV, Parquet is a columnar format. This means that the data is stored in columns
rather than rows. This is a more efficient way of storing data as it allows for better
compression and faster access to data.

## Write
"""

tabs """
import polars as pl

df = pl.DataFrame({"foo": [1, 2, 3], "bar": [None, "bak", "baz"]})
df.write_parquet("data/polars/path.parquet")
df
""":
  nbCode:
    import nanuq

    let written = newDataFrame(
      series("foo", [1, 2, 3]),
      series("bar", [none(string), some("bak"), some("baz")]))
    written.writeParquet("data/polars/path.parquet")
    nbShow written

nanuq """
`writeParquet` compresses with Zstandard by default, like Python Polars; the
`compression` argument takes the enum `ParquetCompression` (for example
`writeParquet(path, compression = ParquetCompression.Snappy)`).
"""

nbText: """
## Read

We can read a `Parquet` file into a `DataFrame` using the `read_parquet` function:
"""

tabs """
df = pl.read_parquet("data/polars/path.parquet")
df
""":
  nbCode:
    let df = readParquet("data/polars/path.parquet")
    nbShow df

nbText: """
## Scan

Polars allows you to _scan_ a `Parquet` input. Scanning delays the actual parsing of the
file and instead returns a lazy computation holder called a `LazyFrame`.
"""

tabs """
df = pl.scan_parquet("data/polars/path.parquet")
df.collect()
""":
  nbCode:
    let lazyDf = scanParquet("data/polars/path.parquet")
    nbShow lazyDf.collect

nbText: """
If you want to know why this is desirable, you can read more about those Polars
optimizations [here](lazy_api.html).

When we scan a `Parquet` file stored in the cloud, we can also apply predicate and
projection pushdowns. This can significantly reduce the amount of data that needs to be
downloaded. For scanning a Parquet file in the cloud, see
[Cloud storage](https://docs.pola.rs/user-guide/io/cloud-storage/#scanning-from-cloud-storage-with-query-optimisation).
"""

nanuq """
Nanuq reads local files only so far: no cloud storage yet.
"""

bookSave()
