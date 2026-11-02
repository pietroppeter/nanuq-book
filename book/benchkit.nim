## Helpers for the benchmark chapters.
##
## A benchmark chapter builds in two ways:
## - normally (`nimble genbook`, CI): it runs its queries on a small sample, to check
##   that Nim and Python agree, and shows every result file in `results/<bench>/`,
##   as a Nanuq query over those files;
## - with `-d:bench` (`scripts/bench <bench>`, on your machine): it first runs the
##   benchmark at full size, times the Nim and the Python queries, writes a timestamped
##   JSON file with the timings and the machine's specs to `results/<bench>/`, and
##   commits it.
import std/[json, options, os, osproc, strutils, times, monotimes, sequtils, math, xmltree]
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

proc markdownTable*(df: DataFrame, boldLast = false): string =
  ## `df` as a Markdown table, as readers want it: capitalised headers, seconds with two
  ## decimals, rows with separators, "-" for nulls. `boldLast` is for a row of totals.
  let names = df.columns
  result = "| " & names.mapIt(it.capitalizeAscii).join(" | ") & " |\n| " &
    names.mapIt(if df.dtype(it) == String: "---" else: "--:").join(" | ") & " |\n"
  for i in 0 ..< df.height:
    var cells: seq[string]
    for name in names:
      let dtype = df.dtype(name)
      var cell = "-"
      if dtype == Float64:
        let x = df[name, i, Option[float]]
        if x.isSome: cell = formatFloat(x.get, ffDecimal, 2) & " s"
      elif dtype == Int64:
        cell = insertSep($df[name, i, int], ',')
      else:
        cell = df[name, i, string]
      cells.add (if boldLast and i == df.height - 1 and cell != "-": "**" & cell & "**" else: cell)
    result.add "| " & cells.join(" | ") & " |\n"

proc queryTabs*(nimSrc, pySrc: string, nimFrame: DataFrame, pyCall: string): string =
  ## A query's Nim and Python source in tabs, each with the table it gives (the Python
  ## one from running `pyCall`); fails the build if the two tables differ.
  let nimSide = "<pre><code class=\"nim-file nohighlight nim hljs\">" &
    highlightNim(nimSrc.strip) & "</code></pre>" & nimFrame.toHtml
  let (_, pyShown) = runPython(pyCall)
  checkSameFrame(nimSide, pyShown, pyCall)
  tabsHtml(nimSide, "<pre><code class=\"language-python py-file hljs\">" &
    xmltree.escape(pySrc.strip) & "</code></pre>" & pyShown)

proc sourcePart*(source, start: string, stops: openArray[string]): string =
  ## The part of `source` from the line starting with `start` to the next `stops`.
  let i = source.find(start)
  doAssert i >= 0, "not found: " & start
  var j = source.len
  for s in stops:
    let k = source.find(s, i + start.len)
    if k >= 0 and k < j: j = k
  source[i ..< j].strip
