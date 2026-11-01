import nanuqbook
bookInit()

nbText: "# Textual and temporal data types"

attribution definitiveGuide(12, "Working with Textual, Temporal, and Nested Data Types",
  "The string, categorical, enum and temporal examples of the chapter; the data is read " &
  "from `data/definitive-guide/`. Left out: `str.split` with `list.get`, `extract_all`, " &
  "the string cache, `cat.get_categories`, the deprecated physical ordering of " &
  "categoricals, and the List, Array and Struct sections, which wait for nested types " &
  "in Nanuq.")

nbText: """
Beyond numbers, a column can hold text, a fixed set of categories, dates and times, or
nested values. Each of these types has its own namespace of expressions: `str`, `cat`,
`dt`, `list`, `arr` and `struct`. Nanuq 0.3 has the first three.

## String

### String Examples

Three messy lines of text:
"""

tabs """
import polars as pl

corpus = pl.DataFrame(
    {
        "raw_text": [
            "  Data Science is amazing ",
            "Data_analysis > Data entry",
            " Python&Polars; Fast",
        ]
    }
)

corpus
""":
  nbCode:
    import nanuq

    var corpus = newDataFrame:
      raw_text: ["  Data Science is amazing ", "Data_analysis > Data entry",
                 " Python&Polars; Fast"]

    nbShow corpus

nbText: "String expressions chain, each step working on the result of the one before:"

tabs """
corpus = corpus.with_columns(
    processed_text=pl.col("raw_text")
    .str.strip_chars()
    .str.to_lowercase()
    .str.replace_all("_", " ")
)
corpus
""":
  nbCode:
    corpus = corpus.withColumns(
      col.raw_text
        .str.stripChars
        .str.toLowercase
        .str.replaceAll("_", " ")
        .alias("processed_text"))
    nbShow corpus

tabs """
corpus.with_columns(
    first_5_chars=pl.col("processed_text").str.slice(0, 5),
)
""":
  nbCode:
    nbShow corpus.withColumns(col.processed_text.str.slice(0, 5).alias("first_5_chars"))

nanuq """
The book also takes the first and second word, with `str.split(" ")` and `list.get`.
`split` gives a list per row, and Nanuq has no list columns yet, so this cell keeps the
first five characters only.
"""

tabs """
corpus.with_columns(
    len_chars=pl.col("processed_text").str.len_chars(),
    len_bytes=pl.col("processed_text").str.len_bytes(),
    count_a=pl.col("processed_text").str.count_matches("a"),
)
""":
  nbCode:
    nbShow corpus.withColumns(
      col.processed_text.str.lenChars.alias("len_chars"),
      col.processed_text.str.lenBytes.alias("len_bytes"),
      col.processed_text.str.countMatches("a").alias("count_a"))

nbText: "Extracting all the hashtags of a post gives a list, so this one is Python only:"

python """
posts = pl.DataFrame(
    {"post": ["Loving #python and #polars!", "A boomer post without a hashtag"]}
)

hashtag_regex = r"#(\w+)"

posts.with_columns(
    hashtags=pl.col("post").str.extract_all(hashtag_regex)
)
"""

nbText: """
## Categorical

A categorical column stores each distinct string once, and a small integer per row: its
physical representation.
"""

tabs """
cats = pl.DataFrame(
    {"name": ["Persian cat", "Siamese Cat", "Lynx", "Lynx"]},
    schema={"name": pl.Categorical},
)

cats.with_columns(name_physical=pl.col("name").to_physical())
""":
  nbCode:
    let cats = newDataFrame(
        series("name", ["Persian cat", "Siamese Cat", "Lynx", "Lynx"]))
      .cast({"name": Categorical})

    nbShow cats.withColumns(col.name.toPhysical.alias("name_physical"))

nanuq """
Nanuq builds the frame from strings and casts it, with a mapping from column names to
types, where Python passes a `schema`.
"""

nbText: """
### Categorical Examples

A second frame with some of the same cats. In recent versions of Polars all categoricals share one
global set of categories, so the same name has the same code in both frames:
"""

tabs """
more_cats = pl.DataFrame(
    {"name": ["Maine Coon Cat", "Lynx", "Lynx", "Siamese Cat"]},
    schema={"name": pl.Categorical},
)

more_cats.with_columns(name_physical=pl.col("name").to_physical())
""":
  nbCode:
    let moreCats = newDataFrame(
        series("name", ["Maine Coon Cat", "Lynx", "Lynx", "Siamese Cat"]))
      .cast({"name": Categorical})

    nbShow moreCats.withColumns(col.name.toPhysical.alias("name_physical"))

tabs """
cats.join(more_cats, on="name")
""":
  nbCode:
    nbShow cats.join(moreCats, on = ["name"])

nanuq """
The book's next cells wrap the frames in `pl.StringCache()`, which older versions of
Polars needed to join two categorical columns. It is a no-op now, and Nanuq has no string
cache: joins on categoricals just work. The book's `cat.get_categories` is gone from
Python Polars 2; Nanuq keeps Rust's `cat.getCategories`.
"""

nbText: """
Sorting a categorical column sorts by the strings, not by the codes:
"""

