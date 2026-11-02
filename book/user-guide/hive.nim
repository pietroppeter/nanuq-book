import nanuqbook
bookInit()

nbText: "# Hive partitioning"

attribution userGuide("Hive", "io/hive",
  "The files are written to `data/polars/` instead of `docs/assets/data/`, and frames are " &
  "shown instead of printed. Nanuq 0.6 scans one path or glob at a time and writes " &
  "partitioned files through a sink; boxes show where the Nim tab differs.")

nbText: """
## Scanning hive partitioned data

Polars supports scanning hive partitioned parquet and IPC datasets, with planned support for
other formats in the future.

Hive partition parsing is enabled by default if `scan_parquet` receives a single directory path,
otherwise it is disabled by default. This can be explicitly configured using the
`hive_partitioning` parameter.

### Scanning a hive directory

For this example the following directory structure is used:
"""

tabs """
import polars as pl
from pathlib import Path

dfs = [
    pl.DataFrame({"x": [1, 2]}),
    pl.DataFrame({"x": [3, 4, 5]}),
    pl.DataFrame({"x": [6, 7]}),
    pl.DataFrame({"x": [8, 9, 10, 11]}),
]

parts = [
    "year=2023/month=11",
    "year=2023/month=12",
    "year=2024/month=01",
    "year=2024/month=02",
]

for df, part in zip(dfs, parts, strict=True):
    path = Path("data/polars/hive/") / part / "data.parquet"
    Path(path).parent.mkdir(exist_ok=True, parents=True)
    df.write_parquet(path)

    path = Path("data/polars/hive_mixed/") / part / "data.parquet"
    Path(path).parent.mkdir(exist_ok=True, parents=True)
    df.write_parquet(path)

# Make sure the file is not empty because path expansion ignores empty files.
Path("data/polars/hive_mixed/description.txt").write_text("A")


def paths(path: str) -> pl.DataFrame:
    def dir_recurse(path: Path):
        if path.is_dir():
            for p in path.iterdir():
                yield from dir_recurse(p)
        else:
            yield path

    return (
        pl.Series(
            "File path",
            (str(x) for x in dir_recurse(Path(path))),
            dtype=pl.String,
        )
        .sort()
        .to_frame()
    )


paths("data/polars/hive/")
""":
  nbCode:
    import nanuq, std/[os, algorithm]

    let dfs = [
      newDataFrame(series("x", [1, 2])),
      newDataFrame(series("x", [3, 4, 5])),
      newDataFrame(series("x", [6, 7])),
      newDataFrame(series("x", [8, 9, 10, 11]))]

    let parts = [
      "year=2023/month=11",
      "year=2023/month=12",
      "year=2024/month=01",
      "year=2024/month=02"]

    for i, part in parts:
      for root in ["data/polars/hive", "data/polars/hive_mixed"]:
        let path = root / part / "data.parquet"
        createDir path.parentDir
        dfs[i].writeParquet(path)

    # Make sure the file is not empty because path expansion ignores empty files.
    writeFile("data/polars/hive_mixed/description.txt", "A")

    proc paths(path: string): DataFrame =
      var files: seq[string]
      for f in walkDirRec(path): files.add f
      newDataFrame(series("File path", files.sorted))

    nbShow paths("data/polars/hive")

nbText: """
Simply pass the directory to `scan_parquet`, and all files will be loaded with the hive parts in
the path included in the output:
"""

tabs """
df = pl.scan_parquet("data/polars/hive/").collect()
df
""":
  nbCode:
    var df = scanParquet("data/polars/hive/").collect
    nbShow df

nbText: """
### Handling mixed files

Passing a directory to `scan_parquet` may not work if there are files with different extensions
in the directory.

For this example the following directory structure is used:
"""

tabs """
paths("data/polars/hive_mixed/")
""":
  nbCode:
    nbShow paths("data/polars/hive_mixed")

