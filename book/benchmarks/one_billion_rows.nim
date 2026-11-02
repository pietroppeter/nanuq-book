import nanuq, nanuqbook, benchkit, onebrc
import std/[algorithm, os, json, sequtils, strutils]
bookInit()

const benchRows {.intdefine.} = 1_000_000_000  ## rows of a full run (`-d:benchRows=...`)
const benchInMemory {.booldefine.} = true  ## also time the in-memory engine (`-d:benchInMemory=false`)

nbText: "# One Billion Row Challenge"

nanuq """
**About this chapter.** The [One Billion Row Challenge](https://github.com/gunnarmorling/1brc)
is Gunnar Morling's, licensed under the
[Apache License 2.0](https://github.com/pietroppeter/nanuq-book/blob/main/licenses/1brc-Apache-2.0.txt).
The 413 weather stations in `data/1brc/weather_stations.csv` and the way the data is made
come from its generator, `CreateMeasurements.java`; the text and the code here are the
book's own.
"""

let stations = ".." / "data" / "1brc" / "weather_stations.csv"
discard runPython("import sys\nsys.path.insert(0, '../bench')\nfrom onebrc import onebrc")

# --- A full run: only with -d:bench -------------------------------------------------
when defined(bench):
  let dataDir = ".." / "bench-data"
  createDir dataDir
  let measurements = dataDir / "measurements-" & $benchRows & ".txt"
  if not fileExists(measurements):
    echo "[bench] generating ", benchRows, " rows in ", measurements
    generate(stations, measurements, benchRows)
  echo "[bench] timing Nanuq"
  var timings = newJObject()
  if benchInMemory:
    timings["nanuq in-memory"] = %timeIt(benchRuns, proc () = discard onebrc(measurements).collect(Engine.InMemory))
  timings["nanuq streaming"] = %timeIt(benchRuns, proc () = discard onebrc(measurements).collect(Engine.Streaming))
  echo "[bench] timing Python Polars"
  if benchInMemory:
    timings["python in-memory"] = %timePython(benchRuns, "onebrc(" & escapeJson(measurements) & ").collect(engine='in-memory')")
  timings["python streaming"] = %timePython(benchRuns, "onebrc(" & escapeJson(measurements) & ").collect(engine='streaming')")
  discard saveResult("1brc", %*{"rows": benchRows, "runs": benchRuns}, timings)

# --- Results ----------------------------------------------------------------------
nbText: """
## Results

Each run of the full benchmark leaves a JSON file in
[`results/1brc/`](https://github.com/pietroppeter/nanuq-book/tree/main/results/1brc), with
the machine, the versions and three timings per engine. The table below is a Polars query
over those files, so it is built like everything else in this book. The JSON nests the
timings in a struct, so `unnest` makes each engine a column; runs that skipped an engine
have no such column, so a diagonal `concat` fills it with nulls.
"""

tabs """
import glob
import polars as pl

runs = pl.concat(
    [pl.read_json(path).unnest("timings") for path in sorted(glob.glob("../results/1brc/*.json"))],
    how="diagonal",
)
""":
  nbCode:
    let runs = concat(
      sorted(toSeq(walkFiles("../results/1brc/*.json"))).mapIt(readJson(it).unnest("timings")),
      how = ConcatMethod.Diagonal)

nbText: """
Each timing is a list of runs, and the best one counts: `list.min` takes it, for all four
columns at once. Struct fields become columns of their own, and the last column is the
gain from streaming, in Nanuq.
"""

tabs """
engines = ["nanuq in-memory", "nanuq streaming", "python in-memory", "python streaming"]

runs.select(
    pl.col("timestamp").str.slice(0, 10).alias("date"),
    pl.col("label").alias("machine"),
    pl.col("system").struct.field("cpu"),
    pl.col("params").struct.field("rows"),
    pl.col("versions").struct.field("nanuqWrapper").alias("nanuq"),
    pl.col(engines).list.min().round(2),
).with_columns(
    (pl.col("nanuq in-memory") / pl.col("nanuq streaming")).round(1).alias("streaming gain")
)
""":
  nbCode:
    let engines = ["nanuq in-memory", "nanuq streaming", "python in-memory", "python streaming"]

    let table = runs.select(
      col.timestamp.str.slice(0, 10).alias("date"),
      col.label.alias("machine"),
      col.system.struct.field("cpu"),
      col.params.struct.field("rows"),
      col.versions.struct.field("nanuqWrapper").alias("nanuq"),
      col(engines).list.min.round(2)
    ).withColumns(
      (col("nanuq in-memory") / col("nanuq streaming")).round(1).alias("streaming gain"))
    nbShow table

nanuq """
Timings are in seconds, reading the file included. A null means the run did not use that
engine: older runs timed Nanuq with one engine only, and the in-memory engine needs too
much memory for one billion rows on a laptop.
"""

nbText: """
## The challenge

The challenge, from January 2024: a text file has one billion lines, each with a weather
station and a temperature, separated by a semicolon:

```text
Hamburg;12.0
Bulawayo;8.9
Palembang;38.8
Hamburg;34.2
```

Compute the minimum, mean and maximum temperature of each station, sorted by station, as
fast as possible. The challenge was for Java, but the answer in Polars is a single lazy
query, and it is one of the best-known Polars examples. Nanuq runs the same engine, so the
timings above show how close it gets to Python Polars.

## The query

Here are the two queries, Nim and Python, as they are in the book's repository:
"""

nbRawHtml: fileTabs("../bench/onebrc.nim", "../bench/onebrc.py")

nbText: """
The data is made by `generate`, which follows the challenge's generator: each line is a
random station, and a temperature drawn from a normal distribution around the station's
mean, with a standard deviation of 10 degrees and one decimal.

## A small run

When the book is built, the query runs on a sample of 10,000 rows, on both sides:
"""

createDir "data/1brc"
generate(stations, "data/1brc/sample.txt", 10_000)
tabs """
onebrc("data/1brc/sample.txt").collect().head(10)
""":
  nbCode:
    let sample = onebrc("data/1brc/sample.txt").collect.head(10)
    nbShow sample

nanuq """
Python reads the file with a schema, which names the columns too; Nanuq's `scanCsv` has no
such option yet, so it names them with `rename`. Both sides are timed with both of Polars'
engines: Nanuq's `collect(Engine.InMemory)` and `collect(Engine.Streaming)` are Python's
`collect(engine="in-memory")` and `collect(engine="streaming")`.
"""

nbText: """
## Running it on your machine

From the root of a clone of the book, with Nim, nimble, uv and git (the script
installs the book's dependencies first; it generates the data the first
time, about 13 GB for one billion rows, in `bench-data/`, which git ignores):

```sh
scripts/bench 1brc                          # one billion rows, 3 timed runs
scripts/bench 1brc -d:benchRows=100000000   # fewer rows
scripts/bench 1brc -d:benchLabel=my-laptop  # a name for your machine
scripts/bench 1brc -d:benchInMemory=false   # streaming engine only
```

The in-memory engine needs far more memory than the streaming one: about 8 GB against
about 1.4 GB for 100 million rows, measured on Python. On a machine with less than about
100 GB of memory, run one billion rows with the streaming engine only.

It writes the timings and the machine's specs to a timestamped file in `results/1brc/` and
commits it; a pull request with that file adds a row to the table at the top.
"""

bookSave()
