import nanuqbook
bookInit()

nbText: "# String manipulations"

attribution polarsCookbook(6, "Performing String Manipulations",
  "Three recipes of the chapter: converting strings into dates and times, cleaning " &
  "strings and concatenating strings. The conversion recipe runs on four made-up " &
  "timestamps instead of the Google Play Store reviews dataset, which the Nanuq book does " &
  "not ship. Left out: the other recipes on " &
  "that dataset (filtering, extracting substrings, splitting into lists and structs).")

nbText: """
String columns have their own namespace of functions, `str`. These recipes clean up
messy text, parse dates and glue strings together.

## Converting strings into date, time, and datetime

The recipe parses the timestamps of app reviews, `at`. Four of them stand in for the
book's dataset:
"""

tabs """
import polars as pl

df = pl.DataFrame(
    {
        'at': [
            '2024-03-14 09:26:53',
            '2024-03-15 18:02:11',
            '2024-04-01 00:00:00',
            '2024-04-02 23:59:59'
        ]
    }
)
df.head()
""":
  nbCode:
    import nanuq

    var df = newDataFrame:
      at: ["2024-03-14 09:26:53", "2024-03-15 18:02:11", "2024-04-01 00:00:00",
           "2024-04-02 23:59:59"]
    nbShow df.head()

nbText: """
With the format of the whole string, `toDate` keeps the date, `toTime` the time of day
and `toDatetime` both:
"""

tabs """
df.select(
    'at',
    pl.col('at').str.to_date(format='%Y-%m-%d %H:%M:%S').alias('at(date)')
).head()
""":
  nbCode:
    nbShow df.select(
      col.at,
      col.at.str.toDate(format = "%Y-%m-%d %H:%M:%S").alias("at(date)")).head()

tabs """
df.select(
    'at',
    pl.col('at').str.to_time(format='%Y-%m-%d %H:%M:%S').alias('at(time)')
).head()
""":
  nbCode:
    nbShow df.select(
      col.at,
      col.at.str.toTime(format = "%Y-%m-%d %H:%M:%S").alias("at(time)")).head()

tabs """
df.select(
    'at',
    pl.col('at').str.to_datetime(format='%Y-%m-%d %H:%M:%S').alias('at(datetime)')
).head()
""":
  nbCode:
    nbShow df.select(
      col.at,
      col.at.str.toDatetime(format = "%Y-%m-%d %H:%M:%S").alias("at(datetime)")).head()

nbText: "`strptime` does all three, with the type to parse into:"

tabs """
df.select(
    'at',
    pl.col('at').str.strptime(pl.Date, '%Y-%m-%d %H:%M:%S').alias('at(date)'),
    pl.col('at').str.strptime(pl.Time, '%Y-%m-%d %H:%M:%S').alias('at(time)'),
    pl.col('at').str.strptime(pl.Datetime, '%Y-%m-%d %H:%M:%S').alias('at(datetime)')
).head()
""":
  nbCode:
    nbShow df.select(
      col.at,
      col.at.str.strptime(Date, "%Y-%m-%d %H:%M:%S").alias("at(date)"),
      col.at.str.strptime(TimeOfDay, "%Y-%m-%d %H:%M:%S").alias("at(time)"),
      col.at.str.strptime(DateTime, "%Y-%m-%d %H:%M:%S").alias("at(datetime)")).head()

nanuq """
The types are Nim's: `Date` and `TimeOfDay` from Nanuq, `DateTime` from `std/times`.
"""

nbText: """
## Cleaning strings

Three sentences with stray spaces and random capitals:
"""

tabs """
df = pl.DataFrame(
    {
        'text': [
            '  I aM a HUmAn.  ',
            'it is NOT   easy!  ',
            ' WHY are You cool'
        ]
    }
)
df.head()
""":
  nbCode:
    df = newDataFrame:
      text: ["  I aM a HUmAn.  ", "it is NOT   easy!  ", " WHY are You cool"]
    nbShow df.head()

nbText: "`stripChars` with no argument trims the whitespace at both ends (not inside):"

tabs """
df.select(
    'text',
    pl.col('text')
    .str.strip_chars()
    .alias('stripped_text')
)
""":
  nbCode:
    nbShow df.select(
      col.text,
      col.text.str.stripChars.alias("stripped_text"))

nbText: """
`replace` replaces the first match, or the first `n`; `replaceAll` replaces them all.
With `literal = true` the pattern is plain text, not a regular expression.
"""

