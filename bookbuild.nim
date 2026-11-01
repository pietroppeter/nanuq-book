## Incremental build of the Nanuq book.
##
## A chapter is compiled and run only when something it depends on changed. Running it
## writes its nimib document as JSON (nimib's JSON backend, `nb.doc.dump()`, see
## `bookSave` in book/nanuqbook.nim), next to the page in docs/. This program then adds
## a *build record* to that JSON: every file the chapter depended on, with its SHA1.
##
## - Compile time: Nim's own list, `depfiles` in the nimcache JSON of the chapter (the
##   chapter, book/nanuqbook.nim, config.nims, Nanuq's sources and lib checksums, the
##   stdlib, nimib, nimibook, nimpy...).
## - Run time: the files the chapter opened, traced with strace (Linux; Polars reads data
##   in Rust, where Nim sees nothing). Without strace the run-time inputs of the previous
##   record are kept.
## - Always: uv.lock, pyproject.toml and .python-version (the Python side of the tabs),
##   and the Nim version.
##
## Then a single pass renders every page of the book from the chapter JSONs, with the
## current theme and table of contents, plus the Markdown pages. Adding a chapter or
## changing the theme does not rerun any chapter.
##
## Usage: `uv run nimble genbook`, which runs, from the repo root and after `nbook.nim dump`,
##   nim r -d:release bookbuild.nim [--force] [--from:<site url>] [--jobs:N]
## `--from` (or BOOK_FROM) downloads the JSON of chapters that have none in docs/ from
## the published book, so CI starts from what is live. `--force` (or BOOK_FORCE=1)
## reruns every chapter.
import std/[os, osproc, json, strutils, sequtils, tables, sets, algorithm, strformat, times]
{.warning[Deprecated]: off.}  # std/sha1: the same SHA1 Nim writes in its depfiles
import std/sha1
{.warning[Deprecated]: on.}
import nanuqbook  # the theme of the pages
import nimibook/commands

const recordVersion = 1

type
  Chapter = object
    path: string        # relative to book/, e.g. user-guide/casting.nim
    jsonPath: string    # relative to the repo root, e.g. docs/user-guide/casting.json
    cacheDir: string    # nimcache/<path without extension>
    exe: string
    reason: string      # why it is rebuilt ("" = up to date)

let root = getCurrentDir()

proc rel(path: string): string =
  ## Repo files are recorded relative to the repo root; data the chapters read from
  ## docs/data is recorded as its source in data/ (genbook copies it).
  result = path
  if path.isAbsolute and path.startsWith(root & "/"):
    result = path.relativePath(root)
  if result.startsWith("docs/data/"):
    result = result["docs/".len .. ^1]

proc absPath(p: string): string =
  if p.isAbsolute: p else: root / p

proc gitIgnored(paths: seq[string]): HashSet[string] =
  ## The paths git ignores (generated: docs/, nimcache/, bench-data/, __pycache__...).
  if paths.len == 0: return
  let (output, _) = execCmdEx("git check-ignore --stdin", input = paths.join("\n") & "\n")
  for line in output.splitLines:
    if line.len > 0: result.incl line

var hashCache: Table[string, string]

proc fileHash(p: string): string =
  ## SHA1 of a file (as Nim writes it in depfiles), or of the sorted listing of a
  ## directory (without what git ignores); "" when it does not exist.
  let a = absPath(p)
  if a in hashCache: return hashCache[a]
  result =
    if fileExists(a): $secureHashFile(a)
    elif dirExists(a):
      var names: seq[string]
      for kind, f in walkDir(a, relative = true): names.add f
      let ignored = gitIgnored(names.mapIt(rel(a / it)))
      names = names.filterIt(rel(a / it) notin ignored)
      names.sort()
      "dir:" & $secureHash(names.join("\n"))
    else: ""
  hashCache[a] = result

proc nimVersion(): string =
  execProcess("nim", args = ["--version"], options = {poUsePath}).splitLines()[0].strip

let globalInputs = ["uv.lock", "pyproject.toml", ".python-version"]

proc staleReason(c: Chapter, nimVer: string): string =
  ## "" when the chapter's record still matches, else why it does not.
  if not fileExists(c.jsonPath): return "no previous build"
  let j = try: parseFile(c.jsonPath) except CatchableError: return "unreadable JSON"
  if not j.hasKey("build"): return "no build record"
  let b = j["build"]
  if b{"version"}.getInt != recordVersion: return "old record format"
  if b{"nim"}.getStr != nimVer: return "Nim version changed"
  for item in b{"inputs"}.getElems:
    let (p, h) = (item[0].getStr, item[1].getStr)
    if fileHash(p) != h: return "changed: " & p
  ""

