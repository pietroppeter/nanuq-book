## Helpers shared by the chapters of the Nanuq book.
import std/[strutils, xmltree]
import nimib, nimibook
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

template python*(code: string) =
  ## The original Python code, shown (not run) before its Nim port.
  nbRawHtml: "<div class=\"py-original\"><span>Python</span><pre><code class=\"language-python\">" &
    xmltree.escape(code.strip) & "</code></pre></div>"

template bookStyle* =
  ## Styles for the book's own blocks; call once after nbInit.
  nbRawHtml: """<style>
.py-original { border-left: 3px solid #e0b000; padding: 0 0 0 10px; margin: 12px 0; opacity: .85; }
.py-original > span { font-size: .75em; font-weight: 600; text-transform: uppercase; letter-spacing: .05em; color: #8a6d00; }
.py-original pre { margin: 2px 0 0; background: transparent; }
.content table.dataframe, .content .dataframe table { font-size: .85em; }
</style>"""

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
