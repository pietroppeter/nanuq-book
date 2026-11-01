import nanuqbook
bookInit()

nbText: "# Basic operations"

attribution userGuide("Basic operations", "expressions/basic-operations",
  "Left out: the bitwise operators and the named-function forms of the operators (a " &
  "Python workaround). The 100,000 random integers are drawn with Polars' seeded " &
  "`sample` instead of numpy, so both sides get the same ones; `value_counts` on an " &
  "expression returns structs, which Nanuq does not have yet, so it runs in Python " &
  "only and the Nim side shows the frame version. The random column is numpy's, seeded " &
  "as in the original; the Nim side writes the same five numbers out.")

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
"""

nanuq """
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

Polars uses operator overloading to allow you to use your language's native arithmetic
operators within your expressions. If you prefer, in Python you can use the corresponding
named functions.
"""

nanuq """
The original shows the named functions (`add`, `sub`, `mul`, …) here. Nanuq has only the
operators.
"""

nbText: """
## Comparisons

Like with arithmetic operations, Polars supports comparisons via the overloaded operators or
named functions:
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
## Boolean and bitwise operations

Depending on the language, you may use the operators `&`, `|`, and `~`, for the Boolean
operations “and”, “or”, and “not”, respectively, or the functions of the same name:
"""

nanuq """
Python overloads `&`, `|` and `~` because its keywords `and`, `or` and `not` can't be
overloaded. Nim's can, so Nanuq uses the keywords `and`, `or` and `not`. The bitwise
operations that follow in the original are not in Nanuq yet.
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
## Counting (unique) values

Polars has two functions to count the number of unique values in a series. The function
`n_unique` can be used to count the exact number of unique values in a series. However, for
very large data sets, this operation can be quite slow. In those cases, if an approximation
is good enough, you can use the function `approx_n_unique` that uses the algorithm
[HyperLogLog++](https://en.wikipedia.org/wiki/HyperLogLog) to estimate the result.
"""

nbText: """
The example below shows an example series where the `approx_n_unique` estimation is wrong
by 0.9%:
"""

nanuq """
The original draws its 100,000 integers with numpy. Here both sides draw them with
Polars' `sample` (with replacement, from the numbers below 100,000) and the same seed, so
they count the same numbers. On these, the estimate is off by 0.6%.
"""

tabs """
long_df = pl.DataFrame({"numbers": range(100_000)}).sample(
    100_000, with_replacement=True, seed=42
)

long_df.select(
    pl.col("numbers").n_unique().alias("n_unique"),
    pl.col("numbers").approx_n_unique().alias("approx_n_unique"),
)
""":
  nbCode:
    import std/sequtils
    let longDf = newDataFrame(series("numbers", toSeq(0 ..< 100_000))).sample(
      100_000, withReplacement = true, seed = 42)

    let counts = longDf.select(
      col("numbers").nUnique.alias("n_unique"),
      col("numbers").approxNUnique.alias("approx_n_unique"))
    nbShow counts

nbText: """
You can get more information about the unique values and their counts with the function
`value_counts`, that Polars also provides:
"""

nanuq """
`value_counts` on an expression returns a column of structs, and Nanuq has no structs
yet, so this cell runs in Python only. Nanuq has `valueCounts` on a dataframe or a Series
instead, which returns the values and their counts as a dataframe, like Python's
`Series.value_counts` (shown after it).
"""

python """
df.select(
    pl.col("names").value_counts().alias("value_counts"),
)
"""

tabs """
df["names"].value_counts(sort=True)
""":
  nbCode:
    let nameCounts = df["names"].valueCounts(sort = true)
    nbShow nameCounts

nbText: """
The function `value_counts` returns the results in
[structs, a data type that we will explore in a later section](https://docs.pola.rs/user-guide/expressions/structs/).

Alternatively, if you only need a series with the unique values or a series with the
unique counts, they are one function away:
"""

tabs """
df.select(
    pl.col("names").unique(maintain_order=True).alias("unique"),
    pl.col("names").unique_counts().alias("unique_counts"),
)
""":
  nbCode:
    let uniqueCounts = df.select(
      col("names").unique(maintainOrder = true).alias("unique"),
      col("names").uniqueCounts.alias("unique_counts"))
    nbShow uniqueCounts

nbText: """
Note that we need to specify `maintain_order=True` in the function `unique` so that the
order of the results is consistent with the order of the results in `unique_counts`. See
the API reference for more information.
"""

nbText: """
## Conditionals

Polars supports something akin to a ternary operator through the function `when`, which is
followed by one function `then` and an optional function `otherwise`.

The function `when` accepts a predicate expression. The values that evaluate to `True` are
replaced by the corresponding values of the expression inside the function `then`. The
values that evaluate to `False` are replaced by the corresponding values of the expression
inside the function `otherwise` or `null`, if `otherwise` is not provided.

The example below applies one step of the
[Collatz conjecture](https://en.wikipedia.org/wiki/Collatz_conjecture) to the numbers in
the column “nrs”:
"""

nanuq """
In Nanuq the idiomatic way to write this is the `choose` macro: it takes a Nim
`if`/`elif`/`else` and builds the same `when`/`then`/`otherwise` chain. Two variants work
too. `choose` with a one-line `if`, inline as in Python:

```nim
choose(if col("nrs") mod 2 == 1: 3 * col("nrs") + 1
       else: col("nrs") div 2).alias("Collatz")
```

and the chain itself, where `when`, a Nim keyword, needs backticks as the first call:

```nim
`when`(col("nrs") mod 2 == 1).then(3 * col("nrs") + 1).otherwise(col("nrs") div 2)
```

Integer division, Python's `//`, is `div`.
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
    let step = choose:
      if col("nrs") mod 2 == 1:  # Is the number odd?
        3 * col("nrs") + 1       # If so, multiply by 3 and add 1.
      else:
        col("nrs") div 2         # If not, divide by 2.
    let collatz = df.select(col("nrs"), step.alias("Collatz"))
    nbShow collatz

nbText: """
You can also emulate a chain of an arbitrary number of conditionals, akin to Python's
`elif` statement, by chaining an arbitrary number of consecutive blocks of
`.when(...).then(...)`. In those cases, and for each given value, Polars will only consider
a replacement expression that is deeper within the chain if the previous predicates all
failed for that value.
"""

nanuq """
With `choose`, that is simply an `if` with more `elif` branches.
"""

bookSave()
