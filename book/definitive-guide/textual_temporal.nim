import nanuqbook
bookInit()

nbText: "# Textual and temporal data types"

attribution definitiveGuide(12, "Working with Textual, Temporal, and Nested Data Types",
  "The string, categorical, enum and temporal examples of the chapter; the data is read " &
  "from `data/definitive-guide/`. Left out: the string cache, `cat.get_categories` and " &
  "the deprecated physical ordering of categoricals.")

nbText: """
Beyond numbers, a column can hold text, a fixed set of categories, dates and times, or
nested values. Each of these types has its own namespace of expressions: `str`, `cat`,
`dt`, `list`, `arr` and `struct`. Nanuq has all six.

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
    first_word=pl.col("processed_text")
    .str.split(" ")
    .list.get(0),
    second_word=pl.col("processed_text").str.split(" ").list.get(1),
)
""":
  nbCode:
    nbShow corpus.withColumns(
      col.processed_text.str.slice(0, 5).alias("first_5_chars"),
      col.processed_text
        .str.split(" ")
        .list.get(0)
        .alias("first_word"),
      col.processed_text.str.split(" ").list.get(1).alias("second_word"))

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

nbText: "Extracting all the hashtags of a post gives a list per row:"

tabs """
posts = pl.DataFrame(
    {"post": ["Loving #python and #polars!", "A boomer post without a hashtag"]}
)

hashtag_regex = r"#(\w+)"

posts.with_columns(
    hashtags=pl.col("post").str.extract_all(hashtag_regex)
)
""":
  nbCode:
    let posts = newDataFrame:
      post: ["Loving #python and #polars!", "A boomer post without a hashtag"]

    let hashtagRegex = r"#(\w+)"

    nbShow posts.withColumns(col.post.str.extractAll(hashtagRegex).alias("hashtags"))

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

nbText: """
## List

### List Examples

A list column holds a list of values of the same type in each row, of any length. Some
list methods reduce each list to one value:
"""

tabs """
bools = pl.DataFrame({"values": [[True, True], [False, False, True], [False]]})

bools.with_columns(
    all_true=pl.col("values").list.all(),
    any_true=pl.col("values").list.any(),
)
""":
  nbCode:
    let bools = newDataFrame:
      values: [@[true, true], @[false, false, true], @[false]]

    nbShow bools.withColumns(
      col.values.list.all.alias("all_true"),
      col.values.list.any.alias("any_true"))

nbText: "`list.eval` runs any expression on the values of each list, with `pl.element()` standing for them:"

tabs """
groups = pl.DataFrame({"ages": [[18, 21], [30, 40, 50], [42, 69]]})

groups.with_columns(
    over_forty=pl.col("ages").list.eval(
        pl.element() > 40,
        parallel=True,
    )
).with_columns(
    all_over_forty=pl.col("over_forty").list.all()
)
""":
  nbCode:
    let groups = newDataFrame:
      ages: [@[18, 21], @[30, 40, 50], @[42, 69]]

    nbShow groups.withColumns(
      col.ages.list.eval(element() > 40).alias("over_forty")
    ).withColumns(
      col.over_forty.list.all.alias("all_over_forty"))

tabs """
groups.with_columns(
    ages_sorted_descending=pl.col("ages").list.sort(descending=True)
)
""":
  nbCode:
    nbShow groups.withColumns(
      col.ages.list.sort(descending = true).alias("ages_sorted_descending"))

nbText: "Exploding gives one row per value, on the frame or on one column:"

tabs """
groups.explode("ages")
""":
  nbCode:
    nbShow groups.explode("ages")

tabs """
groups.select(ages=pl.col("ages").list.explode())
""":
  nbCode:
    nbShow groups.select(col.ages.list.explode.alias("ages"))

nbText: """
## Array

### Array Examples

An array column holds the same number of values in every row, like a week of
temperatures:
"""