proc traceInputs(trace: string): seq[string] =
  ## Files (and listed directories) inside the repo that the chapter read, from
  ## `strace -y` output: not the ones it wrote, nor what git ignores (outputs,
  ## caches, generated data).
  var read, written: seq[string]
  for line in lines(trace):
    let i = line.rfind("= ")
    if i < 0: continue
    let lt = line.find('<', i)
    let gt = line.rfind('>')
    if lt < 0 or gt <= lt: continue
    let p = rel(line[lt + 1 ..< gt])
    if p.isAbsolute or p in [".", ""]: continue
    if "O_WRONLY" in line or "O_RDWR" in line or "O_CREAT" in line: written.add p
    elif p notin read: read.add p
  let ignored = gitIgnored(read)
  read.filterIt(it notin ignored and it notin written and not it.startsWith(".git/") and it != ".git")

proc writeRecord(c: Chapter, nimVer: string, traced: seq[string], prevRuntime: seq[string]) =
  var inputs: seq[string]
  var seen: HashSet[string]
  proc add(p: string) =
    let r = rel(p)
    if r notin seen:
      seen.incl r
      inputs.add r
  for f in walkFiles(c.cacheDir / "*.json"):
    let nc = parseFile(f)
    for d in nc{"depfiles"}.getElems: add d[0].getStr
  let runtime = if traced.len > 0: traced else: prevRuntime
  for p in runtime: add p
  for p in globalInputs: add p
  var record = %*{"version": recordVersion, "nim": nimVer,
                  "built": now().utc.format("yyyy-MM-dd'T'HH:mm:ss'Z'"),
                  "runtime": runtime, "inputs": []}
  for p in inputs: record["inputs"].add %*[p, fileHash(p)]
  var j = parseFile(c.jsonPath)
  j["build"] = record
  writeFile(c.jsonPath, $j)

proc previousRuntime(c: Chapter): seq[string] =
  try:
    for p in parseFile(c.jsonPath)["build"]["runtime"].getElems: result.add p.getStr
  except CatchableError: discard

proc fetch(url, dest: string): bool =
  createDir(dest.parentDir)
  execCmd("curl -fsL --retry 2 -o " & quoteShell(dest) & " " & quoteShell(url)) == 0

proc runAll(cmds: seq[tuple[name, cmd: string]], jobs: int, logDir: string): Table[string, (int, string)] =
  ## Runs the commands, at most `jobs` at a time; exit code and output per name (the
  ## output goes through a file, so a chatty chapter never blocks on a full pipe).
  var i = 0
  var running: seq[(string, string, Process)]
  while i < cmds.len or running.len > 0:
    while i < cmds.len and running.len < jobs:
      let (name, cmd) = cmds[i]
      let log = logDir / name.changeFileExt("") & "." & $i & ".out"
      createDir log.parentDir
      echo "[bookbuild] ", cmd
      running.add (name, log, startProcess(cmd & " > " & quoteShell(log) & " 2>&1",
                                          options = {poEvalCommand}))
      inc i
    var k = 0
    while k < running.len:
      let (name, log, p) = running[k]
      if p.running:
        inc k
        continue
      result[name] = (p.peekExitCode, readFile(log))
      p.close
      removeFile log
      running.delete k
    sleep 20

# --- rendering --------------------------------------------------------------

proc renderChapter(path, jsonPath: string) =
  ## A page from its chapter's JSON: blocks and source as the chapter left them, the
  ## rest (theme, table of contents, previous/next) as the book is now.
  let saved = readFile(jsonPath).fromJson(NbDoc)
  nbInit(theme = useNanuqBook, thisFileRel = path)
  nb.doc.blocks = saved.blocks
  nb.doc.source = saved.source
  nb.doc.sourceFiles = saved.sourceFiles
  for key, value in saved.context:  # what the chapter itself added to the context
    if not nb.doc.context.hasKey(key): nb.doc.context[key] = value
  nbSave
  setCurrentDir nb.doc.initDir

