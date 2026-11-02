import nanuq, nanuqbook, benchkit, pdsh
import std/[algorithm, os, json, strutils, osproc, sequtils]
bookInit()

const benchScale {.strdefine.} = "1"  ## scale factor of a full run (`-d:benchScale=10`)

nbText: "# PDS-H queries"

nanuq """
**About this chapter.** The queries are ported from the Polars queries of
[polars-benchmark](https://github.com/pola-rs/polars-benchmark), by the Polars
contributors, licensed under the
[Apache License 2.0](https://github.com/pietroppeter/nanuq-book/blob/main/licenses/polars-benchmark-Apache-2.0.txt).
The data comes from [tpchgen-cli](https://github.com/datafusion-contrib/tpchgen-rs), which
generates the TPC-H tables; it is made on the fly and never stored in the repository.
PDS-H is derived from TPC-H, but these results are not comparable to published TPC-H
results. The text is the book's own.
"""

proc tpchData(scale: string): string =
  ## The tables at this scale factor, generated with tpchgen-cli the first time.
  result = ".." / "bench-data" / "tpch-" & scale
  if not fileExists(result / "lineitem.csv"):
    createDir result
    let (o, code) = execCmdEx("tpchgen-cli csv -s " & scale & " --output-dir=" & quoteShell(result))
    doAssert code == 0, "tpchgen-cli failed (run the book with `uv run`):\n" & o

type Query = tuple[n: int, run: proc (t: Tables): LazyFrame]

proc queries(scale: float): seq[Query] =
  @[(1, q1), (2, q2), (3, q3), (4, q4), (5, q5), (6, q6), (7, q7), (8, q8), (9, q9),
    (10, q10), (11, proc (t: Tables): LazyFrame = q11(t, scale)),
    (12, q12), (13, q13), (14, q14), (15, q15), (16, q16), (17, q17), (18, q18),
    (19, q19), (20, q20), (21, q21), (22, q22)]

proc pyCall(n: int, scale: float, engine = "in-memory"): string =
  "q" & $n & "(**_tables" & (if n == 11: ", scale_factor=" & $scale else: "") &
    ").collect(engine=" & escapeJson(engine) & ")"

proc loadPython(dir: string) =
  discard runPython("import sys\nsys.path.insert(0, '../bench')\nfrom pdsh import *\n" &
                    "_tables = scan_tables(" & escapeJson(dir) & ")")

# --- A full run: only with -d:bench -------------------------------------------------
when defined(bench):
  let scale = parseFloat(benchScale)
  let dir = tpchData(benchScale)
  let tables = scanTables(dir)
  loadPython(dir)
  var nimMemory, nimStreaming, pyMemory, pyStreaming = newJObject()
  for (n, run) in queries(scale):
    let q = "q" & $n
    echo "[bench] ", q
    nimMemory[q] = %timeIt(benchRuns, proc () = discard run(tables).collect(Engine.InMemory))
    nimStreaming[q] = %timeIt(benchRuns, proc () = discard run(tables).collect(Engine.Streaming))
    pyMemory[q] = %timePython(benchRuns, pyCall(n, scale))
    pyStreaming[q] = %timePython(benchRuns, pyCall(n, scale, "streaming"))
  discard saveResult("pdsh", %*{"scaleFactor": scale, "runs": benchRuns},
    %*{"nanuq in-memory": nimMemory, "nanuq streaming": nimStreaming,
       "python in-memory": pyMemory, "python streaming": pyStreaming})

# --- Results ----------------------------------------------------------------------
nbText: """
## Results

One table per run of the full benchmark on someone's machine: for each query, the best of
the timed runs, in seconds, reading the CSV files included. A dash means the run did not
use that engine: older runs timed Nanuq with one engine only, and runs with Nanuq 0.2 have
13 queries, so compare totals only between runs with the same number of queries.
"""

nbText: ""  # the tables, filled in below from the Polars query
let summary = nb.blk.NbText

