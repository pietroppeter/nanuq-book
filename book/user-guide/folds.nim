import nanuqbook
bookInit()

nbText: "# Folds"

attribution userGuide("Folds", "expressions/folds",
  "The fold function is a Nim proc on two Series, where Python passes `operator.add`, " &
  "`operator.mul` or a lambda.")

nbText: """
Polars provides many expressions to perform computations across columns, like
`sum_horizontal`, `mean_horizontal`, and `min_horizontal`. However, these are just special
cases of a general algorithm called a fold, and Polars provides a general mechanism for you
to compute custom folds for when the specialised versions of Polars are not enough.

Folds computed with the function `fold` operate on the full columns for maximum speed.
They utilize the data layout very efficiently and often have vectorized execution.

## Basic example

As a first example, we will reimplement `sum_horizontal` with the function `fold`:
"""

tabs """
import operator
import polars as pl

df = pl.DataFrame(
    {
        "label": ["foo", "bar", "spam"],
        "a": [1, 2, 3],
        "b": [10, 20, 30],
    }
)

result = df.select(
    pl.fold(
        acc=pl.lit(0),
        function=operator.add,
        exprs=pl.col("a", "b"),
    ).alias("sum_fold"),
    pl.sum_horizontal(pl.col("a", "b")).alias("sum_horz"),
)
result
""":
  nbCode:
    import nanuq

    let df = newDataFrame:
      label: ["foo", "bar", "spam"]
      a: [1, 2, 3]
      b: [10, 20, 30]

    let add = proc (acc, x: Series): Series = acc + x

    nbShow df.select(
      fold(
        acc = lit(0),
        f = add,
        exprs = col("a", "b"),
      ).alias("sum_fold"),
      sumHorizontal(col("a", "b")).alias("sum_horz"))

nanuq """
The function gets the accumulated values and the next column as two Series, and returns a
Series: Nim's `+` on Series stands in for Python's `operator.add`.
"""

nbText: """
The function `fold` expects a function `f` as the parameter `function` and `f` should
accept two arguments. The first argument is the accumulated result, which we initialise as
zero, and the second argument takes the successive values of the expressions listed in the
parameter `exprs`. In our case, they're the two columns “a” and “b”.

The snippet below includes a third explicit expression that represents what the function
`fold` is doing above:
"""

tabs """
acc = pl.lit(0)
f = operator.add

result = df.select(
    f(f(acc, pl.col("a")), pl.col("b")),
    pl.fold(acc=acc, function=f, exprs=pl.col("a", "b")).alias("sum_fold"),
)
result
""":
  nbCode:
    let acc = lit(0)

    nbShow df.select(
      acc + col("a") + col("b"),
      fold(acc = acc, f = add, exprs = col("a", "b")).alias("sum_fold"))

nanuq """
Python's `operator.add` works on expressions and on Series alike; in Nim the explicit
version is written with `+` on expressions, and the fold with `add` on Series.
"""

nbText: """
> **`fold` in Python.** Most programming languages include a higher-order function that
> implements the algorithm that the function `fold` in Polars implements. The Polars `fold`
> is very similar to Python's `functools.reduce`. You can
> [learn more about the power of `functools.reduce` in this article](http://mathspp.com/blog/pydonts/the-power-of-reduce).
"""

nanuq """
In Nim it is `foldl` from `std/sequtils`.
"""

nbText: """
## The initial value `acc`

The initial value chosen for the accumulator `acc` is typically, but not always, the
[identity element](https://en.wikipedia.org/wiki/Identity_element) of the operation you
want to apply. For example, if we wanted to multiply across the columns, we would not get
the correct result if our accumulator was set to zero:
"""

tabs """
result = df.select(
    pl.fold(
        acc=pl.lit(0),
        function=operator.mul,
        exprs=pl.col("a", "b"),
    ).alias("prod"),
)
result
""":
  nbCode:
    let mul = proc (acc, x: Series): Series = acc * x

    nbShow df.select(
      fold(
        acc = lit(0),
        f = mul,
        exprs = col("a", "b"),
      ).alias("prod"))

nbText: """
To fix this, the accumulator `acc` should be set to `1`:
"""

tabs """
result = df.select(
    pl.fold(
        acc=pl.lit(1),
        function=operator.mul,
        exprs=pl.col("a", "b"),
    ).alias("prod"),
)
result
""":
  nbCode:
    nbShow df.select(
      fold(
        acc = lit(1),
        f = mul,
        exprs = col("a", "b"),
      ).alias("prod"))

nbText: """
## Conditional

In the case where you'd want to apply a condition/predicate across all columns in a
dataframe, a fold can be a very concise way to express this.
"""

tabs """
df = pl.DataFrame(
    {
        "a": [1, 2, 3],
        "b": [0, 1, 2],
    }
)

result = df.filter(
    pl.fold(
        acc=pl.lit(True),
        function=lambda acc, x: acc & x,
        exprs=pl.all() > 1,
    )
)
result
""":
  nbCode:
    let df2 = newDataFrame:
      a: [1, 2, 3]
      b: [0, 1, 2]

    nbShow df2.filter(
      fold(
        acc = lit(true),
        f = proc (acc, x: Series): Series = acc and x,
        exprs = all() > 1))

nbText: """
The snippet above filters all rows where all columns are greater than 1.

## Folds and string data

Folds could be used to concatenate string data. However, due to the materialization of
intermediate columns, this operation will have squared complexity.

Therefore, we recommend using the function `concat_str` for this:
"""

tabs """
df = pl.DataFrame(
    {
        "a": ["a", "b", "c"],
        "b": [1, 2, 3],
    }
)

result = df.select(pl.concat_str(["a", "b"]))
result
""":
  nbCode:
    let df3 = newDataFrame:
      a: ["a", "b", "c"]
      b: [1, 2, 3]

    nbShow df3.select(concatStr([col("a"), col("b")]))

bookSave()
