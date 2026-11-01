import nanuqbook
bookInit()

nbText: "# Strings"

attribution userGuide("Strings", "expressions/strings",
  "Left out: `extract_all` (it returns a list column, and Nanuq has no lists yet).")

nbText: """
The following section discusses operations performed on string data, which is a frequently
used data type when working with dataframes. String processing functions are available in
the namespace `str`.

Working with strings in other dataframe libraries can be highly inefficient due to the fact
that strings have unpredictable lengths. Polars mitigates these inefficiencies by
[following the Arrow Columnar Format specification](https://docs.pola.rs/user-guide/concepts/data-types-and-structures/#data-types-internals),
so you can write performant data queries on string data too.

## The string namespace

When working with string data you will likely need to access the namespace `str`, which
aggregates 40+ functions that let you work with strings. As an example of how to access
functions from within that namespace, the snippet below shows how to compute the length of
the strings in a column in terms of the number of bytes and the number of characters:
"""

nanuq """
Nanuq 0.3 has the `str` namespace, with Polars' names in camelCase (`len_bytes` is
`lenBytes`). It has about 25 of the 40+ functions so far: the ones that return lists or
structs (`split`, `extract_all`, `extract_groups`) wait for nested types.
"""

tabs """
import polars as pl

df = pl.DataFrame(
    {
        "language": ["English", "Dutch", "Portuguese", "Finish"],
        "fruit": ["pear", "peer", "pêra", "päärynä"],
    }
)

df.with_columns(
    pl.col("fruit").str.len_bytes().alias("byte_count"),
    pl.col("fruit").str.len_chars().alias("letter_count"),
)
""":
  nbCode:
    import nanuq

    var df = newDataFrame:
      language: ["English", "Dutch", "Portuguese", "Finish"]
      fruit: ["pear", "peer", "pêra", "päärynä"]

    nbShow df.withColumns(
      col.fruit.str.lenBytes.alias("byte_count"),
      col.fruit.str.lenChars.alias("letter_count"))

nbText: """
> **Note.** If you are working exclusively with ASCII text, then the results of the two
> computations will be the same and using `len_bytes` is recommended since it is faster.

## Parsing strings

Polars offers multiple methods for checking and parsing elements of a string column, namely
checking for the existence of given substrings or patterns, and counting, extracting, or
replacing, them. We will demonstrate some of these operations in the upcoming examples.

### Check for the existence of a pattern

We can use the function `contains` to check for the presence of a pattern within a string.
By default, the argument to the function `contains` is interpreted as a regular expression.
If you want to specify a literal substring, set the parameter `literal` to `True`.

For the special cases where you want to check if the strings start or end with a fixed
substring, you can use the functions `starts_with` or `ends_with`, respectively.
"""

tabs """
df.select(
    pl.col("fruit"),
    pl.col("fruit").str.starts_with("p").alias("starts_with_p"),
    pl.col("fruit").str.contains("p..r").alias("p..r"),
    pl.col("fruit").str.contains("e+").alias("e+"),
    pl.col("fruit").str.ends_with("r").alias("ends_with_r"),
)
""":
  nbCode:
    nbShow df.select(
      col.fruit,
      col.fruit.str.startsWith("p").alias("starts_with_p"),
      col.fruit.str.contains("p..r").alias("p..r"),
      col.fruit.str.contains("e+").alias("e+"),
      col.fruit.str.endsWith("r").alias("ends_with_r"))

nanuq """
`literal = true` is a named argument in Nim too: `col.fruit.str.contains("e+", literal =
true)` looks for the two characters `e+`.
"""

nbText: """
### Regex specification

Polars relies on the Rust crate `regex` to work with regular expressions, so you may need
to [refer to the syntax documentation](https://docs.rs/regex/latest/regex/#syntax) to see
what features and flags are supported. In particular, note that the flavor of regex
supported by Polars is different from Python's module `re`.

### Extract a pattern

The function `extract` allows us to extract patterns from the string values in a column.
The function `extract` accepts a regex pattern with one or more capture groups and extracts
the capture group specified as the second argument.
"""

