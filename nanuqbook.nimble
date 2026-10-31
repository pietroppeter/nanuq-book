# Package

version       = "0.1.0"
author        = "Pietro Peterlongo"
description   = "Public Polars tutorials and examples, ported to Nanuq (Polars for Nim)"
license       = "MIT"  # original content only; each chapter states the licence of its source

# Dependencies

requires "nim >= 2.0.0"
requires "nimib >= 0.4.3"
requires "nimibook >= 0.4.0"
# nanuq is not a nimble dependency: it is the git submodule in nanuq/, pinned to a
# commit, and config.nims puts nanuq/src on the path.

# Tasks

task genbook, "Build the book into docs/":
  exec "nim r -d:release --hints:off nbook.nim init"
  # chapters run from docs/ and read data from data/ there, which is also where
  # readers of the site can download it
  cpDir "data", "docs/data"
  exec "nim r -d:release --hints:off nbook.nim build"

task cleanbook, "Remove the files created by genbook":
  exec "nim r -d:release --hints:off nbook.nim clean"
