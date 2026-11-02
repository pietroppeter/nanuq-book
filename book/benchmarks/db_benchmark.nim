import nanuq, nanuqbook, benchkit, dbbench
import std/[algorithm, os, json, strutils, sequtils]
bookInit()

const
  benchRows {.intdefine.} = 10_000_000  ## rows of a full run (`-d:benchRows=...`)
  benchGroups {.intdefine.} = 100       ## K, the number of groups of id1, id2, id4, id5

nbText: "# Group-by and join (db-benchmark)"

nanuq """
**About this chapter.** The questions are ported from the Polars scripts of
[db-benchmark](https://github.com/duckdblabs/db-benchmark) (started by H2O.ai, now kept by
DuckDB Labs), licensed under the
[Mozilla Public License 2.0](https://github.com/pietroppeter/nanuq-book/blob/main/licenses/db-benchmark-MPL-2.0.txt).
The data generators in `bench/dbbench.nim` follow its R scripts (`groupby-datagen.R` and
`join-datagen.R`), with Nim's random numbers, so the values differ from the R ones. The data
is made on the fly and never stored in the repository. The text is the book's own.
"""

type
  GroupQ = tuple[name, title: string, keys: seq[string], run: proc (x: LazyFrame): LazyFrame]
  JoinQ = tuple[name, title: string, run: proc (t: JoinTables): LazyFrame]

let groupQs: seq[GroupQ] = @[
  ("g1", "sum v1 by id1", @["id1"], g1),
  ("g2", "sum v1 by id1:id2", @["id1", "id2"], g2),
  ("g3", "sum v1 mean v3 by id3", @["id3"], g3),
  ("g4", "mean v1:v3 by id4", @["id4"], g4),
  ("g5", "sum v1:v3 by id6", @["id6"], g5),
  ("g6", "median v3 sd v3 by id4 id5", @["id4", "id5"], g6),
  ("g7", "max v1 - min v2 by id3", @["id3"], g7),
  ("g8", "largest two v3 by id6", @["id6", "largest2_v3"], g8),
  ("g9", "regression v1 v2 by id2 id4", @["id2", "id4"], g9),
  ("g10", "sum v3 count by id1:id6", @["id1", "id2", "id3", "id4", "id5", "id6"], g10)]

let joinQs: seq[JoinQ] = @[
  ("j1", "small inner on int", j1),
  ("j2", "medium inner on int", j2),
  ("j3", "medium outer on int", j3),
  ("j4", "medium inner on factor", j4),
  ("j5", "big inner on int", j5)]

proc groupByFile(rows: int): string =
  result = ".." / "bench-data" / "dbbench" / "G1_" & $rows & "_" & $benchGroups & ".csv"
  if not fileExists(result):
    createDir result.parentDir
    generateGroupBy(result, rows, benchGroups)

proc joinDir(rows: int): string =
  result = ".." / "bench-data" / "dbbench" / "J1_" & $rows
  if not fileExists(result / "big.csv"):
    generateJoin(result, rows)

proc loadPython(gfile, jdir: string) =
  discard runPython("import sys\nsys.path.insert(0, '../bench')\nfrom dbbench import *\n" &
                    "_x = scan_groupby(" & escapeJson(gfile) & ")\n" &
                    "_t = scan_join(" & escapeJson(jdir) & ")")

# --- A full run: only with -d:bench -------------------------------------------------
when defined(bench):
  let gfile = groupByFile(benchRows)
  let jdir = joinDir(benchRows)
  let x = scanGroupBy(gfile)
  let t = scanJoin(jdir)
  loadPython(gfile, jdir)
  var nimMemory, nimStreaming, pyMemory, pyStreaming = newJObject()
  for q in groupQs:
    echo "[bench] ", q.name
    nimMemory[q.name] = %timeIt(benchRuns, proc () = discard q.run(x).collect(Engine.InMemory))
    nimStreaming[q.name] = %timeIt(benchRuns, proc () = discard q.run(x).collect(Engine.Streaming))
    pyMemory[q.name] = %timePython(benchRuns, q.name & "(_x).collect(engine='in-memory')")
    pyStreaming[q.name] = %timePython(benchRuns, q.name & "(_x).collect(engine='streaming')")
  for q in joinQs:
    echo "[bench] ", q.name
    nimMemory[q.name] = %timeIt(benchRuns, proc () = discard q.run(t).collect(Engine.InMemory))
    nimStreaming[q.name] = %timeIt(benchRuns, proc () = discard q.run(t).collect(Engine.Streaming))
    pyMemory[q.name] = %timePython(benchRuns, q.name & "(_t).collect(engine='in-memory')")
    pyStreaming[q.name] = %timePython(benchRuns, q.name & "(_t).collect(engine='streaming')")
  discard saveResult("dbbench", %*{"rows": benchRows, "groups": benchGroups, "runs": benchRuns},
    %*{"nanuq in-memory": nimMemory, "nanuq streaming": nimStreaming,
       "python in-memory": pyMemory, "python streaming": pyStreaming})

