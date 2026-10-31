import nanuqbook
bookInit()

nbText: "# Basic operations"

attribution userGuide("Basic operations", "expressions/basic-operations",
  "Left out: the bitwise operators, `approx_n_unique`, `value_counts` and `unique_counts` " &
  "(not in Nanuq yet), and the named-function forms of the operators (a Python " &
  "workaround). `n_unique` counts the `names` column instead of 100,000 random integers. " &
  "The random column is numpy's, seeded as in the original; the Nim side " &
  "writes the same five numbers out.")

nbText: """
This section shows how to do basic operations on dataframe columns, like do basic arithmetic
calculations, perform comparisons, and other general-purpose operations. We will use the
following dataframe for the examples that follow:
"""

tabs """
import polars as pl
import numpy as np

np.random.seed(42)  # For reproducibility.

df = pl.DataFrame(
    {
        "nrs": [1, 2, 3, None, 5],
        "names": ["foo", "ham", "spam", "egg", "spam"],
        "random": np.random.rand(5),
        "groups": ["A", "A", "B", "A", "B"],
    }
)
df
""":
  nbCode:
    import nanuq

    let df = newDataFrame(
      series("nrs", [some(1), some(2), some(3), none(int), some(5)]),
      series("names", ["foo", "ham", "spam", "egg", "spam"]),
      # the numbers numpy draws with seed 42
      series("random", [0.3745401188473625, 0.9507143064099162, 0.7319939418114051,
                        0.5986584841970366, 0.15601864044243652]),
      series("groups", ["A", "A", "B", "A", "B"]))
    nbShow df

nbText: """
## Basic arithmetic

Polars supports basic arithmetic between series of the same length, or between series and
literals. When literals are mixed with series, the literals are broadcast to match the
length of the series they are being used with.

In Nim, the power operator is `^` and the remainder is `mod` (with Polars' meaning: the
result takes the sign of the divisor, as `%` does in Python).
"""

tabs """
df.select(
    (pl.col("nrs") + 5).alias("nrs + 5"),
    (pl.col("nrs") - 5).alias("nrs - 5"),
    (pl.col("nrs") * pl.col("random")).alias("nrs * random"),
    (pl.col("nrs") / pl.col("random")).alias("nrs / random"),
    (pl.col("nrs") ** 2).alias("nrs ** 2"),
    (pl.col("nrs") % 3).alias("nrs % 3"),
)
""":
  nbCode:
    let arithmetic = df.select(
      (col("nrs") + 5).alias("nrs + 5"),
      (col("nrs") - 5).alias("nrs - 5"),
      (col("nrs") * col("random")).alias("nrs * random"),
      (col("nrs") / col("random")).alias("nrs / random"),
      (col("nrs") ^ 2).alias("nrs ** 2"),
      (col("nrs") mod 3).alias("nrs % 3"))
    nbShow arithmetic

nbText: """
The example above shows that when an arithmetic operation takes `null` as one of its
operands, the result is `null`.

## Comparisons

Like with arithmetic operations, Polars supports comparisons via the overloaded operators:
"""

tabs """
df.select(
    (pl.col("nrs") > 1).alias("nrs > 1"),  # .gt
    (pl.col("nrs") >= 3).alias("nrs >= 3"),  # .ge
    (pl.col("random") < 0.2).alias("random < .2"),  # .lt
    (pl.col("random") <= 0.5).alias("random <= .5"),  # .le
    (pl.col("nrs") != 1).alias("nrs != 1"),  # .ne
    (pl.col("nrs") == 1).alias("nrs == 1"),  # .eq
)
""":
  nbCode:
    let comparisons = df.select(
      (col("nrs") > 1).alias("nrs > 1"),
      (col("nrs") >= 3).alias("nrs >= 3"),
      (col("random") < 0.2).alias("random < .2"),
      (col("random") <= 0.5).alias("random <= .5"),
      (col("nrs") != 1).alias("nrs != 1"),
      (col("nrs") == 1).alias("nrs == 1"))
    nbShow comparisons

nbText: """
## Boolean operations

Python uses the operators `&`, `|` and `~` for the Boolean operations “and”, “or” and
“not”, because its keywords `and`, `or` and `not` can't be overloaded. Nim can overload
them, so Nanuq uses the keywords:
"""

tabs """
df.select(
    ((~pl.col("nrs").is_null()) & (pl.col("groups") == "A")).alias(
        "number not null and group A"
    ),
    ((pl.col("random") < 0.5) | (pl.col("groups") == "B")).alias(
        "random < 0.5 or group B"
    ),
)
""":
  nbCode:
    let booleans = df.select(
      ((not col("nrs").isNull) and (col("groups") == "A")).alias(
        "number not null and group A"),
      ((col("random") < 0.5) or (col("groups") == "B")).alias(
        "random < 0.5 or group B"))
    nbShow booleans

nbText: """
## Counting unique values

The function `n_unique` (`nUnique` in Nanuq) counts the exact number of unique values in a
series:
"""

tabs """
df.select(
    pl.col("names").n_unique().alias("n_unique"),
)
""":
  nbCode:
    let uniqueNames = df.select(col("names").nUnique.alias("n_unique"))
    nbShow uniqueNames

nbText: """
The original page counts the unique values of 100,000 random integers here, and compares
`n_unique` with the faster estimate `approx_n_unique`, which Nanuq does not have yet.

## Conditionals

Polars supports something akin to a ternary operator through the function `when`, which is
followed by one function `then` and an optional function `otherwise`.

The function `when` accepts a predicate expression. The values that evaluate to `True` are
replaced by the corresponding values of the expression inside the function `then`. The
values that evaluate to `False` are replaced by the corresponding values of the expression
inside the function `otherwise` or `null`, if `otherwise` is not provided.

`when` is a Nim keyword, so as the first call of an expression it needs backticks. Integer
division, Python's `//`, is `div`.

The example below applies one step of the
[Collatz conjecture](https://en.wikipedia.org/wiki/Collatz_conjecture) to the numbers in
the column “nrs”:
"""

tabs """
df.select(
    pl.col("nrs"),
    pl.when(pl.col("nrs") % 2 == 1)  # Is the number odd?
    .then(3 * pl.col("nrs") + 1)  # If so, multiply by 3 and add 1.
    .otherwise(pl.col("nrs") // 2)  # If not, divide by 2.
    .alias("Collatz"),
)
""":
  nbCode:
    let collatz = df.select(
      col("nrs"),
      `when`(col("nrs") mod 2 == 1)  # Is the number odd?
        .then(3 * col("nrs") + 1)     # If so, multiply by 3 and add 1.
        .otherwise(col("nrs") div 2)  # If not, divide by 2.
        .alias("Collatz"))
    nbShow collatz

nbText: """
You can also emulate a chain of an arbitrary number of conditionals, akin to Python's
`elif` statement, by chaining an arbitrary number of consecutive blocks of
`.when(...).then(...)`. In those cases, and for each given value, Polars will only consider
a replacement expression that is deeper within the chain if the previous predicates all
failed for that value. Nanuq also has the `choose` macro, which writes the same chain as an
`if`/`elif`/`else`.
"""

bookSave()
