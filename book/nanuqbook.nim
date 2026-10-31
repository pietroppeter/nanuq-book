## Helpers shared by the chapters of the Nanuq book.
##
## The main one is `tabs`: a Nim port and the original Python side by side, in two tabs
## (Nim first), like the Rust/Python tabs of the Polars user guide. Both sides run when
## the book is built: the Nim blocks as usual, the Python code through nimpy in the uv
## environment of the repo (`uv run nimble genbook`).
import std/[strutils, os, osproc, xmltree]
import nimib, nimibook, nimpy
import nimpy/py_lib as pyLib
export nimib, nimibook

type Source* = object
  title*, url*: string       ## the original page
  authors*: string           ## who wrote it
  license*, licenseUrl*: string
  changes*: string           ## what this port changes, in one or two sentences

template attribution*(s: Source) =
  ## The box at the top of every ported chapter: where it comes from, under which
  ## licence, and what changed.
  nbText: "> **Ported from** [" & s.title & "](" & s.url & ") by " & s.authors &
    ", licensed under [" & s.license & "](" & s.licenseUrl & "). " & s.changes

const polarsGuide* = Source(
  authors: "the Polars contributors",
  license: "MIT",
  licenseUrl: "https://github.com/pola-rs/polars/blob/main/LICENSE")

proc userGuide*(title, path: string, changes: string): Source =
  ## A page of the Polars user guide (docs.pola.rs/user-guide/<path>).
  result = polarsGuide
  result.title = "“" & title & "” in the Polars user guide"
  result.url = "https://docs.pola.rs/user-guide/" & path & "/"
  result.changes = changes

# ---------------------------------------------------------------------------
# Python, run for real
# ---------------------------------------------------------------------------

const runnerSource = """
import ast, contextlib, html, io

def run(code, ns):
    # Runs `code` in `ns` like a notebook cell: returns what it printed, and the
    # HTML of its last expression (a table for frames), if it ends with one.
    tree = ast.parse(code)
    last = None
    if tree.body and isinstance(tree.body[-1], ast.Expr):
        last = ast.Expression(tree.body.pop().value)
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        exec(compile(tree, "<python>", "exec"), ns)
        value = eval(compile(last, "<python>", "eval"), ns) if last is not None else None
    shown = ""
    if value is not None:
        if hasattr(value, "_repr_html_"):
            shown = value._repr_html_()
        else:
            shown = '<pre class="nb-output">' + html.escape(repr(value)) + "</pre>"
    return out.getvalue(), shown
"""

var pyRunner, pyNamespace: PyObject
var pyReady = false

proc initPython() =
  # Embed the Python of the uv environment (`uv run` sets VIRTUAL_ENV): load its
  # libpython, point it at its standard library, and add the environment's packages.
  let venv = getEnv("VIRTUAL_ENV")
  if venv.len > 0:
    let probe = execProcess(venv / "bin" / "python", args = ["-c",
      "import os, sys, sysconfig; print(sys.base_prefix); " &
      "print(os.path.join(sysconfig.get_config_var('LIBDIR'), sysconfig.get_config_var('LDLIBRARY')))"],
      options = {poUsePath}).strip.splitLines
    putEnv("PYTHONHOME", probe[0])
    pyLib.pyInitLibPath(probe[1])
    let site = pyImport("site")
    for d in walkDirs(venv / "lib" / "python*" / "site-packages"):
      discard site.addsitedir(d)
  let builtins = pyBuiltinsModule()
  let helper = builtins.dict()
  discard builtins.exec(runnerSource, helper)
  pyRunner = helper["run"]
  pyNamespace = builtins.dict()
  pyReady = true

proc runPython*(code: string): tuple[printed, shown: string] =
  ## Runs a cell of Python in the chapter's Python namespace (shared by its cells).
  if not pyReady: initPython()
  let r = pyRunner.callObject(code, pyNamespace)
  (r[0].to(string), r[1].to(string))

proc pythonHtml(code: string): string =
  let (printed, shown) = runPython(code)
  result = "<pre><code class=\"language-python hljs\">" & xmltree.escape(code) & "</code></pre>"
  if printed.len > 0:
    result.add "<pre class=\"nb-output\">" & xmltree.escape(printed.strip(leading = false)) & "</pre>"
  result.add shown


template tabs*(py: string, body: untyped) =
  ## A Nim port (the blocks in `body`) and the original `py` code, in tabs, Nim
  ## first. Both run. A Python cell that ends with an expression shows its value, as
  ## in a notebook.
  let first = nb.blocks.len
  body
  var nimSide = ""
  for i in first ..< nb.blocks.len:
    nimSide.add nb.render(nb.blocks[i])
  nb.blocks.setLen(first)
  let pySide = pythonHtml(py.strip)
  nbRawHtml: "<div class=\"nq-tabs\"><div class=\"nq-tablist\" role=\"tablist\">" &
    "<button class=\"nq-tab\" role=\"tab\" data-lang=\"nim\" aria-selected=\"true\">Nim</button>" &
    "<button class=\"nq-tab\" role=\"tab\" data-lang=\"python\" aria-selected=\"false\">Python</button></div>" &
    "<div class=\"nq-panel\" data-lang=\"nim\">" & nimSide & "</div>" &
    "<div class=\"nq-panel\" data-lang=\"python\" hidden>" & pySide & "</div></div>"

template python*(code: string) =
  ## Python that runs without a Nim counterpart (shown in its own block).
  nbRawHtml: "<div class=\"nq-python-only\">" & pythonHtml(code.strip) & "</div>"

template bookStyle* =
  ## Styles and script for the book's own blocks; call once after nbInit.
  nbRawHtml: """<style>
.nq-tabs { margin: 16px 0; }
.nq-tablist { display: flex; gap: 2px; border-bottom: 1px solid var(--table-border-color, #ccc); }
.nq-tab { font: inherit; font-size: .85em; font-weight: 600; padding: 4px 14px; border: 0;
  border-bottom: 2px solid transparent; background: none; color: var(--fg); opacity: .65; cursor: pointer; }
.nq-tab[aria-selected="true"] { opacity: 1; border-bottom-color: var(--links, #0d6f86); color: var(--links, #0d6f86); }
.nq-tab:focus-visible { outline: 2px solid var(--links, #0d6f86); }
.nq-panel { padding-top: 6px; }
.nq-panel pre, .nq-python-only pre { margin: 6px 0; }
.nq-panel > div, .nq-python-only > div { overflow-x: auto; }
</style>
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
<script>
(function () {
  var pyHljs = window.hljs;  // highlight.js with Python, for the Python cells
  function choose(lang) {
    document.querySelectorAll(".nq-tabs").forEach(function (t) {
      t.querySelectorAll(".nq-tab").forEach(function (b) {
        b.setAttribute("aria-selected", b.dataset.lang === lang ? "true" : "false"); });
      t.querySelectorAll(".nq-panel").forEach(function (p) { p.hidden = p.dataset.lang !== lang; });
    });
    try { localStorage.setItem("nanuq-book-lang", lang); } catch (e) {}
  }
  document.addEventListener("click", function (e) {
    var b = e.target.closest && e.target.closest(".nq-tab");
    if (b) choose(b.dataset.lang);
  });
  document.addEventListener("DOMContentLoaded", function () {
    var lang = null;
    try { lang = localStorage.getItem("nanuq-book-lang"); } catch (e) {}
    if (lang) choose(lang);
    if (pyHljs) document.querySelectorAll("code.language-python").forEach(function (c) {
      pyHljs.highlightElement(c); });
  });
})();
</script>"""