tabs """
df = pl.DataFrame(
    {
        "urls": [
            "http://vote.com/ballon_dor?candidate=messi&ref=polars",
            "http://vote.com/ballon_dor?candidat=jorginho&ref=polars",
            "http://vote.com/ballon_dor?candidate=ronaldo&ref=polars",
        ]
    }
)
df.select(
    pl.col("urls").str.extract(r"candidate=(\w+)", group_index=1),
)
""":
  nbCode:
    df = newDataFrame:
      urls: ["http://vote.com/ballon_dor?candidate=messi&ref=polars",
             "http://vote.com/ballon_dor?candidat=jorginho&ref=polars",
             "http://vote.com/ballon_dor?candidate=ronaldo&ref=polars"]
    nbShow df.select(col.urls.str.extract(r"candidate=(\w+)", groupIndex = 1))

nbText: """
To extract all occurrences of a pattern within a string, we can use the function
`extract_all`. In the example below, we extract all numbers from a string using the regex
pattern `(\d+)`, which matches one or more digits. The resulting output of the function
`extract_all` is a list containing all instances of the matched pattern within the string.
"""

python """
df = pl.DataFrame({"text": ["123 bla 45 asd", "xyz 678 910t"]})
df.select(
    pl.col("text").str.extract_all(r"(\d+)").alias("extracted_nrs"),
)
"""

nanuq """
Nanuq has no `extractAll` yet: it returns a list column, and Nanuq has no lists. The
Python code runs on its own above.
"""

nbText: """
### Replace a pattern

Akin to the functions `extract` and `extract_all`, Polars provides the functions `replace`
and `replace_all`. These accept a regex pattern or a literal substring (if the parameter
`literal` is set to `True`) and perform the replacements specified. The function `replace`
will make at most one replacement whereas the function `replace_all` will make all the
non-overlapping replacements it finds.
"""

tabs """
df = pl.DataFrame({"text": ["123abc", "abc456"]})
df.with_columns(
    pl.col("text").str.replace(r"\d", "-"),
    pl.col("text").str.replace_all(r"\d", "-").alias("text_replace_all"),
)
""":
  nbCode:
    df = newDataFrame:
      text: ["123abc", "abc456"]
    nbShow df.withColumns(
      col.text.str.replace(r"\d", "-"),
      col.text.str.replaceAll(r"\d", "-").alias("text_replace_all"))

nbText: """
## Modifying strings

### Concatenating strings

String expressions can be concatenated horizontally using the `+` operator, which is
equivalent to `Expr.add`.
"""

tabs """
df = pl.DataFrame(
    {
        "first_name": ["Ada", "Grace", "Edsger"],
        "last_name": ["Lovelace", "Hopper", "Dijkstra"],
    }
)

df.with_columns(
    full_name=pl.col("first_name") + pl.lit(" ") + pl.col("last_name"),
)
""":
  nbCode:
    df = newDataFrame:
      first_name: ["Ada", "Grace", "Edsger"]
      last_name: ["Lovelace", "Hopper", "Dijkstra"]
    nbShow df.withColumns(
      (col.first_name + lit(" ") + col.last_name).alias("full_name"))

nanuq """
The same in two other ways that Nanuq 0.3 has, like Python Polars: `concatStr([col.first_name,
col.last_name], separator = " ")`, and `format("{} {}", col.first_name, col.last_name)`.
"""

nbText: """
### Case conversion

Converting the casing of a string is a common operation and Polars supports it out of the
box with the functions `to_lowercase`, `to_titlecase`, and `to_uppercase`:
"""

tabs """
addresses = pl.DataFrame(
    {
        "addresses": [
            "128 PERF st",
            "Rust blVD, 158",
            "PoLaRs Av, 12",
            "1042 Query sq",
        ]
    }
)

addresses = addresses.select(
    pl.col("addresses").alias("originals"),
    pl.col("addresses").str.to_titlecase(),
    pl.col("addresses").str.to_lowercase().alias("lower"),
    pl.col("addresses").str.to_uppercase().alias("upper"),
)
addresses
""":
  nbCode:
    var addresses = newDataFrame:
      addresses: ["128 PERF st", "Rust blVD, 158", "PoLaRs Av, 12", "1042 Query sq"]

    addresses = addresses.select(
      col.addresses.alias("originals"),
      col.addresses.str.toTitlecase,
      col.addresses.str.toLowercase.alias("lower"),
      col.addresses.str.toUppercase.alias("upper"))
    nbShow addresses

