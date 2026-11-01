import nanuqbook
bookInit()

nbText: "# Selecting and creating columns"

attribution definitiveGuide(10, "Selecting and Creating Columns",
  "The data is read from `data/definitive-guide/`. Python's column slices `rebels[:, :6]` " &
  "are `select`s by name here. Left out: selecting by position (`cs.by_index`), most of " &
  "combining selectors with set operations, the cells that the book shows raising an " &
  "error, and `cut`, which Nanuq does not have yet.")

nbText: """
Most of what you do to a frame comes down to two verbs: `select`, which keeps the columns
you name (and computes new ones), and `withColumns`, which keeps all the columns and adds
or replaces some. This chapter plays with both on a table of Star Wars characters, reduced
to three rebels.
"""

tabs """
import polars as pl

starwars = pl.read_parquet("data/definitive-guide/starwars.parquet")
rebels = starwars.drop("films").filter(
    pl.col("name").is_in(["Luke Skywalker", "Leia Organa", "Han Solo"])
)

rebels[:, :6]
""":
  nbCode:
    import nanuq

    let starwars = readParquet("data/definitive-guide/starwars.parquet")
    let rebels = starwars.drop("films").filter(
      col.name.isIn(["Luke Skywalker", "Leia Organa", "Han Solo"]))

    nbShow rebels.select(col("name", "height", "mass", "hair_color", "skin_color", "eye_color"))

tabs """
rebels[:, 6:11]
""":
  nbCode:
    nbShow rebels.select(col("birth_year", "sex", "gender", "homeworld", "species"))

tabs """
rebels[:, 11:]
""":
  nbCode:
    nbShow rebels.select(col("vehicles", "starships", "birth_date", "screen_time"))

nanuq """
Nanuq has no `df[rows, columns]` indexing: columns are picked by name with `select`.
The list columns, `vehicles` and `starships`, come through and print, but Nanuq has no
functions for lists yet.
"""

nbText: """
## Selecting Columns

`select` takes column names, `col` expressions, regular expressions on the names, and new
columns computed from the old ones:
"""

tabs """
rebels.select(
    "name",
    pl.col("homeworld"),
    pl.col("^.*_color$"),
    (pl.col("height") / 100).alias("height_m"),
)
""":
  nbCode:
    nbShow rebels.select(
      col.name,
      col.homeworld,
      col("^.*_color$"),
      (col.height / 100).alias("height_m"))

nanuq """
Nim's `select` takes expressions only, so a bare name is `col.name`. The height is a
`UInt16`; dividing it gives floats, with true division in Nanuq 0.3 as in Python.
"""

nbText: """
### Introducing Selectors

Selectors pick columns by name, type or position, and can be combined like sets.
"""

python """
import polars.selectors as cs

rebels.select(
    "name",
    cs.by_name("homeworld"),
    cs.matches("^.*_color$"),
    (cs.by_name("height") / 100).alias("height_m"),
)
"""

nanuq """
The book has `cs.by_name("^.*_color$")`, but since Python Polars 2.0 `by_name` takes
names only, not regular expressions, so this page uses `cs.matches`.
"""

nanuq """
Nanuq has no `polars.selectors` module. Its selectors are `col` with several names
(`col("a", "b")`), with Nim types (`col(string)`, `col(SomeNumber)`), with a regular
expression, and `all()`, which can `exclude` names. The cells below use them in place of
the `cs` functions.
"""

nbText: "### Selecting Based on Name"

tabs """
rebels.select(cs.starts_with("birth_"))
""":
  nbCode:
    nbShow rebels.select(col("^birth_.*$"))

tabs """
rebels.select(cs.ends_with("_color"))
""":
  nbCode:
    nbShow rebels.select(col("^.*_color$"))

tabs """
rebels.select(cs.contains("_"))
""":
  nbCode:
    nbShow rebels.select(col("^.*_.*$"))

tabs """
rebels.select(cs.matches("^[a-z]{4}$"))
""":
  nbCode:
    nbShow rebels.select(col("^[a-z]{4}$"))

nanuq """
A regular expression in `col` must match the whole name, from `^` to `$`; `starts_with`,
`ends_with` and `contains` become `^birth_.*$`, `^.*_color$` and `^.*_.*$`.
"""

nbText: "### Selecting Based on Data Type"

tabs """
rebels.group_by("hair_color").agg(cs.numeric().mean())
""":
  nbCode:
    nbShow rebels.groupBy(col.hair_color).agg(col(SomeNumber).mean).collect

tabs """
rebels.select(cs.string())
""":
  nbCode:
    nbShow rebels.select(col(string))

tabs """
rebels.select(cs.temporal())
""":
  nbCode:
    nbShow rebels.select(col(Date, Duration))

nanuq """
`cs.temporal()` is every date, time, datetime and duration column; in Nim you name the
types, `col(Date, Duration)`, with the `Duration` of `std/times`. The book also selects
the list columns with `cs.by_dtype(pl.List(pl.String))`, which Nanuq cannot spell yet.
"""

nbText: """
### Selecting Based on Position

Python only: Nanuq has no `by_index`.
"""

python """
rebels.select("name", cs.by_index(range(-2, 0)))
"""

nbText: """
### Combining Selectors

Selectors combine with `|` (union), `&` (intersection), `-` (difference), `^` and `~`
(complement):
"""

python """
rebels.select(cs.by_name("hair_color") | cs.numeric())
"""

nanuq """
Nanuq's selectors have no set operations yet. Unions of types work, `col(float, int)`, and
so does a difference with names, `all().exclude("name")`; mixing names and types, as here,
does not.
"""

nbText: """
## Creating Columns

`withColumns` adds new columns, here the body mass index of each rebel:
"""