# --- Results ----------------------------------------------------------------------
nbText: """
## Results

Each run of the full benchmark leaves a JSON file in
[`results/dbbench/`](https://github.com/pietroppeter/nanuq-book/tree/main/results/dbbench),
with the machine, the versions and, for each engine and question, three timings. The tables
below are a Polars query over those files (`run` is when it started, in UTC), as in the other benchmark chapters: two rounds
of `unnest` and `unpivot` give one row per engine and question, and `list.min` keeps the
best of the timed runs.
"""

tabs """
import glob
import polars as pl

index = ["run", "machine", "cpu", "nanuq", "rows"]


def timings(path):
    return (
        pl.read_json(path)
        .select(
            pl.col("timestamp").str.slice(0, 16).alias("run"),
            pl.col("label").alias("machine"),
            pl.col("system").struct.field("cpu"),
            pl.col("versions").struct.field("nanuqWrapper").alias("nanuq"),
            pl.col("params").struct.field("rows"),
            "timings",
        )
        .unnest("timings")
        .unpivot(index=index, variable_name="engine", value_name="questions")
        .unnest("questions")
        .unpivot(index=[*index, "engine"], variable_name="question", value_name="seconds")
    )


times = pl.concat(
    [timings(path) for path in sorted(glob.glob("../results/dbbench/*.json"))]
).with_columns(pl.col("seconds").list.min())
times.head(3)
""":
  nbCode:
    let index = @["run", "machine", "cpu", "nanuq", "rows"]

    proc timings(path: string): DataFrame =
      readJson(path)
        .select(
          col.timestamp.str.slice(0, 16).alias("run"),
          col.label.alias("machine"),
          col.system.struct.field("cpu"),
          col.versions.struct.field("nanuqWrapper").alias("nanuq"),
          col.params.struct.field("rows"),
          col.timings)
        .unnest("timings")
        .unpivot(index = index, variableName = "engine", valueName = "questions")
        .unnest("questions")
        .unpivot(index = index & "engine", variableName = "question", valueName = "seconds")

    let times = concat(sorted(toSeq(walkFiles("../results/dbbench/*.json"))).mapIt(timings(it)),
                       how = ConcatMethod.Vertical)
      .withColumns(col.seconds.list.min)
    nbShow times.head(3)

nbText: """
The total time of each run, one column per engine:
"""

tabs """
(
    times.group_by([*index, "engine"], maintain_order=True)
    .agg(pl.col("seconds").sum().round(2))
    .pivot(on="engine", index=index, values="seconds", sort_columns=True)
)
""":
  nbCode:
    nbShow times
      .groupBy(index & "engine", maintainOrder = true)
      .agg(col.seconds.sum.round(2))
      .pivot(on = "engine", index = index, values = "seconds", sortColumns = true)

nbText: """
And question by question, on the latest run:
"""

tabs """
pl.Config.set_tbl_rows(15)  # the default shows 10 rows

(
    times.filter(pl.col("run") == pl.col("run").max())
    .with_columns(pl.col("seconds").round(3))
    .pivot(on="engine", index="question", values="seconds", sort_columns=True)
)
""":
  nbCode:
    let byQuestion = times
      .filter(col.run == col.run.max)
      .withColumns(col.seconds.round(3))
      .pivot(on = "engine", index = "question", values = "seconds", sortColumns = true)
  nbRawHtml: byQuestion.toHtml(maxRows = 15)  # the default shows 10 rows

discard runPython("pl.Config.set_tbl_rows(10)")

nanuq """
Timings are in seconds, reading the CSV files included.
"""