nbText: """
## How the tables are made

Each run of the full benchmark leaves a JSON file in
[`results/pdsh/`](https://github.com/pietroppeter/nanuq-book/tree/main/results/pdsh), with
the machine, the versions and, for each engine and query, three timings. The tables above
are a Polars query over those files, so they come from the same tools as everything else
in this book.

The timings are two structs deep: engines, then queries. Two rounds of `unnest` and
`unpivot` turn each file into a long table with one row per engine and query, and
`list.min` keeps the best of the timed runs:
"""

tabs """
import glob
import polars as pl

index = ["date", "machine", "cpu", "nanuq", "scale"]


def timings(path):
    return (
        pl.read_json(path)
        .select(
            pl.col("timestamp").str.slice(0, 10).alias("date"),
            pl.col("label").alias("machine"),
            pl.col("system").struct.field("cpu"),
            pl.col("versions").struct.field("nanuqWrapper").alias("nanuq"),
            pl.col("params").struct.field("scaleFactor").alias("scale"),
            "timings",
        )
        .unnest("timings")
        .unpivot(index=index, variable_name="engine", value_name="queries")
        .unnest("queries")
        .unpivot(index=[*index, "engine"], variable_name="query", value_name="seconds")
    )


times = pl.concat(
    [timings(path) for path in sorted(glob.glob("../results/pdsh/*.json"))]
).with_columns(pl.col("seconds").list.min())
times.head(3)
""":
  nbCode:
    let index = @["date", "machine", "cpu", "nanuq", "scale"]

    proc timings(path: string): DataFrame =
      readJson(path)
        .select(
          col.timestamp.str.slice(0, 10).alias("date"),
          col.label.alias("machine"),
          col.system.struct.field("cpu"),
          col.versions.struct.field("nanuqWrapper").alias("nanuq"),
          col.params.struct.field("scaleFactor").alias("scale"),
          col.timings)
        .unnest("timings")
        .unpivot(index = index, variableName = "engine", valueName = "queries")
        .unnest("queries")
        .unpivot(index = index & "engine", variableName = "query", valueName = "seconds")

    let paths = sorted(toSeq(walkFiles("../results/pdsh/*.json")))
    let times = concat(paths.mapIt(timings(it)), how = ConcatMethod.Vertical)
      .withColumns(col.seconds.list.min)
    nbShow times.head(3)

nbText: """
Summing per run and engine, and a `pivot` with one column per engine, gives the total time
of each run:
"""

tabs """
(
    times.group_by([*index, "engine"], maintain_order=True)
    .agg(pl.len().alias("queries"), pl.col("seconds").sum().round(2))
    .pivot(on="engine", index=[*index, "queries"], values="seconds", sort_columns=True)
)
""":
  nbCode:
    nbShow times
      .groupBy(index & "engine", maintainOrder = true)
      .agg(len().alias("queries"), col.seconds.sum.round(2))
      .pivot(on = "engine", index = index & "queries", values = "seconds", sortColumns = true)

nbText: """
And query by query, on the latest run on an M3 Pro:
"""

tabs """
pl.Config.set_tbl_rows(22)  # the default shows 10 rows

(
    times.filter(pl.col("machine") == "pietro-mac")
    .filter(pl.col("date") == pl.col("date").max())
    .with_columns(pl.col("seconds").round(3))
    .pivot(on="engine", index="query", values="seconds", sort_columns=True)
)
""":
  nbCode:
    let byQuery = times
      .filter(col.machine == "pietro-mac")
      .filter(col.date == col.date.max)
      .withColumns(col.seconds.round(3))
      .pivot(on = "engine", index = "query", values = "seconds", sortColumns = true)
  nbRawHtml: byQuery.toHtml(maxRows = 22)  # the default shows 10 rows

discard runPython("pl.Config.set_tbl_rows(10)")

const engines = ["nanuq in-memory", "nanuq streaming", "python in-memory", "python streaming"]

