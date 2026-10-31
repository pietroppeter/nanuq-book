import std/os
# Nanuq comes from the git submodule in nanuq/ (pinned to a commit).
switch("path", thisDir() / "nanuq" / "src")
switch("path", thisDir() / "book")
# Use only a released Polars wrapper library (downloaded from Nanuq's GitHub
# releases), never build it with cargo: building fails if the pinned lib version
# is not released. A library in nanuq/src/rust/target/release still wins, for
# local work on an unreleased Nanuq.
switch("define", "nanuqLib=prebuilt")
switch("path", thisDir() / "bench")
