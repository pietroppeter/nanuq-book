import std/os
# Nanuq comes from the git submodule in nanuq/ (pinned to a commit). Its Polars
# wrapper library is found or built under nanuq/src/rust/target/release.
switch("path", thisDir() / "nanuq" / "src")
switch("path", thisDir() / "book")
