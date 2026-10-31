## Helpers for the benchmark chapters.
##
## A benchmark chapter builds in two ways:
## - normally (`nimble genbook`, CI): it runs its queries on a small sample, to check
##   that Nim and Python agree, and shows every result file in `results/<bench>/`;
## - with `-d:bench` (`scripts/bench <bench>`, on your machine): it first runs the
##   benchmark at full size, times the Nim and the Python queries, writes a timestamped
##   JSON file with the timings and the machine's specs to `results/<bench>/`, and
##   commits it.
import std/[json, os, osproc, strutils, times, monotimes, algorithm, sequtils, math]
import nanuq
import nanuqbook

const
  benchRuns* {.intdefine.} = 3        ## timed runs of each query (the best one counts)
  benchLabel* {.strdefine.} = ""      ## a name for the machine, such as "pietro-mac"

proc resultsDir*(bench: string): string =
  ## results/<bench>, seen from the chapter's working directory (docs/).
  ".." / "results" / bench

proc cmd(c: string): string =
  try:
    let (o, code) = execCmdEx(c)
    if code == 0: o.strip else: ""
  except OSError: ""

proc systemInfo*(): JsonNode =
  ## The machine the benchmark runs on.
  var cpu, memBytes: string
  when defined(macosx):
    cpu = cmd("sysctl -n machdep.cpu.brand_string")
    memBytes = cmd("sysctl -n hw.memsize")
  else:
    for line in cmd("cat /proc/cpuinfo").splitLines:
      if line.startsWith("model name"):
        cpu = line.split(':', 1)[1].strip
        break
    for line in cmd("cat /proc/meminfo").splitLines:
      if line.startsWith("MemTotal:"):
        memBytes = $(parseInt(line.splitWhitespace[1]) * 1024)
  let memGb = if memBytes.len > 0: round(parseFloat(memBytes) / 1e9, 1) else: 0.0
  var osName = cmd("uname -sr")
  when defined(macosx):
    osName = "macOS " & cmd("sw_vers -productVersion")
  %*{"os": osName, "arch": hostCPU, "cpu": cpu, "cores": countProcessors(),
     "memoryGB": memGb}

proc timeIt*(runs: int, body: proc ()): seq[float] =
  ## Seconds taken by each of `runs` runs of `body`.
  for _ in 1 .. runs:
    let start = getMonoTime()
    body()
    result.add (getMonoTime() - start).inNanoseconds.float / 1e9

proc timePython*(runs: int, call: string): seq[float] =
  ## Seconds taken by each of `runs` runs of the Python expression `call`, in the
  ## chapter's Python session.
  let (printed, _) = runPython("""
import time as _time
_times = []
for _ in range(""" & $runs & """):
    _start = _time.perf_counter()
    """ & call & """

    _times.append(_time.perf_counter() - _start)
print(" ".join(repr(t) for t in _times))
""")
  printed.splitWhitespace.mapIt(parseFloat(it))

proc pythonVersions*(): JsonNode =
  let (printed, _) = runPython("""
import platform as _platform, polars as _pl
print(_platform.python_version(), _pl.__version__)
""")
  let v = printed.splitWhitespace
  %*{"python": v[0], "pythonPolars": v[1]}

proc saveResult*(bench: string, params, timings: JsonNode): string =
  ## Writes results/<bench>/<timestamp>[-<label>].json and commits it. Returns its path.
  let now = now().utc
  var versions = %*{"nim": NimVersion, "nanuqWrapper": polarsWrapperVersion()}
  for k, v in pythonVersions(): versions[k] = v
  let data = %*{"benchmark": bench, "timestamp": now.format("yyyy-MM-dd'T'HH:mm:ss'Z'"),
                "label": benchLabel, "params": params, "system": systemInfo(),
                "versions": versions, "timings": timings}
  createDir resultsDir(bench)
  var name = now.format("yyyyMMdd'T'HHmmss'Z'")
  if benchLabel.len > 0: name.add "-" & benchLabel
  result = resultsDir(bench) / name & ".json"
  writeFile result, data.pretty & "\n"
  echo "[bench] wrote ", result
  let (o, code) = execCmdEx("git add " & quoteShell(result) & " && git commit -q -m " &
    quoteShell("Benchmark result: " & bench & " " & name) & " -- " & quoteShell(result))
  if code == 0: echo "[bench] committed ", result
  else: echo "[bench] could not commit ", result, ":\n", o

proc loadResults*(bench: string): seq[JsonNode] =
  ## Every result file of `bench`, oldest first.
  for f in walkFiles(resultsDir(bench) / "*.json"):
    result.add parseFile(f)
  result.sort(proc (a, b: JsonNode): int = cmp(a["timestamp"].getStr, b["timestamp"].getStr))

proc best*(times: JsonNode): float =
  times.getElems.mapIt(it.getFloat).min

proc seconds*(x: float): string = formatFloat(x, ffDecimal, 2) & " s"

proc machine*(r: JsonNode): string =
  ## One line about the machine of a result.
  let s = r["system"]
  result = s["cpu"].getStr
  if result.len == 0: result = s["arch"].getStr
  result.add ", " & $s["cores"].getInt & " cores, " & $s["memoryGB"].getFloat & " GB, " &
    s["os"].getStr
