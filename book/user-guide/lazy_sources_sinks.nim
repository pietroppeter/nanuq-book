import nanuqbook
bookInit()

nbText: "# Lazy: sources and sinks"

attribution userGuide("Sources and sinks", "lazy/sources_sinks",
  "The guide's snippets use placeholders (`my_dataset/*.csv`, `..`); here they run on " &
  "`data/polars/reddit.csv` and write to a temporary folder. The filter is wrapped in " &
  "`all_horizontal`, which Polars 2 requires.")

nbText: """
## Scan

When using the `LazyFrame` API, it is important to favor `scan_*` (`scan_parquet`, `scan_csv`,
etc.) over `read_*`. A Polars `scan` is lazy and will delay execution until the query is
collected. The benefit of this, is that the Polars optimizer can push optimization into the
readers. They can skip reading columns and rows that aren't required. Another benefit is that,
during streaming execution, the engine already can process batches before the file is
completely read.

## Sink

Sinks can execute a query and stream the results to storage (being disk or cloud). The benefit
of sinking data to storage is that you don't necessarily have to store all data in RAM, but can
process data in batches.

If we would want to convert many csv files to parquet, whilst dropping the missing data, we
could do something like the query below. We use a partitioning strategy that defines how many
rows may be in a single parquet file, before we generate a new file
"""

tabs """
import os
import tempfile
import polars as pl

out = os.path.join(tempfile.gettempdir(), "nanuq-book-sinks")

lf = pl.scan_csv("data/polars/reddit.csv").filter(pl.all_horizontal(pl.all().is_not_null()))
lf.sink_parquet(
    pl.PartitionBy(
        os.path.join(out, "output_folder"),
        max_rows_per_file=25,
    ),
    mkdir=True,
)
print(sorted(os.listdir(os.path.join(out, "output_folder"))))
""":
  nbCode:
    import nanuq, std/[os, algorithm]

    let output = getTempDir() / "nanuq-book-sinks"

    let lf = scanCsv("data/polars/reddit.csv").filter(allHorizontal(all().isNotNull))
    lf.sinkParquet(
      PartitionBy(
        basePath: output / "output_folder",
        maxRowsPerFile: 25),
      mkdir = true)
    var files: seq[string]
    for f in walkFiles(output / "output_folder" / "*"): files.add f.extractFilename
    echo files.sorted

nanuq """
In Polars 2 `filter(pl.all().is_not_null())` is an error (the predicate "expanded to multiple
expressions"), so both tabs combine the column checks with `all_horizontal`. The sample has 99
complete rows, so a limit of 25 rows per file gives four files.
"""

nbText: """
This will create the following files on disk:

```text
output_folder/00000000.parquet
output_folder/00000001.parquet
...
output_folder/0000000f.parquet
output_folder/00000010.parquet
```

## Multiplexing sinks

Sinks can also multiplex. Meaning that we write to different sinks in a single query. In the
code snippet below, we take a `LazyFrame` and sink it into 2 sinks at the same time.
"""

tabs """
q1 = lf.sink_parquet(os.path.join(out, "reddit.parquet"), lazy=True)
q2 = lf.sink_ipc(os.path.join(out, "reddit.arrow"), lazy=True)

pl.collect_all([q1, q2])
pl.scan_ipc(os.path.join(out, "reddit.arrow")).select(pl.len()).collect()
""":
  nbCode:
    let q1 = lf.sinkParquet(output / "reddit.parquet", lazy = true)
    let q2 = lf.sinkIpc(output / "reddit.arrow", lazy = true)

    discard collectAll([q1, q2])
    nbShow scanIpc(output / "reddit.arrow").select(len()).collect

nanuq """
With `lazy = true` a Nanuq sink returns the sink as a `LazyFrame`, as in Python; `collectAll`
then runs both and returns empty frames. The last line reads one of the files back to show that
it was written. `explainAll([q1, q2])` prints the shared plan: one `SINK_MULTIPLE` whose two
sinks read the same `CACHE`d scan.
"""

bookSave()
