import nanuqbook
bookInit()

nbText: "# Expression expansion"

attribution userGuide("Expression expansion", "expressions/expression-expansion",
  "Dtypes are selected with Nim types (`col(float)` for `pl.col(pl.Float64)`). Left out: " &
  "`name.map` (it needs a Nim callback), the `polars.selectors` module with its set " &
  "operations, and the check that mixing names and dtypes in one `col` is an error, since " &
  "in Nim that call does not compile in the first place.")

nbText: """
As you've seen in
[the section about expressions and contexts](https://docs.pola.rs/user-guide/concepts/expressions-and-contexts/),
expression expansion is a feature that enables you to write a single expression that can
expand to multiple different expressions, possibly depending on the schema of the context
in which the expression is used.

This feature isn't just decorative or syntactic sugar. It allows for a very powerful
application of [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself) principles in
your code: a single expression that specifies multiple columns expands into a list of
expressions, which means you can write one single expression and reuse the computation
that it represents.

In this section we will show several forms of expression expansion and we will be using the
dataframe that you can see below for that effect:
"""

tabs """
import polars as pl

df = pl.DataFrame(
    {  # As of 14th October 2024, ~3pm UTC
        "ticker": ["AAPL", "NVDA", "MSFT", "GOOG", "AMZN"],
        "company_name": ["Apple", "NVIDIA", "Microsoft", "Alphabet (Google)", "Amazon"],
        "price": [229.9, 138.93, 420.56, 166.41, 188.4],
        "day_high": [231.31, 139.6, 424.04, 167.62, 189.83],
        "day_low": [228.6, 136.3, 417.52, 164.78, 188.44],
        "year_high": [237.23, 140.76, 468.35, 193.31, 201.2],
        "year_low": [164.08, 39.23, 324.39, 121.46, 118.35],
    }
)
df
""":
  nbCode:
    import nanuq

    # As of 14th October 2024, ~3pm UTC
    let df = newDataFrame(
      series("ticker", ["AAPL", "NVDA", "MSFT", "GOOG", "AMZN"]),
      series("company_name", ["Apple", "NVIDIA", "Microsoft", "Alphabet (Google)", "Amazon"]),
      series("price", [229.9, 138.93, 420.56, 166.41, 188.4]),
      series("day_high", [231.31, 139.6, 424.04, 167.62, 189.83]),
      series("day_low", [228.6, 136.3, 417.52, 164.78, 188.44]),
      series("year_high", [237.23, 140.76, 468.35, 193.31, 201.2]),
      series("year_low", [164.08, 39.23, 324.39, 121.46, 118.35]))
    nbShow df

nbText: """
## Function `col`

The function `col` is the most common way of making use of expression expansion features
in Polars. Typically used to refer to one column of a dataframe, in this section we explore
other ways in which you can use `col` (or its variants, when in Rust).

### Explicit expansion by column name

The simplest form of expression expansion happens when you provide multiple column names
to the function `col`.

The example below uses a single function `col` with multiple column names to convert the
values in USD to EUR:
"""

tabs """
eur_usd_rate = 1.09  # As of 14th October 2024

result = df.with_columns(
    (
        pl.col(
            "price",
            "day_high",
            "day_low",
            "year_high",
            "year_low",
        )
        / eur_usd_rate
    ).round(2)
)
result
""":
  nbCode:
    const eurUsdRate = 1.09  # As of 14th October 2024

    let result = df.withColumns(
      (col("price", "day_high", "day_low", "year_high", "year_low") / eurUsdRate).round(2))
    nbShow result

nbText: """
When you list the column names you want the expression to expand to, you can predict what
the expression will expand to. In this case, the expression that does the currency
conversion is expanded to a list of five expressions:
"""

tabs """
exprs = [
    (pl.col("price") / eur_usd_rate).round(2),
    (pl.col("day_high") / eur_usd_rate).round(2),
    (pl.col("day_low") / eur_usd_rate).round(2),
    (pl.col("year_high") / eur_usd_rate).round(2),
    (pl.col("year_low") / eur_usd_rate).round(2),
]

result2 = df.with_columns(exprs)
print(result.equals(result2))
""":
  nbCode:
    let exprs = [
      (col("price") / eurUsdRate).round(2),
      (col("day_high") / eurUsdRate).round(2),
      (col("day_low") / eurUsdRate).round(2),
      (col("year_high") / eurUsdRate).round(2),
      (col("year_low") / eurUsdRate).round(2),
    ]

    let result2 = df.withColumns(exprs)
    echo $result == $result2

nanuq """
Nanuq does not have `DataFrame.equals` yet, so the Nim version compares the two frames as
text.
"""