proc main =
  var force = getEnv("BOOK_FORCE") in ["1", "true"]
  var fromUrl = getEnv("BOOK_FROM").strip(chars = {'/'}, leading = false)
  var jobs = 10  # as nimibook: Nim's front end is single-threaded, so more jobs than cores helps
  for kind, key, val in getopt():
    case key
    of "force": force = true
    of "from": fromUrl = val.strip(chars = {'/'}, leading = false)
    of "jobs": jobs = parseInt(val)
    else: discard

  let book = load("docs/book.json")
  let nimVer = nimVersion()
  let useStrace = findExe("strace").len > 0
  if not useStrace: echo "[bookbuild] no strace: run-time inputs come from the previous records"

  var chapters: seq[Chapter]
  for e in book.toc.entries:
    if e.isDraft or not e.path.endsWith(".nim"): continue
    let name = e.path.changeFileExt("")
    var c = Chapter(path: e.path, jsonPath: "docs" / name & ".json",
                    cacheDir: "nimcache" / name)
    c.exe = c.cacheDir / "chapter"
    if fromUrl.len > 0 and not fileExists(c.jsonPath):
      if fetch(fromUrl & "/" & name & ".json", c.jsonPath):
        echo "[bookbuild] fetched ", c.jsonPath
    c.reason = if force: "forced" else: staleReason(c, nimVer)
    chapters.add c

  let stale = chapters.filterIt(it.reason.len > 0)
  echo &"[bookbuild] {chapters.len - stale.len} of {chapters.len} chapters up to date"
  for c in stale: echo "[bookbuild] rebuild ", c.path, " (", c.reason, ")"

  # compile (Nim skips what is already compiled), then run, under strace if available
  var failed: seq[string]
  proc logFailure(c: Chapter, output: string) =
    failed.add c.path
    writeFile("book" / c.path.changeFileExt("log"), output)  # as nimibook does
    discard tryRemoveFile(c.jsonPath)  # never render an old page for a failing chapter
  var compiles: seq[tuple[name, cmd: string]]
  for c in stale:
    discard tryRemoveFile("book" / c.path.changeFileExt("log"))
    createDir c.cacheDir
    # -d:nimBetterRun: Nim then lists the files it compiled, with hashes, in
    # <nimcache>/chapter.json (`depfiles`), as it does for `nim r`. No -d:release, as
    # with nimibook's build: chapters run small examples, and a release build of the C
    # code costs about 4 times the CPU.
    compiles.add (c.path, "nim c -d:nimBetterRun --hints:off --nimcache:" & quoteShell(c.cacheDir) &
                          " -o:" & quoteShell(c.exe) & " " & quoteShell("book" / c.path))
  let compiled = runAll(compiles, jobs, "nimcache/logs")
  var runs: seq[tuple[name, cmd: string]]
  var prevRuntime: Table[string, seq[string]]
  for c in stale:
    let (code, output) = compiled[c.path]
    if code != 0:
      logFailure(c, output)
      continue
    # keep the run-time inputs of the old record (for runs without strace), then drop
    # the old JSON: the chapter writes a new one, or fails
    prevRuntime[c.path] = previousRuntime(c)
    discard tryRemoveFile(c.jsonPath)
    let exe = absPath(c.exe)
    runs.add (c.path, if useStrace:
      "strace -f -qq -y -e trace=openat,open -e status=successful -o " &
        quoteShell(absPath(c.cacheDir / "trace.txt")) & " " & quoteShell(exe)
    else: quoteShell(exe))
  let ran = runAll(runs, jobs, "nimcache/logs")
  for c in stale:
    if c.path notin ran: continue
    let (code, output) = ran[c.path]
    if code != 0 or not fileExists(c.jsonPath):
      logFailure(c, output)
      continue
    let traced = if useStrace: traceInputs(c.cacheDir / "trace.txt") else: @[]
    hashCache.clear()
    writeRecord(c, nimVer, traced, prevRuntime[c.path])

  if failed.len > 0:
    echo "[bookbuild] ", failed.len, " chapters failed:"
    for f in failed:
      echo "\n  ❌ ", f, "\n", readFile("book" / f.changeFileExt("log"))
    quit 1

  # one pass renders every page
  for e in book.toc.entries:
    if e.isDraft: continue
    if e.path.endsWith(".nim"):
      renderChapter(e.path, "docs" / e.path.changeFileExt("json"))
    elif not buildMd(e):
      quit 1
  check book

main()