tabs """
df.select(
    'text',
    pl.col('text')
    .str.replace('a', 'new_a', literal=True, n=1)
    .alias('replaced_text')
)
""":
  nbCode:
    nbShow df.select(
      col.text,
      col.text.str.replace("a", "new_a", literal = true, n = 1).alias("replaced_text"))

tabs """
df.select(
    'text',
    pl.col('text')
    .str.replace_all('a', 'new_a', literal=True)
    .alias('replaced_all_text')
)
""":
  nbCode:
    nbShow df.select(
      col.text,
      col.text.str.replaceAll("a", "new_a", literal = true).alias("replaced_all_text"))

nbText: "Title, lower and upper case:"

tabs """
df.select(
    'text',
    pl.col('text')
    .str.to_titlecase().alias('title_case')
)
""":
  nbCode:
    nbShow df.select(
      col.text,
      col.text.str.toTitlecase.alias("title_case"))

nanuq """
`toTitlecase` needs Polars' `nightly` feature: the release libraries of Nanuq 0.3 have
it, while a library built from source with stable Rust raises an `InvalidOperationError`.
"""

tabs """
df.select(
    'text',
    pl.col('text')
    .str.to_lowercase().alias('lower_case')
)
""":
  nbCode:
    nbShow df.select(
      col.text,
      col.text.str.toLowercase.alias("lower_case"))

tabs """
df.select(
    'text',
    pl.col('text')
    .str.to_uppercase().alias('upper_case')
)
""":
  nbCode:
    nbShow df.select(
      col.text,
      col.text.str.toUppercase.alias("upper_case"))

nbText: """
Padding fills a string up to a length, at the start or at the end. Strings that are
already longer stay as they are.
"""

tabs """
df.select(
    'text',
    pl.col('text')
    .str.pad_start(20, '~').alias('pad_start'),
    pl.col('text')
    .str.pad_end(20, '~').alias('pad_end'),
)
""":
  nbCode:
    nbShow df.select(
      col.text,
      col.text.str.padStart(20, '~').alias("pad_start"),
      col.text.str.padEnd(20, '~').alias("pad_end"))

tabs """
df.select(
    'text',
    pl.col('text')
    .str.pad_start(20, '0').alias('pad_start')

)
""":
  nbCode:
    nbShow df.select(
      col.text,
      col.text.str.padStart(20, '0').alias("pad_start"))

nanuq """
The fill character is a Nim `char`, `'~'`, where Python passes a one-letter string.
"""

nbText: """
## Concatenating strings
"""

tabs """
df = pl.DataFrame(
    {
        'colA': ['a', 'b', 'c', 'd'],
        'colB': ['aa', 'bb', 'cc', 'dd']
    }
)
df
""":
  nbCode:
    df = newDataFrame:
      colA: ["a", "b", "c", "d"]
      colB: ["aa", "bb", "cc", "dd"]
    nbShow df

nbText: "`+` concatenates strings, with a literal or with another column:"

tabs """
df.select(
    pl.all(),
    (pl.col('colB') + ' new').alias('newColB')
)
""":
  nbCode:
    nbShow df.select(
      all(),
      (col.colB + " new").alias("newColB"))

tabs """
df.select(
    pl.all(),
    (pl.col('colA') + pl.col('colB')).alias('colC')

)
""":
  nbCode:
    nbShow df.select(
      all(),
      (col.colA + col.colB).alias("colC"))

nbText: """
`concatStr` joins several expressions with a separator, and casts what is not a string:
here the number 103.
"""

tabs """
df.select(
    pl.all(),
    pl.concat_str(
        pl.lit(100)+3,
        pl.lit(' '),
        pl.col('colA'),
        pl.col('colB'),
        separator='::'
    ).alias('newCol')
)
""":
  nbCode:
    nbShow df.select(
      all(),
      concatStr([lit(100) + 3, lit(" "), col.colA, col.colB], separator = "::")
        .alias("newCol"))

nanuq """
Python's `concat_str` takes the expressions as separate arguments; Nanuq's takes them in
an array, so that the separator can follow.
"""

nbText: """
`str.join` goes the other way: it is an aggregation that joins all the values of a column
into one string.
"""

tabs """
df.select(
    pl.all(),
    pl.col('colA').str.join(delimiter=', ').alias('concatenatedColA')
)
""":
  nbCode:
    nbShow df.select(
      all(),
      col.colA.str.join(delimiter = ", ").alias("concatenatedColA"))

bookSave()
