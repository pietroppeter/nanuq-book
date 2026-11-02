import nanuqbook
bookInit()

nbText: "# Multiple files"

attribution userGuide("Multiple", "io/multiple",
  "The files are written to `data/polars/` instead of `docs/assets/data/`, the frames are " &
  "shown instead of printed, the file list is sorted, and the Graphviz pictures of the plan " &
  "(`show_graph`) are left out: Nanuq has no `showGraph`.")

nbText: """
## Dealing with multiple files.

Polars can deal with multiple files differently depending on your needs and memory strain.

Let's create some files to give us some context:
"""

tabs """
import polars as pl

df = pl.DataFrame({"foo": [1, 2, 3], "bar": [None, "ham", "spam"]})

for i in range(5):
    df.write_csv(f"data/polars/my_many_files_{i}.csv")
""":
  nbCode:
    import nanuq, std/[os, algorithm, sequtils]

    var df = newDataFrame:
      foo: [1, 2, 3]
      bar: [none(string), some("ham"), some("spam")]

    for i in 0 ..< 5:
      df.writeCsv("data/polars/my_many_files_" & $i & ".csv")

nbText: """
## Reading into a single `DataFrame`

To read multiple files into a single `DataFrame`, we can use globbing patterns:
"""

tabs """
df = pl.read_csv("data/polars/my_many_files_*.csv")
df
""":
  nbCode:
    df = readCsv("data/polars/my_many_files_*.csv")
    nbShow df

nbText: """
To see how this works we can take a look at the query plan. Below we see that all files are
read separately and concatenated into a single `DataFrame`. Polars will try to parallelize the
reading.
"""

tabs """
print(pl.scan_csv("data/polars/my_many_files_*.csv").explain())
""":
  nbCode:
    echo scanCsv("data/polars/my_many_files_*.csv").explain

nanuq """
The guide draws this plan with `show_graph`; the printed plan says the same: one CSV scan over
the five files.
"""

nbText: """
## Reading and processing in parallel

If your files don't have to be in a single table you can also build a query plan for each file
and execute them in parallel on the Polars thread pool.

All query plan execution is embarrassingly parallel and doesn't require any communication.
"""

tabs """
import glob

queries = []
for file in sorted(glob.glob("data/polars/my_many_files_*.csv")):
    q = pl.scan_csv(file).group_by("bar").agg(pl.len(), pl.sum("foo"))
    queries.append(q)

dataframes = pl.collect_all(queries)
dataframes[0]
""":
  nbCode:
    var queries: seq[LazyFrame]
    for file in sorted(toSeq(walkFiles("data/polars/my_many_files_*.csv"))):
      let q = scanCsv(file).groupBy("bar").agg(len(), col.foo.sum)
      queries.add q

    let dataframes = collectAll(queries)
    echo dataframes.len, " frames"
    nbShow dataframes[0]

nanuq """
The guide prints the list of five frames; the page shows how many there are and the first one
(they are all the same).
"""

bookSave()