proc runTable(date, machine: string): string =
  ## The table of one run: every engine, a row per query and a row of totals.
  let cells = engines.mapIt(col.seconds.filter(col.engine == it).first.alias(it))
  let run = times.filter(col.date == date and col.machine == machine)
    .groupBy("query", maintainOrder = true).agg(cells)
  # mean * count, not sum, which gives 0 for an engine the run did not use
  let totals = run.select(@[lit("total").alias("query")] &
    engines.mapIt((col(it).mean * col(it).count).alias(it)))
  markdownTable(concat([run, totals]), boldLast = true)

for path in paths:
  let run = readJson(path).select(
    col.timestamp.str.slice(0, 10).alias("date"),
    col.label.alias("machine"),
    col.params.struct.field("scaleFactor").alias("scale"),
    format("{}, {} cores, {} GB, {}. Nanuq {}, Polars {}, Nim {}.",
           col.system.struct.field("cpu"), col.system.struct.field("cores"),
           col.system.struct.field("memoryGB"), col.system.struct.field("os"),
           col.versions.struct.field("nanuqWrapper"),
           col.versions.struct.field("pythonPolars"),
           col.versions.struct.field("nim")).alias("about"))
  let (date, machine) = (run["date", 0, string], run["machine", 0, string])
  summary.text.add "### " & date & " (" & machine & "), scale factor " &
    $run["scale", 0, float] & "\n\n" & run["about", 0, string] & "\n\n" &
    runTable(date, machine) & "\n"

nbText: """
## The benchmark

[TPC-H](https://www.tpc.org/tpch/) is the classic decision-support benchmark: eight
tables of a wholesale business (orders, line items, customers, suppliers, parts and the
nations and regions they are in) and 22 queries that report on them. Polars publishes
how fast it runs them as [PDS-H](https://pola.rs/posts/benchmarks/), with its queries in
the polars-benchmark repository.

Nanuq 0.3 runs all 22. (Nanuq 0.2 ran 13 of them: the others need string functions or
the year of a date, which came with 0.3.)
"""

nanuq """
The Python queries are the originals, unchanged; both sides read the CSV files with
`tryParseDates`, so the date columns are dates. In Nim, Python's `date(1995, 3, 15)` is
Nanuq's `date(1995, 3, 15)`, column names that Python passes as strings are `col(...)`,
keys are lists, `pl.len()` is the length of a column and `when/then/otherwise` is
`choose`. One query takes a detour for an expression Nanuq does not have yet: q20 takes the
unique keys with the frame's `unique` (no `Expr.unique`).
"""

nbText: """
The queries are in [`bench/pdsh.nim`](https://github.com/pietroppeter/nanuq-book/blob/main/bench/pdsh.nim)
and [`bench/pdsh.py`](https://github.com/pietroppeter/nanuq-book/blob/main/bench/pdsh.py).
When the book is built, each one runs on both sides on a small dataset (scale factor
0.01, about 10 MB of CSV), and the build checks that the two tables are the same.
"""

let nimSource = readFile(".." / "bench" / "pdsh.nim")
let pySource = readFile(".." / "bench" / "pdsh.py")

block:
  let dir = tpchData("0.01")
  let tables = scanTables(dir)
  loadPython(dir)
  for (n, run) in queries(0.01):
    nbText: "## Q" & $n
    let nimSrc = sourcePart(nimSource, "proc q" & $n & "*", ["\nproc "])
    let pySrc = sourcePart(pySource, "def q" & $n & "(", ["\n\n\ndef "])
    nbRawHtml: queryTabs(nimSrc, pySrc, run(tables).collect, pyCall(n, 0.01))

nbText: """
## Running it on your machine

From the root of a clone of the book, with Nim, nimble, uv and git (the script
installs the book's dependencies first; the data goes to
`bench-data/`, which git ignores; scale factor 1 is about 1 GB of CSV):

```sh
scripts/bench pdsh                          # scale factor 1, 3 timed runs per query
scripts/bench pdsh -d:benchScale=10         # scale factor 10
scripts/bench pdsh -d:benchLabel=my-laptop  # a name for your machine
```

It writes the timings and the machine's specs to a timestamped file in `results/pdsh/`
and commits it; a pull request with that file adds a run to the tables at the top.
"""

bookSave()
