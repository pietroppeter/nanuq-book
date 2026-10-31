import nanuqbook
bookInit()

nbText: "# Getting started"

attribution userGuide("Getting started", "getting-started",
  "Left out: the installation instructions (see the Nanuq README instead) and the " &
  "“more complex query”, which splits names into lists and aggregates into lists, and " &
  "Nanuq has no lists yet. The CSV file is written to `data/output.csv`.")

nbText: """
This chapter is here to help you get started with Polars. It covers all the fundamental
features and functionalities of the library, making it easy for new users to familiarise
themselves with the basics from initial installation and setup to core functionalities. If
you're already an advanced user or familiar with dataframes, feel free to skip ahead to the
[next chapter about installation options](https://docs.pola.rs/user-guide/installation/).
"""

nanuq """
To install Nanuq, see its [README](https://github.com/pietroppeter/nanuq#readme): it is a
Nim package that downloads a prebuilt Polars library the first time you compile.
"""

nbText: """
## Reading & writing

Polars supports reading and writing for common file formats (e.g., csv, json, parquet),
cloud storage (S3, Azure Blob, BigQuery) and databases (e.g., postgres, mysql). Below, we
create a small dataframe and show how to write it to disk and read it back.
"""

tabs """
import polars as pl
import datetime as dt

df = pl.DataFrame(
    {
        "name": ["Alice Archer", "Ben Brown", "Chloe Cooper", "Daniel Donovan"],
        "birthdate": [
            dt.date(1997, 1, 10),
            dt.date(1985, 2, 15),
            dt.date(1983, 3, 22),
            dt.date(1981, 4, 30),
        ],
        "weight": [57.9, 72.5, 53.6, 83.1],  # (kg)
        "height": [1.56, 1.77, 1.65, 1.75],  # (m)
    }
)

df
""":
  nbCode:
    import nanuq

    let df = newDataFrame:
      name: ["Alice Archer", "Ben Brown", "Chloe Cooper", "Daniel Donovan"]
      birthdate: [date(1997, 1, 10), date(1985, 2, 15), date(1983, 3, 22), date(1981, 4, 30)]
      weight: [57.9, 72.5, 53.6, 83.1]  # (kg)
      height: [1.56, 1.77, 1.65, 1.75]  # (m)

    nbShow df

nanuq """
Nanuq has dates since 0.3: `date(1997, 1, 10)` is a Nanuq `Date`, Polars' `Date` type.
"""

nbText: """
In the example below we write the dataframe to a csv file called `output.csv`. After that,
we read it back using `read_csv` and then print the result for inspection.
"""

tabs """
df.write_csv("data/output.csv")
df_csv = pl.read_csv("data/output.csv", try_parse_dates=True)
df_csv
""":
  nbCode:
    df.writeCsv("data/output.csv")
    let dfCsv = readCsv("data/output.csv", tryParseDates = true)
    nbShow dfCsv

nbText: """
For more examples on the CSV file format and other data formats, see the
[IO section](https://docs.pola.rs/user-guide/io/) of the user guide.

## Expressions and contexts

_Expressions_ are one of the main strengths of Polars because they provide a modular and
flexible way of expressing data transformations.

Here is an example of a Polars expression:

```py
pl.col("weight") / (pl.col("height") ** 2)
```

As you might be able to guess, this expression takes the column named “weight” and divides
its values by the square of the values in the column “height”, computing a person's BMI.
Note that the code above expresses an abstract computation: it's only inside a Polars
_context_ that the expression materalizes into a series with the results.
"""

nanuq """
In Nim the same expression is `col.weight / (col.height ^ 2)`: `^` is Nim's power
operator, and `col.weight` is short for `col("weight")`.
"""

nbText: """
Below, we will show examples of Polars expressions inside different contexts:

- `select`
- `with_columns`
- `filter`
- `group_by`

For a more
[detailed exploration of expressions and contexts see the respective user guide section](expressions_and_contexts.html).

### `select`

The context `select` allows you to select and manipulate columns from a dataframe. In the
simplest case, each expression you provide will map to a column in the result dataframe:
"""

tabs """
df.select(
    pl.col("name"),
    pl.col("birthdate").dt.year().alias("birth_year"),
    (pl.col("weight") / (pl.col("height") ** 2)).alias("bmi"),
)
""":
  nbCode:
    nbShow df.select(
      col.name,
      col.birthdate.dt.year.alias("birth_year"),
      (col.weight / (col.height ^ 2)).alias("bmi"))

nbText: """
Polars also supports a feature called “expression expansion”, in which one expression acts
as shorthand for multiple expressions. In the example below, we use expression expansion to
manipulate the columns “weight” and “height” with a single expression. When using
expression expansion you can use `.name.suffix` to add a suffix to the names of the
original columns:
"""

tabs """
df.select(
    pl.col("name"),
    (pl.col("weight", "height") * 0.95).round(2).name.suffix("-5%"),
)
""":
  nbCode:
    nbShow df.select(
      col.name,
      (col("weight", "height") * 0.95).round(2).name.suffix("-5%"))

nbText: """
You can check other sections of the user guide to learn more about
[basic operations](basic_operations.html) or
[column selections in expression expansion](expression_expansion.html).

### `with_columns`

The context `with_columns` is very similar to the context `select` but `with_columns` adds
columns to the dataframe instead of selecting them. Notice how the resulting dataframe
contains the four columns of the original dataframe plus the two new columns introduced by
the expressions inside `with_columns`:
"""

tabs """
df.with_columns(
    birth_year=pl.col("birthdate").dt.year(),
    bmi=pl.col("weight") / (pl.col("height") ** 2),
)
""":
  nbCode:
    nbShow df.withColumns(
      col.birthdate.dt.year.alias("birth_year"),
      (col.weight / (col.height ^ 2)).alias("bmi"))