tabs """
sorting_comparison_df = cats.select(cat_lexical=pl.col("name")).with_columns(
    cat_physical=pl.col("cat_lexical").to_physical()
)

sorting_comparison_df.sort(by="cat_lexical")
""":
  nbCode:
    let sortingComparisonDf = cats.select(col.name.alias("cat_lexical")).withColumns(
      col.cat_lexical.toPhysical.alias("cat_physical"))

    nbShow sortingComparisonDf.sort("cat_lexical")

nanuq """
The book compares physical with lexical ordering; physical ordering has been removed
from Polars since, so this cell sorts the frame directly instead of casting it to
`pl.Categorical("lexical")` first.
"""

nbText: """
## Enum

An `Enum` has a fixed list of categories, given up front, in order:
"""

tabs """
bear_enum_dtype = pl.Enum(["Polar", "Panda", "Brown"])

bear_enum_series = pl.Series(
    ["Polar", "Panda", "Brown", "Brown", "Polar"], dtype=bear_enum_dtype
)

bear_cat_series = pl.Series(
    ["Polar", "Panda", "Brown", "Brown", "Polar"], dtype=pl.Categorical
)

pl.DataFrame([bear_enum_series.alias("enum"), bear_cat_series.alias("cat")])
""":
  nbCode:
    type
      Bear = enum
        Polar, Panda, Brown

    let bearEnumSeries = series("enum", [Polar, Panda, Brown, Brown, Polar])

    let bearCatSeries = series("cat", ["Polar", "Panda", "Brown", "Brown", "Polar"])

    nbShow newDataFrame(bearEnumSeries, bearCatSeries).cast({"cat": Categorical})

nanuq """
A Nim enum is a Polars `Enum`: a Series of `Bear` values has the data type
`Enum(["Polar", "Panda", "Brown"])`. The book stops at the two Series; to show them,
both sides put them in one frame.
"""

nbText: """
## Temporal

### Temporal Examples

#### Loading from a CSV file

With `try_parse_dates`, the CSV reader recognises the dates:
"""

tabs """
pl.read_csv("data/definitive-guide/all_stocks.csv", try_parse_dates=True)
""":
  nbCode:
    nbShow readCsv("data/definitive-guide/all_stocks.csv", tryParseDates = true)

nbText: "#### Converting to and from a String"

tabs """
dates = pl.DataFrame({"date_str": ["2023-12-31", "2024-02-29"]}).with_columns(
    date=pl.col("date_str").str.to_date("%Y-%m-%d")
)

dates
""":
  nbCode:
    let dates = newDataFrame(series("date_str", ["2023-12-31", "2024-02-29"])).withColumns(
      col.date_str.str.toDate("%Y-%m-%d").alias("date"))

    nbShow dates

tabs """
dates.with_columns(formatted_date=pl.col("date").dt.to_string("%d-%m-%Y"))
""":
  nbCode:
    nbShow dates.withColumns(col("date").dt.toString("%d-%m-%Y").alias("formatted_date"))

nanuq """
`col("date")` with a string: `col.date` would be the `date` proc, Nanuq's date literal.
"""

nbText: "#### Generating date ranges"

tabs """
pl.DataFrame(
    {
        "monday": pl.date_range(
            start=pl.date(2024, 10, 28),
            end=pl.date(2024, 12, 1),
            interval="1w",
            eager=True,
        ),
    }
)
""":
  nbCode:
    nbShow newDataFrame().select(
      dateRange(start = date(2024, 10, 28), stop = date(2024, 12, 1), interval = 1.weeks)
        .alias("monday"))

nanuq """
`dateRange` is an expression: Nanuq has no eager version, so it is selected from an
empty frame. The interval can be a `std/times` interval, `1.weeks`, or Polars' `"1w"`;
the end is `stop`, since `end` is a Nim keyword.
"""

nbText: """
#### Time zones

Strings with mixed UTC offsets parse into one UTC column, which can then be shown in a
time zone:
"""

tabs """
pl.DataFrame(
    {
        "utc_mixed_offset": [
            "2021-03-27T00:00:00+0100",
            "2021-03-28T00:00:00+0100",
            "2021-03-29T00:00:00+0200",
            "2021-03-30T00:00:00+0200",
        ]
    }
).with_columns(
    parsed=pl.col("utc_mixed_offset").str.to_datetime(
        "%Y-%m-%dT%H:%M:%S%z"
    )
).with_columns(
    converted=pl.col("parsed").dt.convert_time_zone("Europe/Amsterdam")
)
""":
  nbCode:
    nbShow newDataFrame(series("utc_mixed_offset", [
        "2021-03-27T00:00:00+0100",
        "2021-03-28T00:00:00+0100",
        "2021-03-29T00:00:00+0200",
        "2021-03-30T00:00:00+0200"]))
      .withColumns(
        col.utc_mixed_offset.str.toDatetime("%Y-%m-%dT%H:%M:%S%z").alias("parsed"))
      .withColumns(
        col.parsed.dt.convertTimeZone("Europe/Amsterdam").alias("converted"))

nanuq """
The chapter goes on with List, Array and Struct columns. Nanuq has no nested types yet,
so those sections are left out; they come with a later release.
"""

bookSave()
