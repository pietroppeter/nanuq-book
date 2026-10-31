## Helpers shared by the chapters of the Nanuq book.
##
## The main one is `tabs`: a Nim port and the original Python side by side, in two tabs
## (Nim first), like the Rust/Python tabs of the Polars user guide. Both sides run when
## the book is built: the Nim blocks as usual, the Python code through nimpy in the uv
## environment of the repo (`uv run nimble genbook`).
import std/[strutils, os, osproc, xmltree, json]
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
  let pySide = pythonHtml(py.strip)
  nbRawHtml: "<div class=\"nq-tabs\"><div class=\"nq-tablist\" role=\"tablist\">" &
    "<button class=\"nq-tab\" role=\"tab\" data-lang=\"nim\" aria-selected=\"true\">" & nimLabel & "</button>" &
    "<button class=\"nq-tab\" role=\"tab\" data-lang=\"python\" aria-selected=\"false\">" & pythonLabel & "</button></div>" &
    "<div class=\"nq-panel\" data-lang=\"nim\">" & nimSide & "</div>" &
    "<div class=\"nq-panel\" data-lang=\"python\" hidden>" & pySide & "</div></div>"

template python*(code: string) =
  ## Python that runs without a Nim counterpart (shown in its own block).
  nbRawHtml: "<div class=\"nq-python-only\">" & pythonHtml(code.strip) & "</div>"

# --- Theme ------------------------------------------------------------------
# nimibook's layout (sidebar, menu bar, search) restyled with the palette and fonts
# of the Nanuq dev log (nanuq/docs/nanuqtheme.nim): pack ice in light themes, polar
# night in dark ones. Nim is highlighted by nimib when the page is built; highlight.js
# (cdnjs) highlights only the Python cells.