nbText: """
### Expansion by data type

We had to type five column names in the previous example but the function `col` can also
conveniently accept one or more data types. If you provide data types instead of column
names, the expression is expanded to all columns that match one of the data types provided.
The example below performs the exact same computation as before:
"""

nanuq """
In Nanuq you give the data type as a Nim type: `float` is Polars' `Float64`, `int` is
`Int64`, `string` is `String`.
"""

tabs """
result = df.with_columns((pl.col(pl.Float64) / eur_usd_rate).round(2))
result
""":
  nbCode:
    let byType = df.withColumns((col(float) / eurUsdRate).round(2))
    nbShow byType

nbText: """
When we use a data type with expression expansion we cannot know, beforehand, how many
columns a single expression will expand to. We need the schema of the input dataframe if
we want to determine what is the final list of expressions that is to be applied.

If we weren't sure about whether the price columns where of the type `Float64` or
`Float32`, we could specify both data types:
"""

nanuq """
Nim can also name the whole family at once with the typeclass `SomeFloat`.
"""

tabs """
result2 = df.with_columns(
    (
        pl.col(
            pl.Float32,
            pl.Float64,
        )
        / eur_usd_rate
    ).round(2)
)
print(result.equals(result2))
""":
  nbCode:
    let byTypes = df.withColumns((col(float32, float) / eurUsdRate).round(2))
    let byClass = df.withColumns((col(SomeFloat) / eurUsdRate).round(2))
    echo $byTypes == $byType, " ", $byClass == $byType

nbText: """
### Expansion by pattern matching

You can also use regular expressions to specify patterns that are used to match the column
names. To distinguish between a regular column name and expansion by pattern matching,
regular expressions start and end with `^` and `$`, respectively. This also means that the
pattern must match against the whole column name string.

Regular expressions can be mixed with regular column names:
"""

tabs """
df.select(pl.col("ticker", "^.*_high$", "^.*_low$"))
""":
  nbCode:
    let highsAndLows = df.select(col("ticker", "^.*_high$", "^.*_low$"))
    nbShow highsAndLows

nbText: """
### Arguments cannot be of mixed types

In Python, the function `col` accepts an arbitrary number of strings (as
[column names](#explicit-expansion-by-column-name) or as
[regular expressions](#expansion-by-pattern-matching)) or an arbitrary number of data types,
but you cannot mix both in the same function call:
"""

python """
try:
    df.select(pl.col("ticker", pl.Float64))
except TypeError as err:
    print("TypeError:", err)
"""

nanuq """
In Nanuq that call does not compile: `col` takes either names or types.
"""

nbText: """
## Selecting all columns

Polars provides the function `all` as shorthand notation to refer to all columns of a
dataframe:
"""

tabs """
result = df.select(pl.all())
print(result.equals(df))
""":
  nbCode:
    echo $df.select(all()) == $df

nbText: """
> **Note.** The function `all` is syntactic sugar for `col("*")`, but since the argument
> `"*"` is a special case and `all` reads more like English, the usage of `all` is
> preferred.

## Excluding columns

Polars also provides a mechanism to exclude certain columns from expression expansion. For
that, you use the function `exclude`, which accepts exactly the same types of arguments as
`col`:
"""

tabs """
df.select(pl.all().exclude("^day_.*$"))
""":
  nbCode:
    let noDay = df.select(all().exclude("^day_.*$"))
    nbShow noDay

nbText: "Naturally, the function `exclude` can also be used after the function `col`:"

tabs """
df.select(pl.col(pl.Float64).exclude("^day_.*$"))
""":
  nbCode:
    let floatsNoDay = df.select(col(float).exclude("^day_.*$"))
    nbShow floatsNoDay

nbText: """
## Column renaming

By default, when you apply an expression to a column, the result keeps the same name as
the original column.

Preserving the column name can be semantically wrong and in certain cases Polars may even
raise an error if duplicate names occur:
"""

tabs """
from polars.exceptions import DuplicateError

gbp_usd_rate = 1.31  # As of 14th October 2024

try:
    df.select(
        pl.col("price") / gbp_usd_rate,  # This would be named "price"...
        pl.col("price") / eur_usd_rate,  # And so would this.
    )
except DuplicateError as err:
    print("DuplicateError:", err)
""":
  nbCode:
    import std/strutils

    const gbpUsdRate = 1.31  # As of 14th October 2024

    try:
      discard df.select(
        col("price") / gbpUsdRate,  # This would be named "price"...
        col("price") / eurUsdRate,  # And so would this.
      )
    except NanuqError as err:
      echo "NanuqError: ", err.msg.splitLines[0]