tabs """
try:
    pl.scan_parquet("data/polars/hive_mixed/").collect()
except Exception as e:
    print(e)
""":
  nbCode:
    try:
      discard scanParquet("data/polars/hive_mixed/").collect
    except CatchableError as e:
      echo e.msg

nbText: """
The above fails as `description.txt` is not a valid parquet file.

In this situation, a glob pattern can be used to be more specific about which files to load.
Note that `hive_partitioning` must explicitly set to `True`:
"""

tabs """
df = pl.scan_parquet(
    # Glob to match all files ending in `.parquet`
    "data/polars/hive_mixed/**/*.parquet",
    hive_partitioning=True,
).collect()
df
""":
  nbCode:
    df = scanParquet(
      # Glob to match all files ending in `.parquet`
      "data/polars/hive_mixed/**/*.parquet",
      hivePartitioning = true).collect
    nbShow df

nbText: """
### Scanning file paths with hive parts

`hive_partitioning` is not enabled by default for file paths:
"""

tabs """
df = pl.scan_parquet(
    [
        "data/polars/hive/year=2024/month=01/data.parquet",
        "data/polars/hive/year=2024/month=02/data.parquet",
    ],
).collect()
df
""":
  nbCode:
    df = concat([
      scanParquet("data/polars/hive/year=2024/month=01/data.parquet"),
      scanParquet("data/polars/hive/year=2024/month=02/data.parquet")]).collect
    nbShow df

nanuq """
Nanuq's `scanParquet` takes one path or glob, not a list of paths, so the Nim tab concatenates
two scans (still one lazy query). A glob covers this example too:
`scanParquet("data/polars/hive/year=2024/*/data.parquet")`.
"""

nbText: """
Pass `hive_partitioning=True` to enable hive partition parsing:
"""

tabs """
df = pl.scan_parquet(
    [
        "data/polars/hive/year=2024/month=01/data.parquet",
        "data/polars/hive/year=2024/month=02/data.parquet",
    ],
    hive_partitioning=True,
).collect()
df
""":
  nbCode:
    df = concat([
      scanParquet("data/polars/hive/year=2024/month=01/data.parquet",
                  hivePartitioning = true),
      scanParquet("data/polars/hive/year=2024/month=02/data.parquet",
                  hivePartitioning = true)]).collect
    nbShow df

nbText: """
## Writing hive partitioned data

> Note: The following functionality is considered _unstable_, and is subject to change.

Polars supports writing hive partitioned parquet datasets, with planned support for other
formats.

### Example

For this example the following DataFrame is used:
"""

tabs """
df = pl.DataFrame({"a": [1, 1, 2, 2, 3], "b": [1, 1, 1, 2, 2], "c": 1})
df
""":
  nbCode:
    df = newDataFrame(
      series("a", [1, 1, 2, 2, 3]),
      series("b", [1, 1, 1, 2, 2]),
      series("c", [1'i32, 1, 1, 1, 1]))
    nbShow df

nanuq """
Python broadcasts the scalar `"c": 1` to the frame's height, as an `Int32` column (a Python int literal is `Int32` in Polars); the Nim tab spells the column out.
"""

nbText: """
We will write it to a hive-partitioned parquet dataset, partitioned by the columns `a` and `b`:
"""

tabs """
df.write_parquet("data/polars/hive_write/", partition_by=["a", "b"])
""":
  nbCode:
    df.lazy.sinkParquet(
      PartitionBy(basePath: "data/polars/hive_write/", key: @["a", "b"]),
      mkdir = true)

nanuq """
Nanuq's `writeParquet` has no `partitionBy`; the same files come from the streaming sink with a
`PartitionBy` target, which is what Python's `partition_by` uses inside.
"""

nbText: """
The output is a hive partitioned parquet dataset with the following paths:
"""

tabs """
paths("data/polars/hive_write/")
""":
  nbCode:
    nbShow paths("data/polars/hive_write")

bookSave()