tabs """
events = pl.DataFrame(
    [
        pl.Series(
            "location", ["Paris", "Amsterdam", "Barcelona"], dtype=pl.String
        ),
        pl.Series(
            "temperatures",
            [
                [23, 27, 21, 22, 24, 23, 22],
                [17, 19, 15, 22, 18, 20, 21],
                [30, 32, 28, 29, 34, 33, 31],
            ],
            dtype=pl.Array(pl.Int64, shape=7),
        ),
    ]
)

events
""":
  nbCode:
    let events = newDataFrame(
      series("location", ["Paris", "Amsterdam", "Barcelona"]),
      series("temperatures", [
        [23, 27, 21, 22, 24, 23, 22],
        [17, 19, 15, 22, 18, 20, 21],
        [30, 32, 28, 29, 34, 33, 31]]))

    nbShow events

nanuq """
No `dtype` needed: a Nim `array[7, int]` is an `Array(Int64, 7)` already.
"""

tabs """
events.with_columns(
    median=pl.col("temperatures").arr.median(),
    max=pl.col("temperatures").arr.max(),
    warmest_dow=pl.col("temperatures").arr.arg_max(),
)
""":
  nbCode:
    nbShow events.withColumns(
      col.temperatures.arr.median.alias("median"),
      col.temperatures.arr.max.alias("max"),
      col.temperatures.arr.argMax.alias("warmest_dow"))

nbText: """
## Struct

### Struct Examples

A struct column holds a few named fields in each row:
"""

tabs """
from datetime import date

orders = pl.DataFrame(
    {
        "customer_id": [2781, 6139, 5392],
        "order_details": [
            {"amount": 250.00, "date": date(2024, 1, 3), "items": 5},
            {"amount": 150.00, "date": date(2024, 1, 5), "items": 1},
            {"amount": 100.00, "date": date(2024, 1, 2), "items": 3},
        ],
    },
)

orders
""":
  nbCode:
    let orders = newDataFrame:
      customer_id: [2781, 6139, 5392]
      order_details: [
        (amount: 250.00, date: date(2024, 1, 3), items: 5),
        (amount: 150.00, date: date(2024, 1, 5), items: 1),
        (amount: 100.00, date: date(2024, 1, 2), items: 3)]

    nbShow orders

nanuq """
A Python dict is a named tuple in Nim; Nanuq's `date(y, m, d)` gives a Polars `Date`.
"""

tabs """
orders.select(pl.col("order_details").struct.field("amount"))
""":
  nbCode:
    nbShow orders.select(col.order_details.struct.field("amount"))

tabs """
order_details_df = orders.unnest("order_details")

order_details_df
""":
  nbCode:
    let orderDetails = orders.unnest("order_details")

    nbShow orderDetails

tabs """
order_details_df.select(
    "amount",
    "date",
    "items",
    order_details=pl.struct(pl.col("amount"), pl.col("date"), pl.col("items")),
)
""":
  nbCode:
    nbShow orderDetails.select(
      col.amount,
      col("date"),
      col.items,
      asStruct(col.amount, col("date"), col.items).alias("order_details"))

nanuq """
`pl.struct` is `asStruct` in Nanuq: `struct` is the namespace.
"""

nbText: "`value_counts` gives a struct per distinct value, with the value and its count:"

tabs """
basket = pl.DataFrame(
    {
        "fruit": ["cherry", "apple", "banana", "banana", "apple", "banana"],
    }
)

basket
""":
  nbCode:
    let basket = newDataFrame:
      fruit: ["cherry", "apple", "banana", "banana", "apple", "banana"]

    nbShow basket

tabs """
basket.select(pl.col("fruit").value_counts(sort=True))
""":
  nbCode:
    nbShow basket.select(col.fruit.valueCounts(sort = true))

tabs """
basket.select(pl.col("fruit").value_counts(sort=True).struct.unnest())
""":
  nbCode:
    nbShow basket.select(col.fruit.valueCounts(sort = true).struct.unnest)

bookSave()