tabs """
rebels.with_columns(bmi=pl.col("mass") / ((pl.col("height") / 100) ** 2))
""":
  nbCode:
    nbShow rebels.withColumns((col.mass / pow(col.height / 100, 2)).alias("bmi"))

nanuq """
Python's keyword arguments, `bmi=...`, are `alias` in Nim; `**` is `pow`.
"""

nbText: "An expression on an existing column, without a new name, replaces it:"

tabs """
df = pl.DataFrame({"a": [1, 2, 3]})
df.with_columns(pl.col("a") * 2)
""":
  nbCode:
    let df = newDataFrame:
      a: [1, 2, 3]
    nbShow df.withColumns(col.a * 2)

tabs """
df.with_columns(a2=pl.col("a") * 2)
""":
  nbCode:
    nbShow df.withColumns((col.a * 2).alias("a2"))

nbText: """
Several columns at once. The second one is the rebels' age in whole years on the day
*Return of the Jedi* came out:
"""

tabs """
rebels.with_columns(
    bmi=pl.col("mass") / ((pl.col("height") / 100) ** 2),
    age_destroy=(
        (pl.date(1983, 5, 25) - pl.col("birth_date")).dt.total_days() / 365
    ).cast(pl.UInt8),
)
""":
  nbCode:
    nbShow rebels.withColumns(
      (col.mass / pow(col.height / 100, 2)).alias("bmi"),
      ((date(1983, 5, 25) - col.birth_date).dt.totalDays / 365).cast(uint8)
        .alias("age_destroy"))

nanuq """
`date(1983, 5, 25)` is a date literal in Nanuq 0.3. Subtracting a date column from it
gives a duration, and the `dt` namespace has `totalDays`.
"""

nbText: """
The columns in one `withColumns` are computed side by side, so one cannot use another:
the book shows that referring to `bmi` in the same call raises a `ColumnNotFoundError`,
and that two calls in a row work. That example bins the BMI with `cut`, which Nanuq does
not have yet:
"""

python """
(
    rebels.with_columns(
        bmi=pl.col("mass") / ((pl.col("height") / 100) ** 2)
    ).with_columns(
        bmi_cat=pl.col("bmi").cut(
            [18.5, 25], labels=["Underweight", "Normal", "Overweight"]
        )
    )
)
"""

nbText: "`select` creates columns too. The five characters with the highest BMI:"

tabs """
(
    starwars.select(
        "name",
        (pl.col("mass") / ((pl.col("height") / 100) ** 2)).alias("bmi"),
        "species",
    )
    .drop_nulls()
    .top_k(5, by="bmi")
)
""":
  nbCode:
    nbShow starwars.select(
        col.name,
        (col.mass / pow(col.height / 100, 2)).alias("bmi"),
        col.species)
      .dropNulls()
      .sort("bmi", descending = true)
      .head(5)

nanuq """
Nanuq has no `top_k` yet: a descending `sort` and `head` give the same rows.
"""

nbText: "A literal is broadcast to every row:"

tabs """
df.with_columns(pl.lit(1).alias("ones"))
""":
  nbCode:
    nbShow df.withColumns(lit(1).alias("ones"))

tabs """
df.select(pl.all(), pl.lit(1).alias("ones"))
""":
  nbCode:
    nbShow df.select(all(), lit(1).alias("ones"))

nbText: """
## Related Column Operations

### Dropping

With `strict=False`, names that are not in the frame (here `screen_time` is, but it
need not be) are ignored:
"""

tabs """
rebels.drop("name", "screen_time", strict=False)
""":
  nbCode:
    nbShow rebels.drop(["name", "screen_time"], strict = false)

tabs """
rebels.select(~cs.by_name("name", "screen_time"))
""":
  nbCode:
    nbShow rebels.select(all().exclude("name", "screen_time"))

tabs """
rebels.select(cs.exclude("name", "screen_time"))
""":
  nbCode:
    nbShow rebels.select(all().exclude("name", "screen_time"))

nbText: "### Renaming"

tabs """
(
    rebels.rename({"homeworld": "planet", "mass": "weight"})
    .rename(lambda s: s.removesuffix("_color"))
    .select("name", "planet", "weight", "hair", "skin", "eye")
)
""":
  nbCode:
    nbShow rebels.rename({"homeworld": "planet", "mass": "weight"})
      .rename({"hair_color": "hair", "skin_color": "skin", "eye_color": "eye"})
      .select(col("name", "planet", "weight", "hair", "skin", "eye"))

nanuq """
`rename` takes a mapping, written with Nim's table constructor `{"a": "b"}`, but not a
function of the old name yet, so the second call names the three columns.
"""

nbText: "### Stacking"

tabs """
rebel_names = rebels.select("name")
rebel_colors = rebels.select(cs.ends_with("_color"))
rebel_quotes = pl.Series(
    "quote",
    [
        "You know, sometimes I amaze myself.",
        "That doesn't sound too hard.",
        "I have a bad feeling about this.",
    ],
)

(rebel_names.hstack(rebel_colors).hstack([rebel_quotes]))
""":
  nbCode:
    let rebelNames = rebels.select(col.name)
    let rebelColors = rebels.select(col("^.*_color$"))
    let rebelQuotes = newDataFrame(series("quote", [
      "You know, sometimes I amaze myself.",
      "That doesn't sound too hard.",
      "I have a bad feeling about this."]))

    nbShow concat([rebelNames, rebelColors, rebelQuotes], how = Horizontal)

nanuq """
Nanuq has no `hstack`: a horizontal `concat` of frames does the same.
"""

nbText: "### Adding Row Indices"

tabs """
rebels.with_row_index(name="rebel_id", offset=1)
""":
  nbCode:
    nbShow rebels.withRowIndex(name = "rebel_id", offset = 1)

bookSave()