const bookHead = """
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Familjen+Grotesk:wght@500;700&family=Literata:ital,opsz,wght@0,7..72,400;0,7..72,600;1,7..72,400&family=JetBrains+Mono:wght@400;600&display=swap">
<style>
/* html.<theme> beats nimibook's .<theme> in variables.css, which loads later */
html.light, html.rust {
  --ice: #f3f7f9; --floe: #ffffff; --ink: #12222e; --mute: #5a6b77; --rule: #d5e1e8;
  --fjord: #0d6f86; --out-bg: #e8f0f4;
  --kw: #8a3b8f; --str: #2f7a3a; --num: #a55310; --com: #7b8a95; --fn: #0d6f86;
  --sidebar-bg: #e8f0f4; --sidebar-fg: #12222e; --sidebar-active: #0d6f86;
  --sidebar-non-existant: #93a6b3; --sidebar-spacer: #d5e1e8;
  --theme-popup-bg: #ffffff; --theme-popup-border: #d5e1e8; --theme-hover: #e8f0f4;
  --searchbar-bg: #ffffff; --searchbar-border-color: #d5e1e8; --searchresults-li-bg: #e8f0f4;
  --search-mark-bg: #b9e3ec; --icons: #5a6b77; --icons-hover: #0d6f86; --scrollbar: #93a6b3;
  color-scheme: light;
}
html.coal, html.navy, html.ayu {
  --ice: #0d161d; --floe: #121e27; --ink: #e3ecf1; --mute: #93a6b3; --rule: #22323e;
  --fjord: #5cc4dc; --out-bg: #0a1218;
  --kw: #d79be0; --str: #8fd19a; --num: #f0a868; --com: #6d8190; --fn: #5cc4dc;
  --sidebar-bg: #0a1218; --sidebar-fg: #c9d6de; --sidebar-active: #5cc4dc;
  --sidebar-non-existant: #5a6b77; --sidebar-spacer: #22323e;
  --theme-popup-bg: #121e27; --theme-popup-border: #22323e; --theme-hover: #1a2a35;
  --searchbar-bg: #121e27; --searchbar-fg: #e3ecf1; --searchbar-border-color: #22323e;
  --searchresults-li-bg: #121e27; --search-mark-bg: #1d5566; --icons: #93a6b3;
  --icons-hover: #5cc4dc; --scrollbar: #5a6b77;
  color-scheme: dark;
}
html.light, html.rust, html.coal, html.navy, html.ayu {
  --bg: var(--ice); --fg: var(--ink); --links: var(--fjord); --inline-code-color: var(--ink);
  --quote-bg: var(--floe); --quote-border: var(--fjord);
  --table-border-color: var(--rule); --table-header-bg: var(--out-bg); --table-alternate-bg: var(--floe);
  --display: "Familjen Grotesk", "Helvetica Neue", Arial, sans-serif;
  --body: "Literata", Georgia, "Times New Roman", serif;
  --mono: "JetBrains Mono", ui-monospace, "SF Mono", Menlo, Consolas, monospace;
  --content-max-width: 78rem;  /* rem is 10px in nimibook */
}
html { font-family: var(--body); }
body { font-size: 1.7rem; line-height: 1.65; }  /* nimibook sets html to 62.5% */
.sidebar { font-family: var(--display); font-size: 1.5rem; border-right: 1px solid var(--rule); }
.chapter li a, .chapter li.chapter-item { line-height: 1.4; }
.chapter li a.active { font-weight: 700; }
.menu-bar { border-bottom-color: var(--rule) !important; }
.menu-title { font: 700 2rem/1 var(--display); letter-spacing: -.01em; }
.content main { line-height: 1.65; }
.content h1, .content h2, .content h3, .content h4 { font-family: var(--display); line-height: 1.15;
  text-wrap: balance; }
.content h1 { font-size: clamp(3.2rem, 6vw, 4.4rem); letter-spacing: -.02em; margin: 1.5rem 0 1rem; }
.content h2 { font-size: 2.6rem; letter-spacing: -.01em; margin-top: 3.6rem; }
.content h3 { font-size: 2rem; margin-top: 2.6rem; }
.content p, .content li { max-width: 65ch; }
.content a, .content a:link, .content a:visited { color: var(--fjord); }
.content a { text-decoration: underline; text-underline-offset: 2px; }
.content .header:link, .content .header:visited { color: var(--ink); text-decoration: none; }
blockquote { border-left: 3px solid var(--fjord); border-top: none; border-bottom: none; margin: 1.5rem 0;
  padding: .2rem 1.4rem; background: var(--floe); color: var(--mute); border-radius: 0 6px 6px 0; }
code, pre, pre code, .hljs { font-family: var(--mono) !important; font-variant-ligatures: none; }
:not(pre) > code { font-size: .86em; background: var(--out-bg); padding: .1em .3em; border-radius: 3px; }
.content pre { position: relative; margin: 1rem 0 0; }
.content pre > code, .content pre > code.hljs {
  display: block; background: var(--floe); color: var(--ink); border: 1px solid var(--rule);
  border-radius: 6px; padding: 2.2rem 1.4rem 1.2rem; font-size: 1.36rem; line-height: 1.55; overflow-x: auto; }
.content pre::before { position: absolute; top: .6rem; right: 1rem; z-index: 1;
  font: 600 1rem/1 var(--mono); letter-spacing: .1em; text-transform: uppercase; color: var(--mute); }
.content pre:has(> code.nim)::before { content: "nim · ran"; }
.content pre:has(> code.language-python)::before { content: "python · ran"; }
.content pre:has(> code.nim-source)::before { content: "nim · source of this page"; }
.content pre:has(> code):has(+ pre.nb-output) > code,
.content pre:has(> code):has(+ div > table.dataframe) > code { border-radius: 6px 6px 0 0; }
.content pre.nb-output:has(+ div > table.dataframe) { border-radius: 0; }
.content pre.nb-output { background: var(--out-bg); border: 1px solid var(--rule); border-top: none;
  border-radius: 0 0 6px 6px; margin: 0; padding: 2.2rem 1.4rem 1rem; font: 1.28rem/1.3 var(--mono);
  color: var(--ink); white-space: pre; overflow-x: auto; }
.content pre.nb-output::before { content: "output"; left: 1.4rem; right: auto; color: var(--fjord); }
.hljs { background: var(--floe); color: var(--ink); }
.hljs-keyword, .hljs-meta, .hljs-built_in, .hljs-selector-tag { color: var(--kw); }
.hljs-string, .hljs-char, .hljs-regexp { color: var(--str); }
.hljs-number, .hljs-literal { color: var(--num); }
.hljs-comment, .hljs-quote { color: var(--com); font-style: italic; }
.hljs-title, .hljs-function, .hljs-type, .hljs-params { color: var(--fn); }
.hljs-attribute, .hljs-symbol, .hljs-variable, .hljs-operator, .hljs-punctuation { color: var(--ink); }
/* Markdown tables */
.content table { border-collapse: collapse; margin: 1.5rem 0; font-size: 1.4rem; line-height: 1.45;
  border: 1px solid var(--rule); background: var(--floe); display: block; overflow-x: auto; width: max-content; max-width: 100%; }
.content table td, .content table th { padding: .6rem .9rem; border: none; border-bottom: 1px solid var(--rule); }
.content table thead th, .content table thead td { font: 600 1.1rem/1.2 var(--mono); letter-spacing: .08em;
  text-transform: uppercase; color: var(--mute); background: var(--out-bg); text-align: left; }
.content table tbody tr:nth-child(2n) { background: transparent; }
/* DataFrame tables (toHtml in Nim, _repr_html_ in Python): one output cell under the code */
.content div:has(> table.dataframe) { background: var(--out-bg); border: 1px solid var(--rule); border-top: none;
  border-radius: 0 0 6px 6px; padding: 2.2rem 1.4rem 1rem; position: relative; overflow-x: auto; }
.content div:has(> table.dataframe)::before { content: "output"; position: absolute; top: .6rem; left: 1.4rem;
  font: 600 1rem/1 var(--mono); letter-spacing: .1em; text-transform: uppercase; color: var(--fjord); }
.content div:has(> table.dataframe) small { font: 1.15rem/1.4 var(--mono); color: var(--mute); }
.content table.dataframe { font: 1.25rem/1.4 var(--mono); margin: .3rem 0 0;
  background: var(--floe); border: 1px solid var(--rule); border-radius: 4px; }
.content table.dataframe th, .content table.dataframe td { padding: .3rem .8rem; text-align: right;
  white-space: pre; border-bottom: 1px solid var(--rule); }
.content table.dataframe thead th { font: 600 1.25rem/1.4 var(--mono); letter-spacing: 0; text-transform: none;
  color: var(--ink); background: var(--floe); }
.content table.dataframe thead tr:nth-child(2) td, .content table.dataframe thead tr:nth-child(2) th {
  color: var(--mute); background: var(--out-bg); border-bottom: 2px solid var(--rule); font-weight: 400; }
.content table.dataframe tbody tr:last-child td { border-bottom: none; }
/* Nim / Python tabs */
.nq-tabs { margin: 2rem 0; }
.nq-tablist { display: flex; gap: .4rem; }
.nq-tab { font: 600 1.25rem/1 var(--mono); letter-spacing: .04em; padding: .7rem 1.2rem; cursor: pointer;
  border: 1px solid var(--rule); border-bottom: none; border-radius: 6px 6px 0 0;
  background: transparent; color: var(--mute); }
.nq-tab[aria-selected="true"] { background: var(--floe); color: var(--fjord); box-shadow: inset 0 2px 0 var(--fjord); }
.nq-tab:hover { color: var(--fjord); }
.nq-tab:focus-visible { outline: 2px solid var(--fjord); outline-offset: 2px; }
.nq-panel > pre:first-child { margin-top: 0; }
.nq-panel > pre:first-child > code { border-top-left-radius: 0; }
.nq-python-only { margin: 2rem 0; }
/* the attribution box at the top of a ported chapter */
.content blockquote strong { color: var(--ink); }
/* "Show source": the page's own nimib source, folded at the end */
details.nq-source { margin: 4rem 0 1rem; }
details.nq-source summary { cursor: pointer; width: max-content; font: 600 1.2rem/1 var(--mono);
  letter-spacing: .06em; text-transform: uppercase; color: var(--fjord); padding: .8rem 1.2rem;
  border: 1px solid var(--rule); border-radius: 6px; background: var(--floe); list-style: none; }
details.nq-source summary::-webkit-details-marker { display: none; }
details.nq-source summary::before { content: "Show source"; }
details.nq-source[open] summary::before { content: "Hide source"; }
details.nq-source .nq-source-link { font: 1.2rem/1.4 var(--mono); color: var(--mute); margin: 1rem 0 0; }
.nq-foot { margin-top: 3rem; padding-top: 1rem; border-top: 1px solid var(--rule);
  font: 1.2rem/1.5 var(--mono); color: var(--mute); }
.content .nq-foot a { color: var(--fjord); }
</style>
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
<script>
(function () {
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
    if (window.hljs) document.querySelectorAll("code.language-python").forEach(function (c) {
      try { window.hljs.highlightElement(c); } catch (e) {} });
  });
})();
</script>
"""

func bookHeadPartial(blk: JsonNode, nb: Nb): string = bookHead

proc useNanuqBook*(nb: var Nb) =
  ## nimibook, restyled like the Nanuq dev log.
  nb.useNimibook
  nb.backend.partials["head"] = bookHeadPartial
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