nbText: """
In the example above we also decided to use named expressions instead of the method `alias`
to specify the names of the new columns. Other contexts like `select` and `group_by` also
accept named expressions.
"""

nanuq """
Nim has no named expressions: the name always comes from `alias`.
"""

nbText: """
### `filter`

The context `filter` allows us to create a second dataframe with a subset of the rows of the
original one:
"""

tabs """
df.filter(pl.col("birthdate").dt.year() < 1990)
""":
  nbCode:
    nbShow df.filter(col.birthdate.dt.year < 1990)

nbText: """
You can also provide multiple predicate expressions as separate parameters, which is more
convenient than putting them all together with `&`:
"""

tabs """
df.filter(
    pl.col("birthdate").is_between(dt.date(1982, 12, 31), dt.date(1996, 1, 1)),
    pl.col("height") > 1.7,
)
""":
  nbCode:
    nbShow df.filter(
      col.birthdate.isBetween(date(1982, 12, 31), date(1996, 1, 1)) and
      col.height > 1.7)

nanuq """
Nanuq's `filter` takes one predicate, so the two are joined with `and`.
"""

nbText: """
### `group_by`

The context `group_by` can be used to group together the rows of the dataframe that share
the same value across one or more expressions. The example below counts how many people
were born in each decade:
"""

tabs """
df.group_by(
    (pl.col("birthdate").dt.year() // 10 * 10).alias("decade"),
    maintain_order=True,
).len()
""":
  nbCode:
    nbShow df.groupBy((col.birthdate.dt.year div 10 * 10).alias("decade"))
      .agg(col.name.len.alias("len"))
      .collect

nbText: """
The keyword argument `maintain_order` forces Polars to present the resulting groups in the
same order as they appear in the original dataframe. This slows down the grouping operation
but is used here to ensure reproducibility of the examples.
"""

nanuq """
Nanuq's `groupBy` always keeps the groups in the order they first appear. Python's `//` is
`div`, and the group-by `len()` shortcut is `len` on any column inside `agg`.
"""

nbText: """
After using the context `group_by` we can use `agg` to compute aggregations over the
resulting groups:
"""

tabs """
df.group_by(
    (pl.col("birthdate").dt.year() // 10 * 10).alias("decade"),
    maintain_order=True,
).agg(
    pl.len().alias("sample_size"),
    pl.col("weight").mean().round(2).alias("avg_weight"),
    pl.col("height").max().alias("tallest"),
)
""":
  nbCode:
    nbShow df.groupBy((col.birthdate.dt.year div 10 * 10).alias("decade"))
      .agg(
        col.name.len.alias("sample_size"),
        col.weight.mean.round(2).alias("avg_weight"),
        col.height.max.alias("tallest"))
      .collect

nbText: """
### More complex queries

Contexts and the expressions within can be chained to create more complex queries according
to your needs.
"""

nanuq """
The guide's example here keeps the first name with `str.split(by=" ").list.first()` and
collects the names of each decade into a list. Nanuq has no lists yet, so the example is
left out.
"""

nbText: """
## Combining dataframes

Polars provides a number of tools to combine two dataframes. In this section, we show an
example of a join and an example of a concatenation.

### Joining dataframes

Polars provides many different join algorithms. The example below shows how to use a left
outer join to combine two dataframes when a column can be used as a unique identifier to
establish a correspondence between rows across the dataframes:
"""

tabs """
df2 = pl.DataFrame(
    {
        "name": ["Ben Brown", "Daniel Donovan", "Alice Archer", "Chloe Cooper"],
        "parent": [True, False, False, False],
        "siblings": [1, 2, 3, 4],
    }
)

df.join(df2, on="name", how="left")
""":
  nbCode:
    let df2 = newDataFrame:
      name: ["Ben Brown", "Daniel Donovan", "Alice Archer", "Chloe Cooper"]
      parent: [true, false, false, false]
      siblings: [1, 2, 3, 4]

    nbShow df.join(df2, on = ["name"], how = Left)

nbText: """
Polars provides many different join algorithms that you can learn about in the
[joins section of the user guide](joins.html).

### Concatenating dataframes

Concatenating dataframes creates a taller or wider dataframe, depending on the method used.
Assuming we have a second dataframe with data from other people, we could use vertical
concatenation to create a taller dataframe:
"""

tabs """
df3 = pl.DataFrame(
    {
        "name": ["Ethan Edwards", "Fiona Foster", "Grace Gibson", "Henry Harris"],
        "birthdate": [
            dt.date(1977, 5, 10),
            dt.date(1975, 6, 23),
            dt.date(1973, 7, 22),
            dt.date(1971, 8, 3),
        ],
        "weight": [67.9, 72.5, 57.6, 93.1],  # (kg)
        "height": [1.76, 1.6, 1.66, 1.8],  # (m)
    }
)

pl.concat([df, df3], how="vertical")
""":
  nbCode:
    let df3 = newDataFrame:
      name: ["Ethan Edwards", "Fiona Foster", "Grace Gibson", "Henry Harris"]
      birthdate: [date(1977, 5, 10), date(1975, 6, 23), date(1973, 7, 22), date(1971, 8, 3)]
      weight: [67.9, 72.5, 57.6, 93.1]  # (kg)
      height: [1.76, 1.6, 1.66, 1.8]  # (m)

    nbShow concat([df, df3], how = Vertical)

nbText: """
Polars provides vertical and horizontal concatenation, as well as diagonal concatenation.
You can learn more about these in the [concatenations section of the user guide](concatenation.html).
"""

bookSave()
