import nanuq, nanuqbook, benchkit, dbbench
import std/[os, json, strutils, sequtils]
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

let nimSource = readFile(".." / "bench" / "dbbench.nim")
let pySource = readFile(".." / "bench" / "dbbench.py")

proc pyKeys(keys: seq[string]): string = "[" & keys.mapIt(escapeJson(it)).join(", ") & "]"

block:
  let gfile = groupByFile(10_000)
  let jdir = joinDir(10_000)
  let x = scanGroupBy(gfile)
  let t = scanJoin(jdir)
  loadPython(gfile, jdir)
  nbText: "## Group-by"
  for q in groupQs:
    nbText: "### " & q.name & ": " & q.title
    let nimSrc = sourcePart(nimSource, "proc " & q.name & "*", ["\nproc ", "\n# ---"])
    let pySrc = sourcePart(pySource, "def " & q.name & "(", ["\n\n\ndef "])
    nbRawHtml: queryTabs(nimSrc, pySrc, q.run(x).collect.sort(q.keys),
                         q.name & "(_x).collect().sort(" & pyKeys(q.keys) & ")")
  nbText: "## Join"
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

# --- A full run: only with -d:bench -------------------------------------------------
when defined(bench):
  let gfile = groupByFile(benchRows)
  let jdir = joinDir(benchRows)
  let x = scanGroupBy(gfile)
  let t = scanJoin(jdir)
  loadPython(gfile, jdir)
  var nimTimes, pyMemory, pyStreaming = newJObject()
  for q in groupQs:
    echo "[bench] ", q.name
    nimTimes[q.name] = %timeIt(benchRuns, proc () = discard q.run(x).collect)
    pyMemory[q.name] = %timePython(benchRuns, q.name & "(_x).collect(engine='in-memory')")
    pyStreaming[q.name] = %timePython(benchRuns, q.name & "(_x).collect(engine='streaming')")
  for q in joinQs:
    echo "[bench] ", q.name
    nimTimes[q.name] = %timeIt(benchRuns, proc () = discard q.run(t).collect)
    pyMemory[q.name] = %timePython(benchRuns, q.name & "(_t).collect(engine='in-memory')")
    pyStreaming[q.name] = %timePython(benchRuns, q.name & "(_t).collect(engine='streaming')")
  discard saveResult("dbbench", %*{"rows": benchRows, "groups": benchGroups, "runs": benchRuns},
    %*{"nanuq": nimTimes, "python in-memory": pyMemory, "python streaming": pyStreaming})

# --- Results ----------------------------------------------------------------------
nbText: """
## Results

One table per run of the full benchmark on someone's machine: for each question, the best of
the timed runs, in seconds, reading the CSV files included.
"""

proc resultsTables(): string =
  let results = loadResults("dbbench")
  if results.len == 0:
    return "No results yet: the first full run will add a table here."
  for r in results:
    let t = r["timings"]
    let v = r["versions"]
    var title = r["timestamp"].getStr[0 .. 9]
    if r["label"].getStr.len > 0: title.add " (" & r["label"].getStr & ")"
    result.add "### " & title & ", " & insertSep($r["params"]["rows"].getInt, ',') &
      " rows\n\n" & machine(r) & ". Nanuq " & v["nanuqWrapper"].getStr & ", Polars " &
      v["pythonPolars"].getStr & ", Nim " & v["nim"].getStr & ".\n\n" &
      "| Question | Nanuq | Python in-memory | Python streaming |\n" &
      "| -------- | ----: | ---------------: | ---------------: |\n"
    for q, _ in t["nanuq"]:
      let row = [best(t["nanuq"][q]), best(t["python in-memory"][q]),
                 best(t["python streaming"][q])]
      result.add "| " & q & " | " & row.mapIt(seconds(it)).join(" | ") & " |\n"
    result.add "\n"

nbText: resultsTables()

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
and commits it; a pull request with that file adds a table above.
"""

bookSave()