nbText: "## The benchmark"

nbText: """
[db-benchmark](https://duckdblabs.github.io/db-benchmark/) times dataframe libraries and
databases on two tasks: ten group-by questions on a table of 10 million to 1 billion rows,
and five joins. It is the benchmark where Polars first made its name, in 2021, and it is
still run on every new version of the tools it covers.

The group-by table has six id columns of different kinds and sizes and three values:

| column | what | groups |
| ------ | ---- | ------ |
| `id1`, `id2` | strings `id001`… | K (100) |
| `id3` | strings `id0000000001`… | N/K |
| `id4`, `id5` | integers | K |
| `id6` | integers | N/K |
| `v1`, `v2` | integers in 1–5 and 1–15 | |
| `v3` | a float in [0, 100) | |

The join tables are a left table `x` of N rows and three right tables of N/10⁶ (`small`), N/10³
(`medium`) and N rows (`big`), whose keys overlap 90% with `x`'s.
"""

nanuq """
As in db-benchmark's Polars scripts, both sides read the CSV files with the same schema
overrides and cast the string ids to `Categorical`. The scripts there first copy each table to
an Arrow IPC file and query that; here the queries scan the CSV files, so the timings include
reading them, as in the other benchmark chapters. Only the 10 million row, 100 group, no
missing values, unsorted variant is set up.
"""

nbText: """
The questions are in [`bench/dbbench.nim`](https://github.com/pietroppeter/nanuq-book/blob/main/bench/dbbench.nim)
and [`bench/dbbench.py`](https://github.com/pietroppeter/nanuq-book/blob/main/bench/dbbench.py).
When the book is built, each one runs on both sides on 10,000 rows, and the build checks that
the two tables are the same (sorted by their keys, so that the rows shown match).
"""

let nimSource = readFile(".." / "bench" / "dbbench.nim")
let pySource = readFile(".." / "bench" / "dbbench.py")

proc pyKeys(keys: seq[string]): string = "[" & keys.mapIt(escapeJson(it)).join(", ") & "]"

block:
  let gfile = groupByFile(10_000)
  let jdir = joinDir(10_000)
  let x = scanGroupBy(gfile)
  let t = scanJoin(jdir)
  loadPython(gfile, jdir)
  nbText: "## Group-by questions"
  for q in groupQs:
    nbText: "### " & q.name & ": " & q.title
    let nimSrc = sourcePart(nimSource, "proc " & q.name & "*", ["\nproc ", "\n# ---"])
    let pySrc = sourcePart(pySource, "def " & q.name & "(", ["\n\n\ndef "])
    nbRawHtml: queryTabs(nimSrc, pySrc, q.run(x).collect.sort(q.keys),
                         q.name & "(_x).collect().sort(" & pyKeys(q.keys) & ")")
  nbText: "## Join questions"
  for q in joinQs:
    nbText: "### " & q.name & ": " & q.title
    let nimSrc = sourcePart(nimSource, "proc " & q.name & "*", ["\nproc ", "\n# ---"])
    let pySrc = sourcePart(pySource, "def " & q.name & "(", ["\n\n\ndef "])
    nbRawHtml: queryTabs(nimSrc, pySrc, q.run(t).collect.sort(["id1", "id2", "id3"]),
                         q.name & "(_t).collect().sort(['id1', 'id2', 'id3'])")

nanuq """
Nanuq spells a few things differently: keys go in a list (`on = ["id1"]`), `pl.sum("v1")` is
`col.v1.sum`, `** 2` is `.pow(2)`, and Python's `method="pearson"` is Nanuq's default `how`.
"""

nbText: """
## Running it on your machine

From the root of a clone of the book, with Nim, nimble, uv and git (the script installs the
book's dependencies first; the data goes to `bench-data/`, which git ignores; 10 million rows
are about 0.5 GB of group-by CSV and 0.7 GB of join CSV):

```sh
scripts/bench dbbench                            # 10 million rows, 3 timed runs per question
scripts/bench dbbench -d:benchRows=100000000     # 100 million rows
scripts/bench dbbench -d:benchLabel=my-laptop    # a name for your machine
```

It writes the timings and the machine's specs to a timestamped file in `results/dbbench/`
and commits it; a pull request with that file adds a run to the tables at the top.
"""

bookSave()
