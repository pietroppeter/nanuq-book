import nanuqbook
bookInit()

nbText: "# Aggregation"

attribution userGuide("Aggregation", "expressions/aggregation",
  "The data is read from `data/polars/legislators-historical.csv`, the columns this page " &
  "uses from the [congress-legislators](https://github.com/unitedstates/congress-legislators) " &
  "project (CC0), named as in the copy the user guide reads from Hugging Face. The results " &
  "are shown as tables instead of printed. The last section, on Python lambdas and the GIL, " &
  "is left out.")

nbText: """
The Polars [context](https://docs.pola.rs/user-guide/concepts/expressions-and-contexts/#contexts)
`group_by` lets you apply expressions on subsets of columns, as defined by the unique values
of the column over which the data is grouped. This is a very powerful capability that we
explore in this section of the user guide.

We start by reading in a
[US congress `dataset`](https://github.com/unitedstates/congress-legislators):
"""

tabs """
import polars as pl

url = "data/polars/legislators-historical.csv"

schema_overrides = {
    "first_name": pl.Categorical,
    "gender": pl.Categorical,
    "type": pl.Categorical,
    "state": pl.Categorical,
    "party": pl.Categorical,
}

dataset = (
    pl.read_csv(url, schema_overrides=schema_overrides)
    .with_columns(pl.col("first", "middle", "last").name.suffix("_name"))
    .with_columns(pl.col("birthday").str.to_date(strict=False))
)
dataset.head()
""":
  nbCode:
    import nanuq

    let url = "data/polars/legislators-historical.csv"

    let schemaOverrides = {
      "first_name": Categorical,
      "gender": Categorical,
      "type": Categorical,
      "state": Categorical,
      "party": Categorical,
    }

    let dataset = readCsv(url, schemaOverrides = schemaOverrides)
      .withColumns(col("first", "middle", "last").name.suffix("_name"))
      .withColumns(col.birthday.str.toDate(strict = false))
    nbShow dataset.head()

nanuq """
`first_name` is not a column of the file (it comes from the suffix step), so its
override does nothing, here and in Python.
"""

nbText: """
## Basic aggregations

You can easily apply multiple expressions to your aggregated values. Simply list all of the
expressions you want inside the function `agg`. There is no upper bound on the number of
aggregations you can do and you can make any combination you want. In the snippet below we
will group the data based on the column “first_name” and then we will apply the following
aggregations:

- count the number of rows in the group (which means we count how many people in the data
  set have each unique first name);
- combine the values of the column “gender” into a list by referring the column but omitting
  an aggregate function; and
- get the first value of the column “last_name” within the group.

After computing the aggregations, we immediately sort the result and limit it to the top
five rows so that we have a nice summary overview:
"""

tabs """
q = (
    dataset.lazy()
    .group_by("first_name")
    .agg(
        pl.len(),
        pl.col("gender"),
        pl.first("last_name"),  # Short for `pl.col("last_name").first()`
    )
    .sort("len", descending=True)
    .limit(5)
)

df = q.collect()
df
""":
  nbCode:
    var q = dataset.lazy
      .groupBy("first_name")
      .agg(
        len(),
        col.gender,
        col.last_name.first)
      .sort("len", descending = true)
      .limit(5)

    var df = q.collect
    nbShow df

nanuq """
Python's `pl.first("last_name")` is short for `pl.col("last_name").first()`; Nanuq has only
the long form. Ties in `len` (and which last name comes first in a group) depend on the
order the groups are processed in, so the two tabs can differ in those rows.
"""

nbText: """
It's that easy! Let's turn it up a notch.

## Conditionals

Let's say we want to know how many delegates of a state are “Pro” or “Anti”
administration. We can query that directly in the aggregation without the need for a
`lambda` or grooming the dataframe:
"""

tabs """
q = (
    dataset.lazy()
    .group_by("state")
    .agg(
        (pl.col("party") == "Anti-Administration").sum().alias("anti"),
        (pl.col("party") == "Pro-Administration").sum().alias("pro"),
    )
    .sort("pro", descending=True)
    .limit(5)
)

df = q.collect()
df
""":
  nbCode:
    q = dataset.lazy
      .groupBy("state")
      .agg(
        (col.party == "Anti-Administration").sum.alias("anti"),
        (col.party == "Pro-Administration").sum.alias("pro"))
      .sort("pro", descending = true)
      .limit(5)

    df = q.collect
    nbShow df

nbText: """
## Filtering

We can also filter the groups. Let's say we want to compute a mean per group, but we don't
want to include all values from that group, and we also don't want to actually filter the
rows from the dataframe because we need those rows for another aggregation.

In the example below we show how this can be done.

> **Note**: Note that we can define Python functions for clarity. These functions don't cost
> us anything because they return Polars expressions, we don't apply a custom function over
> a series during runtime of the query. Of course, you can write functions that return
> expressions in Rust, too.
"""

tabs """
from datetime import date


def compute_age():
    return date.today().year - pl.col("birthday").dt.year()


def avg_age(gender: str) -> pl.Expr:
    return (
        compute_age()
        .filter(pl.col("gender") == gender)
        .mean()
        .alias(f"avg {gender} age")
    )


q = (
    dataset.lazy()
    .group_by("state", maintain_order=True)
    .agg(
        avg_age("M"),
        avg_age("F"),
        (pl.col("gender") == "M").sum().alias("# male"),
        (pl.col("gender") == "F").sum().alias("# female"),
    )
    .limit(5)
)

df = q.collect()
df
""":
  nbCode:
    import std/times

    proc computeAge(): Expr =
      now().year - col.birthday.dt.year

    proc avgAge(gender: string): Expr =
      computeAge()
        .filter(col.gender == gender)
        .mean
        .alias("avg " & gender & " age")

    q = dataset.lazy
      .groupBy("state", maintainOrder = true)
      .agg(
        avgAge("M"),
        avgAge("F"),
        (col.gender == "M").sum.alias("# male"),
        (col.gender == "F").sum.alias("# female"))
      .limit(5)

    df = q.collect
    nbShow df

