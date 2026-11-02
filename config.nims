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
# Linking the static Polars library (~300 MB) is most of a chapter's build: GNU ld takes
# ~9 s per binary, lld ~0.7 s once the debug info (only the library's, Nim's stack
# traces don't use it) is left out. Used when lld is installed (Linux only).
when defined(linux) and not defined(nanuqKeepDebugInfo):
  if findExe("ld.lld").len > 0:
    switch("passL", "-fuse-ld=lld")
    switch("passL", "-Wl,--strip-debug")
