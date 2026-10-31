import nanuq, nanuqbook, benchkit, onebrc
import std/[os, json, strutils]
bookInit()

const benchRows {.intdefine.} = 1_000_000_000  ## rows of a full run (`-d:benchRows=...`)

nbText: "# One Billion Row Challenge"

nanuq """
**About this chapter.** The [One Billion Row Challenge](https://github.com/gunnarmorling/1brc)
is Gunnar Morling's, licensed under the
[Apache License 2.0](https://github.com/pietroppeter/nanuq-book/blob/main/licenses/1brc-Apache-2.0.txt).
The 413 weather stations in `data/1brc/weather_stations.csv` and the way the data is made
come from its generator, `CreateMeasurements.java`; the text and the code here are the
book's own.
"""

nbText: """
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
timings below show how close it gets to Python Polars.

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

let stations = ".." / "data" / "1brc" / "weather_stations.csv"
createDir "data/1brc"
generate(stations, "data/1brc/sample.txt", 10_000)
discard runPython("import sys\nsys.path.insert(0, '../bench')\nfrom onebrc import onebrc")

tabs """
onebrc("data/1brc/sample.txt").collect().head(10)
""":
  nbCode:
    let sample = onebrc("data/1brc/sample.txt").collect.head(10)
    nbShow sample

nanuq """
Python reads the file with a schema, which names the columns too; Nanuq's `scanCsv` has no
such option yet, so it names them with `rename`. Nanuq also has no streaming engine yet, so
it only runs Polars' in-memory engine. The Python side is timed with both engines.
"""

# --- A full run: only with -d:bench -------------------------------------------------
when defined(bench):
  let dataDir = ".." / "bench-data"
  createDir dataDir
  let measurements = dataDir / "measurements-" & $benchRows & ".txt"
  if not fileExists(measurements):
    echo "[bench] generating ", benchRows, " rows in ", measurements
    generate(stations, measurements, benchRows)
  echo "[bench] timing Nanuq"
  let nimTimes = timeIt(benchRuns, proc () = discard onebrc(measurements).collect)
  echo "[bench] timing Python Polars"
  let pyMemory = timePython(benchRuns, "onebrc(" & escapeJson(measurements) & ").collect(engine='in-memory')")
  let pyStreaming = timePython(benchRuns, "onebrc(" & escapeJson(measurements) & ").collect(engine='streaming')")
  discard saveResult("1brc", %*{"rows": benchRows, "runs": benchRuns},
    %*{"nanuq": nimTimes, "python in-memory": pyMemory, "python streaming": pyStreaming})

# --- Results ----------------------------------------------------------------------
nbText: """
## Results

Each row is one run of the full benchmark on someone's machine; the times are the best of
the timed runs, in seconds, reading the file included.
"""

proc resultsTable(): string =
  let results = loadResults("1brc")
  if results.len == 0:
    return "No results yet."
  result = "| Date | Machine | Rows | Nanuq | Python in-memory | Python streaming | Versions |\n" &
           "| ---- | ------- | ---: | ----: | ---------------: | ---------------: | -------- |\n"
  for r in results:
    let t = r["timings"]
    let v = r["versions"]
    var who = r["timestamp"].getStr[0 .. 9]
    if r["label"].getStr.len > 0: who.add " (" & r["label"].getStr & ")"
    result.add "| " & who & " | " & machine(r) & " | " &
      insertSep($r["params"]["rows"].getInt, ',') & " | " &
      seconds(best(t["nanuq"])) & " | " & seconds(best(t["python in-memory"])) & " | " &
      seconds(best(t["python streaming"])) & " | Nanuq " & v["nanuqWrapper"].getStr &
      ", Polars " & v["pythonPolars"].getStr & ", Nim " & v["nim"].getStr & " |\n"

nbText: resultsTable()

nbText: """
## Running it on your machine

From the root of a clone of the book, with Nim (and nimble), uv and git (the script
installs the book's dependencies first) (it generates the data the first
time, about 13 GB for one billion rows, in `bench-data/`, which git ignores):

```sh
scripts/bench 1brc                          # one billion rows, 3 timed runs
scripts/bench 1brc -d:benchRows=100000000   # fewer rows
scripts/bench 1brc -d:benchLabel=my-laptop  # a name for your machine
```

It writes the timings and the machine's specs to a timestamped file in `results/1brc/` and
commits it; a pull request with that file adds a row to the table above.
"""

bookSave()
