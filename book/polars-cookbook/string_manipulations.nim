import nanuqbook
bookInit()

nbText: "# String manipulations"

attribution polarsCookbook(6, "Performing String Manipulations",
  "Two recipes of the chapter: cleaning strings and concatenating strings. Left out: " &
  "`str.to_titlecase` (not in Nanuq yet), and the recipes on the Google Play Store reviews " &
  "dataset, which the Nanuq book does not ship (filtering, extracting substrings, " &
  "splitting into lists and structs).")

nbText: """
String columns have their own namespace of functions, `str`. These recipes clean up
messy text and glue strings together.

## Cleaning strings

Three sentences with stray spaces and random capitals:
"""

tabs """
import polars as pl

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
    import nanuq

    var df = newDataFrame:
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

nanuq """
The recipe then title-cases the text with `str.to_titlecase()`. Nanuq does not have
`toTitlecase` yet (Rust Polars has it behind its `nightly` feature), so that step is left
out.
"""

nbText: "Lower and upper case:"

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