nanuq """
Polars' errors arrive in Nanuq as `NanuqError`, with Polars' message.
"""

nbText: """
To prevent errors like this, and to allow users to rename their columns when appropriate,
Polars provides a series of functions that let you change the name of a column or a group
of columns.

### Renaming a single column with `alias`

The function `alias` has been used thoroughly in the documentation already and it lets you
rename a single column:
"""

tabs """
df.select(
    (pl.col("price") / gbp_usd_rate).alias("price (GBP)"),
    (pl.col("price") / eur_usd_rate).alias("price (EUR)"),
)
""":
  nbCode:
    let prices = df.select(
      (col("price") / gbpUsdRate).alias("price (GBP)"),
      (col("price") / eurUsdRate).alias("price (EUR)"))
    nbShow prices

nbText: """
### Prefixing and suffixing column names

When using expression expansion you cannot use the function `alias` because the function
`alias` is designed specifically to rename a single column.

When it suffices to add a static prefix or a static suffix to the existing names, we can use
the functions `prefix` and `suffix` from the namespace `name`:
"""

tabs """
df.select(
    (pl.col("^year_.*$") / eur_usd_rate).name.prefix("in_eur_"),
    (pl.col("day_high", "day_low") / gbp_usd_rate).name.suffix("_gbp"),
)
""":
  nbCode:
    let renamed = df.select(
      (col("^year_.*$") / eurUsdRate).name.prefix("in_eur_"),
      (col("day_high", "day_low") / gbpUsdRate).name.suffix("_gbp"))
    nbShow renamed

nbText: """
### Dynamic name replacement

If a static prefix/suffix is not enough, the namespace `name` also provides the function
`map` that accepts a callable that accepts the old column names and produces the new ones:
"""

nanuq """
Nanuq can't call Nim code from inside a Polars query yet, so this one has no Nim version.
"""

python """
# There is also `name.to_uppercase`, so this usage of `.map` is moot.
df.select(pl.all().name.map(str.upper))
"""

nbText: """
See the API reference for the full contents of the namespace `name`.

## Programmatically generating expressions

Expression expansion is a very useful feature but it does not solve all of your problems.
For example, if we want to compute the day and year amplitude of the prices of the stocks
in our dataframe, expression expansion won't help us.

At first, you may think about using a `for` loop:
"""

tabs """
for tp in ["day", "year"]:
    df = df.with_columns(
        (pl.col(f"{tp}_high") - pl.col(f"{tp}_low")).alias(f"{tp}_amplitude")
    )
df
""":
  nbCode:
    var amplitudes = df
    for tp in ["day", "year"]:
      amplitudes = amplitudes.withColumns(
        (col(tp & "_high") - col(tp & "_low")).alias(tp & "_amplitude"))
    nbShow amplitudes

nbText: """
Do not do this. Instead, generate all of the expressions you want to compute
programmatically and use them only once in a context. Loosely speaking, you want to swap the
`for` loop with the context `with_columns`. In practice, you could do something like the
following:
"""

nanuq """
In Python that is a generator; in Nim, a proc that returns the expressions does the same.
"""

tabs """
def amplitude_expressions(time_periods):
    for tp in time_periods:
        yield (pl.col(f"{tp}_high") - pl.col(f"{tp}_low")).alias(f"{tp}_amplitude")


df.with_columns(amplitude_expressions(["day", "year"]))
""":
  nbCode:
    proc amplitudeExpressions(timePeriods: openArray[string]): seq[Expr] =
      for tp in timePeriods:
        result.add (col(tp & "_high") - col(tp & "_low")).alias(tp & "_amplitude")

    let withAmplitudes = df.withColumns(amplitudeExpressions(["day", "year"]))
    nbShow withAmplitudes

nbText: """
This produces the same final result and by specifying all of the expressions in one go we
give Polars the opportunity to:

1. do a better job at optimising the query; and
2. parallelise the execution of the actual computations.

## More flexible column selections

Polars comes with the submodule `selectors` that provides a number of functions that allow
you to write more flexible column selections for expression expansion.

As a first example, here is how we can use the functions `string` and `ends_with`, and the
set operations that the functions from `selectors` support, to select all string columns and
the columns whose names end with `"_high"`:
"""

python """
import polars.selectors as cs

df.select(cs.string() | cs.ends_with("_high"))
"""

nanuq """
Nanuq does not have selectors as a separate module yet, so this runs in Python only. Its
`col` covers selection by name, regular expression, Nim type and type family, plus
`exclude`. The rest of the original's section on selectors (set operations, `as_expr`,
debugging selectors and the complete reference) is left out.
"""

bookSave()
