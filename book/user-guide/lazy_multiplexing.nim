import nanuqbook
bookInit()

nbText: "# Lazy: multiplexing queries"

attribution userGuide("Multiplexing queries", "lazy/multiplexing",
  "The Graphviz pictures of the plans are left out (Nanuq has no `showGraph`); the " &
  "printed plan of `explain_all` stays. The Nim tab writes out the shuffled numbers that " &
  "NumPy's seed 0 gives.")

nbText: """
In the [Sources and Sinks](lazy_sources_sinks.html) page, we already discussed multiplexing as a
way to split a query into multiple sinks. This page will go a bit deeper in this concept, as it
is important to understand when combining `LazyFrame`s with procedural programming constructs.

When dealing with eager dataframes, it is very common to keep state in a temporary variable.
Let's look at the following example. Below we create a `DataFrame` with 10 unique elements in a
random order (so that Polars doesn't hit any fast paths for sorted keys).
"""

tabs """
import numpy as np
import polars as pl
import polars.testing

np.random.seed(0)
a = np.arange(0, 10)
np.random.shuffle(a)
df = pl.DataFrame({"n": a})
df
""":
  nbCode:
    import nanuq, nanuq/testing

    let df = newDataFrame:
      n: [2, 8, 4, 9, 1, 6, 7, 3, 0, 5]
    nbShow df

nbText: """
## Eager

If you deal with the Polars eager API, making a variable and iterating over that temporary
`DataFrame` gives the result you expect, as the result of the group-by is stored in `df1`. Even
though the output order is unstable, it doesn't matter as it is eagerly evaluated. The follow
snippet therefore doesn't raise and the assert passes.
"""

tabs """
# A group-by doesn't guarantee order
df1 = df.group_by("n").len()

# Take the lower half and the upper half in a list
out = [df1.slice(offset=i * 5, length=5) for i in range(2)]

# Assert df1 is equal to the sum of both halves
pl.testing.assert_frame_equal(df1, pl.concat(out))
""":
  nbCode:
    # A group-by doesn't guarantee order (in Python; Nanuq keeps it)
    let df1 = df.groupBy("n").len

    # Take the lower half and the upper half in a list
    var halves: seq[DataFrame]
    for i in 0 ..< 2: halves.add df1.slice(offset = i * 5, length = 5)

    # Assert df1 is equal to the sum of both halves
    assertFrameEqual(df1, concat(halves))

nbText: """
## Lazy

Now if we tried this naively with `LazyFrame`s, this would fail.
"""

tabs """
lf1 = df.lazy().group_by("n").len()

out = [lf1.slice(offset=i * 5, length=5).collect() for i in range(2)]

try:
    pl.testing.assert_frame_equal(lf1.collect(), pl.concat(out))
    print("equal, this time")
except AssertionError as e:
    print("AssertionError:", str(e).splitlines()[0])
""":
  nbCode:
    let lf1 = df.lazy.groupBy("n").len

    var outs: seq[DataFrame]
    for i in 0 ..< 2: outs.add lf1.slice(offset = i * 5, length = 5).collect

    assertFrameEqual(lf1.collect, concat(outs))

nanuq """
In Nanuq this naive version passes: a Nanuq `groupBy` keeps the groups in the order they are
first seen (Python's `maintain_order=True`), so every run of the plan gives the same rows. The
point of the page still holds, as each `collect` above runs the group-by again: three times
for one table. The Python tab catches the error, which happens on most runs but not all.
"""

nbText: """
```python
AssertionError: DataFrames are different (value mismatch for column 'n')
[left]:  [9, 2, 0, 5, 3, 1, 7, 8, 6, 4]
[right]: [0, 9, 6, 8, 2, 5, 4, 3, 1, 7]
```

The reason this fails is that `lf1` doesn't contain the materialized result of
`df.lazy().group_by("n").len()`, it instead holds the query plan in that variable.

This means that every time we branch of this `LazyFrame` and call `collect` we re-evaluate the
group-by. Besides being expensive, this also leads to unexpected results if you assume that the
output is stable (which isn't the case here).

In the example above you are actually evaluating 2 query plans (one for each half, each with
its own group-by).

## Combine the query plans

To circumvent this, we must give Polars the opportunity to look at all the query plans in a
single optimization and execution pass. This can be done by passing the diverging `LazyFrame`'s
to the `collect_all` function.
"""

tabs """
lf1 = df.lazy().group_by("n").len()

out = [lf1.slice(offset=i * 5, length=5) for i in range(2)]
results = pl.collect_all([lf1] + out)

pl.testing.assert_frame_equal(results[0], pl.concat(results[1:]))
""":
  nbCode:
    let lf2 = df.lazy.groupBy("n").len

    let plans = @[lf2, lf2.slice(offset = 0, length = 5), lf2.slice(offset = 5, length = 5)]
    let results = collectAll(plans)

    assertFrameEqual(results[0], concat(results[1 .. ^1]))

nbText: """
If we explain the combined queries with `pl.explain_all`, we can also observe that they are
shared under a single "SINK_MULTIPLE" evaluation and that the optimizer has recognized that
parts of the query come from the same subplan, indicated by the inserted "CACHE" nodes.
"""

tabs """
lf1 = df.lazy().group_by("n").len()
out = [lf1.slice(offset=i * 5, length=5) for i in range(2)]

print(pl.explain_all([lf1] + out))
""":
  nbCode:
    echo explainAll(plans)

nbText: """
Combining related subplans in a single execution unit with `pl.collect_all` can thus lead to
large performance increases and allows diverging query plans, storing temporary tables, and a
more procedural programming style.
"""

bookSave()