nanuq """
`toTitlecase` needs Polars' `nightly` feature: the release libraries of Nanuq 0.3 have
it, while a library built from source with stable Rust raises an `InvalidOperationError`.
"""

nbText: """
### Stripping characters from the ends

Polars provides five functions in the namespace `str` that let you strip characters from
the ends of the string:

| Function            | Behaviour                                                             |
| ------------------- | --------------------------------------------------------------------- |
| `strip_chars`       | Removes leading and trailing occurrences of the characters specified. |
| `strip_chars_end`   | Removes trailing occurrences of the characters specified.             |
| `strip_chars_start` | Removes leading occurrences of the characters specified.              |
| `strip_prefix`      | Removes an exact substring prefix if present.                         |
| `strip_suffix`      | Removes an exact substring suffix if present.                         |

> **Similarity to Python string methods.** `strip_chars` is similar to Python's string
> method `strip` and `strip_prefix`/`strip_suffix` are similar to Python's string methods
> `removeprefix` and `removesuffix`, respectively.

It is important to understand that the first three functions interpret their string
argument as a set of characters whereas the functions `strip_prefix` and `strip_suffix` do
interpret their string argument as a literal string.
"""

tabs """
addr = pl.col("addresses")
chars = ", 0123456789"
addresses.select(
    addr.str.strip_chars(chars).alias("strip"),
    addr.str.strip_chars_end(chars).alias("end"),
    addr.str.strip_chars_start(chars).alias("start"),
    addr.str.strip_prefix("128 ").alias("prefix"),
    addr.str.strip_suffix(", 158").alias("suffix"),
)
""":
  nbCode:
    let address = col.addresses
    const chars = ", 0123456789"
    nbShow addresses.select(
      address.str.stripChars(chars).alias("strip"),
      address.str.stripCharsEnd(chars).alias("end"),
      address.str.stripCharsStart(chars).alias("start"),
      address.str.stripPrefix("128 ").alias("prefix"),
      address.str.stripSuffix(", 158").alias("suffix"))

nbText: """
If no argument is provided, the three functions `strip_chars`, `strip_chars_end`, and
`strip_chars_start`, remove whitespace by default.

### Slicing

Besides [extracting substrings as specified by patterns](#extract-a-pattern), you can also
slice strings at specified offsets to produce substrings. The general-purpose function for
slicing is `slice` and it takes the starting offset and the optional _length_ of the slice.
If the length of the slice is not specified or if it's past the end of the string, Polars
slices the string all the way to the end.

The functions `head` and `tail` are specialised versions used for slicing the beginning and
end of a string, respectively.
"""

tabs """
df = pl.DataFrame(
    {
        "fruits": ["pear", "mango", "dragonfruit", "passionfruit"],
        "n": [1, -1, 4, -4],
    }
)

df.with_columns(
    pl.col("fruits").str.slice(pl.col("n")).alias("slice"),
    pl.col("fruits").str.head(pl.col("n")).alias("head"),
    pl.col("fruits").str.tail(pl.col("n")).alias("tail"),
)
""":
  nbCode:
    df = newDataFrame:
      fruits: ["pear", "mango", "dragonfruit", "passionfruit"]
      n: [1, -1, 4, -4]
    nbShow df.withColumns(
      col.fruits.str.slice(col.n).alias("slice"),
      col.fruits.str.head(col.n).alias("head"),
      col.fruits.str.tail(col.n).alias("tail"))

nbText: """
## API documentation

In addition to the examples covered above, Polars offers various other string manipulation
functions. To explore these additional methods, you can go to the API documentation of your
chosen programming language for Polars.
"""

nanuq """
For Nanuq, the string functions are listed in the
[README](https://github.com/pietroppeter/nanuq#readme) and in the `strings` spec of its
OpenSpec specs.
"""

bookSave()
