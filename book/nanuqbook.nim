## Helpers shared by the chapters of the Nanuq book.
##
## The main one is `tabs`: a Nim port and the original Python side by side, in two tabs
## (Nim first), like the Rust/Python tabs of the Polars user guide. Both sides run when
## the book is built: the Nim blocks as usual, the Python code through nimpy in the uv
## environment of the repo (`uv run nimble genbook`).
import std/[strutils, os, osproc, xmltree, json, algorithm]
import nimib, nimibook, nimpy, markdown
import nimpy/py_lib as pyLib
export nimib, nimibook

type Source* = object
  title*, url*: string       ## the original page
  authors*: string           ## who wrote it
  license*, licenseUrl*: string
  changes*: string           ## what this port changes, in one or two sentences

proc noteHtml(label, text: string): string =
  "<aside class=\"nq-note\"><p class=\"nq-note-label\">" & label & "</p>" &
    markdown(text, config = initGfmConfig()) & "</aside>"

template nanuq*(text: string) =
  ## A remark of the Nanuq book (how Nanuq differs, what it lacks), set apart from the
  ## text of the original page, which is kept as it is.
  nbRawHtml: noteHtml("🐻‍❄️ Nanuq", text)

template attribution*(s: Source) =
  ## The box at the top of every ported chapter: where it comes from, under which
  ## licence, and what changed.
  nbRawHtml: noteHtml("🐻‍❄️ About this port", "**Ported from** [" & s.title & "](" & s.url &
    ") by " & s.authors & ", licensed under [" & s.license & "](" & s.licenseUrl & "). " &
    "The text of the original is kept as it is; the Nanuq book's own remarks are in " &
    "boxes like this one. " & s.changes)

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

proc pythonHtml(code: string): tuple[html, shown: string] =
  let (printed, shown) = runPython(code)
  result.html = "<pre><code class=\"language-python hljs\">" & xmltree.escape(code) & "</code></pre>"
  if printed.len > 0:
    result.html.add "<pre class=\"nb-output\">" & xmltree.escape(printed.strip(leading = false)) & "</pre>"
  result.html.add shown
  result.shown = shown

proc lastFrame(html: string): string =
  ## The last DataFrame table in `html` (shape line and table), as both Nanuq's
  ## toHtml and Python Polars' _repr_html_ write it; "" if there is none.
  let stop = html.rfind("</table>")
  if stop < 0: return ""
  let start = html.rfind("<small>shape:", last = stop)
  if start < 0: return ""
  html[start ..< stop + "</table>".len]

proc sortedRows(frame: string): string =
  ## The table with its body rows sorted, so that two frames with the same rows in a
  ## different order compare equal (a `group_by` without `maintain_order` gives its
  ## groups in any order).
  let start = frame.find("<tbody>")
  let stop = frame.rfind("</tbody>")
  if start < 0 or stop < start: return frame
  var rows = frame[start + "<tbody>".len ..< stop].split("</tr>")
  rows.sort()
  frame[0 ..< start] & rows.join("</tr>") & frame[stop .. ^1]

proc checkSameFrame*(nimHtml, pythonShown, py: string) =
  ## Fails the build when the Python cell shows a DataFrame that differs from the
  ## last one the Nim side shows. Row order is not compared.
  let pyFrame = lastFrame(pythonShown)
  if pyFrame.len == 0: return
  let nimFrame = lastFrame(nimHtml)
  if nimFrame.len == 0:
    raise newException(ValueError, "the Python cell shows a DataFrame and the Nim tab " &
      "shows none:\n" & py)
  if nimFrame != pyFrame and sortedRows(nimFrame) != sortedRows(pyFrame):
    raise newException(ValueError, "Nim and Python show different DataFrames for:\n" &
      py & "\n--- nim:\n" & nimFrame & "\n--- python:\n" & pyFrame)


const nimLabel = "👑 Nim"
const pythonLabel = "🐍 Python"

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
  let (pySide, pyShown) = pythonHtml(py.strip)
  checkSameFrame(nimSide, pyShown, py.strip)
  nbRawHtml: "<div class=\"nq-tabs\"><div class=\"nq-tablist\" role=\"tablist\">" &
    "<button class=\"nq-tab\" role=\"tab\" data-lang=\"nim\" aria-selected=\"true\">" & nimLabel & "</button>" &
    "<button class=\"nq-tab\" role=\"tab\" data-lang=\"python\" aria-selected=\"false\">" & pythonLabel & "</button></div>" &
    "<div class=\"nq-panel\" data-lang=\"nim\">" & nimSide & "</div>" &
    "<div class=\"nq-panel\" data-lang=\"python\" hidden>" & pySide & "</div></div>"

template python*(code: string) =
  ## Python that runs without a Nim counterpart (shown in its own block).
  nbRawHtml: "<div class=\"nq-python-only\">" & pythonHtml(code.strip).html & "</div>"

# --- Theme ------------------------------------------------------------------
# The styles and script live in theme/ (nanuq-book.css, nanuq-book.js), which
# `nimble genbook` adds to nimibook's own assets, so Markdown chapters get them too.

proc useNanuqBook*(nb: var Nb) =
  ## nimibook, restyled like the Nanuq dev log.
  nb.useNimibook
  # the book's two looks; theme/nanuq-book.js turns the theme menu into a light/dark switch
  nb.doc.context["theme_option"] = %*{"light": "Light", "navy": "Dark"}
  # Nim cells come highlighted from nimib; skip nimib's highlight.js
  nb.doc.context["disableHighlightJs"] = %true

template bookInit* =
  ## Starts a chapter: `nbInit` with the book's theme.
  nbInit(theme = useNanuqBook)

proc sourceHtml(nb: Nb): string =
  let rel = nb.doc.thisFileRel.string.replace('\\', '/')
  let url = "https://github.com/pietroppeter/nanuq-book/blob/main/book/" & rel
  "<details class=\"nq-source\"><summary></summary>" &
    "<pre><code class=\"nim-source nohighlight nim hljs\">" & highlightNim(nb.doc.source) &
    "</code></pre><p class=\"nq-source-link\">On GitHub: <a href=\"" & url & "\">book/" & rel &
    "</a></p></details>" &
    "<div class=\"nq-foot\">Made with <a href=\"https://github.com/pietroppeter/nimib\">nimib</a> " &
    "and <a href=\"https://github.com/pietroppeter/nimibook\">nimibook</a>. Blocks marked " &
    "\"ran\" were executed when this page was built.</div>"

template bookSave* =
  ## Ends a chapter: a "Show source" button with the page's own source, then `nbSave`.
  nbRawHtml: sourceHtml(nb)
  nbSave
