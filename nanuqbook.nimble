# Package

version       = "0.1.0"
author        = "Pietro Peterlongo"
description   = "Public Polars tutorials and examples, ported to Nanuq (Polars for Nim)"
license       = "MIT"  # original content only; each chapter states the licence of its source

# Dependencies

requires "nim >= 2.0.0"
requires "nimib >= 0.4.3"
requires "nimibook >= 0.4.0"
requires "nimpy >= 0.2.1"  # runs the Python side of the tabs
# nanuq is not a nimble dependency: it is the git submodule in nanuq/, pinned to a
# commit, and config.nims puts nanuq/src on the path.

# Tasks

import std/strutils

task genbook, "Build the book into docs/, rerunning only changed chapters (run it with `uv run nimble genbook`, for the Python side)":
  # Fetch Nanuq's prebuilt library once, up front: nimibook compiles the chapters in
  # parallel, and on a cold cache each would download and unpack it at the same time
  # (one chapter could then link a half-written library).
  # (nim check would not do: it skips the download commands)
  exec "nim c --compileOnly --hints:off --nimcache:nimcache/warmup nanuq/src/nanuq.nim"
  exec "nim r -d:release --hints:off nbook.nim init"
  # fresh nimibook assets, plus the book's look and script from theme/ (in the
  # assets, so pages written in Markdown get them too)
  exec "nim r -d:release --hints:off nbook.nim update"
  # The styles go at the end of chrome.css, the last stylesheet every page loads, so
  # they win over nimibook's; their font @import has to stay at the top of the file.
  let css = readFile("theme/nanuq-book.css")
  let i = css.find("@import")
  let j = css.find('\n', i)
  writeFile "docs/assets/css/chrome.css",
    css[i .. j] & readFile("docs/assets/css/chrome.css") & "\n" & css[0 ..< i] & css[j + 1 .. ^1]
  writeFile "docs/assets/js/book.js",
    readFile("docs/assets/js/book.js") & "\n" & readFile("theme/nanuq-book.js")
  # chapters run from docs/ and read data from data/ there, which is also where
  # readers of the site can download it
  cpDir "data", "docs/data"
  # Chapters run only when something they depend on changed; then every page is
  # rendered from the chapters' JSON (see bookbuild.nim). BOOK_FORCE=1 reruns them all;
  # BOOK_FROM=<url of the published book> starts from the JSON that is live.
  exec "nim r -d:release --hints:off nbook.nim dump"
  exec "nim r -d:release --hints:off --nimcache:nimcache/bookbuild bookbuild.nim"

task cleanbook, "Remove the files created by genbook":
  exec "nim r -d:release --hints:off nbook.nim clean"
