import nanuq, nanuqbook, benchkit, pdsh
import std/[os, json, strutils, osproc, sequtils]
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

nbText: """
[TPC-H](https://www.tpc.org/tpch/) is the classic decision-support benchmark: eight
tables of a wholesale business (orders, line items, customers, suppliers, parts and the
nations and regions they are in) and 22 queries that report on them. Polars publishes
how fast it runs them as [PDS-H](https://pola.rs/posts/benchmarks/), with its queries in
the polars-benchmark repository.

Nanuq 0.2 can run 13 of the 22: q1, q3, q4, q5, q6, q10, q11, q12, q15, q17, q18, q19 and
q21. The others need string functions (q2, q9, q13, q14, q16, q20, q22) or the year of a
date (q7, q8), which come with Nanuq 0.3.
"""

nanuq """
Nanuq has no dates yet, so both sides read the dates as strings: ISO dates such as
`"1995-03-15"` sort in the same order as the dates, so comparing them gives the same
rows. The Python queries are the originals with `date(1995, 3, 15)` written as
`pl.lit("1995-03-15")` (a plain string in `is_between` would be a column name). In Nim, column names that Python passes as strings are `col(...)`, keys
are lists and `pl.len()` is the length of a column. q21 counts late suppliers with a
separate group-by and a join, since Nanuq has no `Expr.filter` yet.
"""

nbText: """
The queries are in [`bench/pdsh.nim`](https://github.com/pietroppeter/nanuq-book/blob/main/bench/pdsh.nim)
and [`bench/pdsh.py`](https://github.com/pietroppeter/nanuq-book/blob/main/bench/pdsh.py).
When the book is built, each one runs on both sides on a small dataset (scale factor
0.01, about 10 MB of CSV), and the build checks that the two tables are the same.
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
  @[(1, q1), (3, q3), (4, q4), (5, q5), (6, q6), (10, q10),
    (11, proc (t: Tables): LazyFrame = q11(t, scale)),
    (12, q12), (15, q15), (17, q17), (18, q18), (19, q19), (21, q21)]

proc pyCall(n: int, scale: float, engine = "in-memory"): string =
  "q" & $n & "(**_tables" & (if n == 11: ", scale_factor=" & $scale else: "") &
    ").collect(engine=" & escapeJson(engine) & ")"

proc loadPython(dir: string) =
  discard runPython("import sys\nsys.path.insert(0, '../bench')\nfrom pdsh import *\n" &
                    "_tables = scan_tables(" & escapeJson(dir) & ")")

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

# --- A full run: only with -d:bench -------------------------------------------------
when defined(bench):
  let scale = parseFloat(benchScale)
  let dir = tpchData(benchScale)
  let tables = scanTables(dir)
  loadPython(dir)
  var nimTimes, pyMemory, pyStreaming = newJObject()
  for (n, run) in queries(scale):
    let q = "q" & $n
    echo "[bench] ", q
    nimTimes[q] = %timeIt(benchRuns, proc () = discard run(tables).collect)
    pyMemory[q] = %timePython(benchRuns, pyCall(n, scale))
    pyStreaming[q] = %timePython(benchRuns, pyCall(n, scale, "streaming"))
  discard saveResult("pdsh", %*{"scaleFactor": scale, "runs": benchRuns},
    %*{"nanuq": nimTimes, "python in-memory": pyMemory, "python streaming": pyStreaming})

# --- Results ----------------------------------------------------------------------
nbText: """
## Results

One table per run of the full benchmark on someone's machine: for each query, the best
of the timed runs, in seconds, reading the CSV files included.
"""

proc resultsTables(): string =
  let results = loadResults("pdsh")
  if results.len == 0:
    return "No results yet."
  for r in results:
    let t = r["timings"]
    let v = r["versions"]
    var title = r["timestamp"].getStr[0 .. 9]
    if r["label"].getStr.len > 0: title.add " (" & r["label"].getStr & ")"
    result.add "### " & title & ", scale factor " & $r["params"]["scaleFactor"].getFloat & "\n\n" &
      machine(r) & ". Nanuq " & v["nanuqWrapper"].getStr & ", Polars " &
      v["pythonPolars"].getStr & ", Nim " & v["nim"].getStr & ".\n\n" &
      "| Query | Nanuq | Python in-memory | Python streaming |\n" &
      "| ----- | ----: | ---------------: | ---------------: |\n"
    var totals: array[3, float]
    for q, _ in t["nanuq"]:
      let row = [best(t["nanuq"][q]), best(t["python in-memory"][q]),
                 best(t["python streaming"][q])]
      for i in 0 .. 2: totals[i] += row[i]
      result.add "| " & q & " | " & row.mapIt(seconds(it)).join(" | ") & " |\n"
    result.add "| **total** | " & totals.mapIt("**" & seconds(it) & "**").join(" | ") & " |\n\n"

nbText: resultsTables()

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
and commits it; a pull request with that file adds a table above.
"""

bookSave()