nanuq """
The same holds for Nim procs: `avgAge` runs once, to build the expression. Here and in
the first two sorting examples both tabs add `maintain_order=True` (`maintainOrder = true`):
without it, which five states come first changes from run to run.
"""

nbText: """
Do the average age values look nonsensical? That's because we are working with historical
data that dates back to the 1800s and we are doing our computations assuming everyone
represented in the dataset is still alive and kicking.

## Nested grouping

The two previous queries could have been done with a nested `group_by`, but that wouldn't
have let us show off some of these features. 😉 To do a nested `group_by`, simply list the
columns that will be used for grouping.

First, we use a nested `group_by` to figure out how many delegates of a state are “Pro” or
“Anti” administration:
"""

tabs """
q = (
    dataset.lazy()
    .group_by("state", "party")
    .agg(pl.len().alias("count"))
    .filter(
        (pl.col("party") == "Anti-Administration")
        | (pl.col("party") == "Pro-Administration")
    )
    .sort("count", descending=True)
    .limit(5)
)

df = q.collect()
df
""":
  nbCode:
    q = dataset.lazy
      .groupBy("state", "party")
      .agg(len().alias("count"))
      .filter(
        col.party == "Anti-Administration" or
        col.party == "Pro-Administration")
      .sort("count", descending = true)
      .limit(5)

    df = q.collect
    nbShow df

nbText: """
Next, we use a nested `group_by` to compute the average age of delegates per state and per
gender:
"""

tabs """
q = (
    dataset.lazy()
    .group_by("state", "gender")
    .agg(
        # The function `avg_age` is not needed:
        compute_age().mean().alias("avg age"),
        pl.len().alias("#"),
    )
    .sort("#", descending=True)
    .limit(5)
)

df = q.collect()
df
""":
  nbCode:
    q = dataset.lazy
      .groupBy("state", "gender")
      .agg(
        # The proc `avgAge` is not needed:
        computeAge().mean.alias("avg age"),
        len().alias("#"))
      .sort("#", descending = true)
      .limit(5)

    df = q.collect
    nbShow df

nbText: """
Note that we get the same results but the format of the data is different. Depending on the
situation, one format may be more suitable than the other.

## Sorting

It is common to see a dataframe being sorted for the sole purpose of managing the ordering
during a grouping operation. Let's say that we want to get the names of the oldest and
youngest politicians per state. We could start by sorting and then grouping:
"""

tabs """
def get_name() -> pl.Expr:
    return pl.col("first_name") + pl.lit(" ") + pl.col("last_name")


q = (
    dataset.lazy()
    .sort("birthday", descending=True)
    .group_by("state", maintain_order=True)
    .agg(
        get_name().first().alias("youngest"),
        get_name().last().alias("oldest"),
    )
    .limit(5)
)

df = q.collect()
df
""":
  nbCode:
    proc getName(): Expr =
      col.first_name + lit(" ") + col.last_name

    q = dataset.lazy
      .sort("birthday", descending = true)
      .groupBy("state", maintainOrder = true)
      .agg(
        getName().first.alias("youngest"),
        getName().last.alias("oldest"))
      .limit(5)

    df = q.collect
    nbShow df

nbText: """
However, if we also want to sort the names alphabetically, we need to perform an extra sort
operation. Luckily, we can sort in a `group_by` context without changing the sorting of the
underlying dataframe:
"""

tabs """
q = (
    dataset.lazy()
    .sort("birthday", descending=True)
    .group_by("state", maintain_order=True)
    .agg(
        get_name().first().alias("youngest"),
        get_name().last().alias("oldest"),
        get_name().sort().first().alias("alphabetical_first"),
    )
    .limit(5)
)

df = q.collect()
df
""":
  nbCode:
    q = dataset.lazy
      .sort("birthday", descending = true)
      .groupBy("state", maintainOrder = true)
      .agg(
        getName().first.alias("youngest"),
        getName().last.alias("oldest"),
        getName().sort.first.alias("alphabetical_first"))
      .limit(5)

    df = q.collect
    nbShow df

nbText: """
We can even sort a column with the order induced by another column, and this also works
inside the context `group_by`. This modification to the previous query lets us check if the
delegate with the first name is male or female:
"""

tabs """
q = (
    dataset.lazy()
    .sort("birthday", descending=True)
    .group_by("state")
    .agg(
        get_name().first().alias("youngest"),
        get_name().last().alias("oldest"),
        get_name().sort().first().alias("alphabetical_first"),
        pl.col("gender").sort_by(get_name()).first(),
    )
    .sort("state")
    .limit(5)
)

df = q.collect()
df
""":
  nbCode:
    q = dataset.lazy
      .sort("birthday", descending = true)
      .groupBy("state")
      .agg(
        getName().first.alias("youngest"),
        getName().last.alias("oldest"),
        getName().sort.first.alias("alphabetical_first"),
        col.gender.sortBy(getName()).first)
      .sort("state")
      .limit(5)

    df = q.collect
    nbShow df

bookSave()
