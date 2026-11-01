import nanuqbook
bookInit()

nbText: "# Expressions and contexts"

attribution userGuide("Expressions and contexts", "concepts/expressions-and-contexts",
  "Nanuq has no dates yet, so the people in the example dataframe have a birth year " &
  "instead of a birthdate, on both sides, and the code that used the date follows. Python's results are shown instead of printed.")

nbText: """
Polars has developed its own Domain Specific Language (DSL) for transforming data. The
language is very easy to use and allows for complex queries that remain human readable.
Expressions and contexts, which will be introduced here, are very important in achieving
this readability while also allowing the Polars query engine to optimize your queries to
make them run as fast as possible.

## Expressions

In Polars, an *expression* is a lazy representation of a data transformation. Expressions
are modular and flexible, which means you can use them as building blocks to build more
complex expressions. Here is an example of a Polars expression:
"""

tabs """
import polars as pl

pl.col("weight") / (pl.col("height") ** 2)
""":
  nbCode:
    import nanuq

    discard col("weight") / (col("height") ^ 2)

nanuq """
A Nim expression statement must be used or discarded, hence the `discard`. Python's `**` is
`^` in Nanuq.
"""

nbText: """
As you might be able to guess, this expression takes a column named “weight” and divides its
values by the square of the values in a column “height”, computing a person's BMI.

The code above expresses an abstract computation that we can save in a variable, manipulate
further, or just print:
"""

tabs """
bmi_expr = pl.col("weight") / (pl.col("height") ** 2)
print(bmi_expr)
""":
  nbCode:
    let bmiExpr = col("weight") / (col("height") ^ 2)
    echo bmiExpr

nanuq """
Where Python prints `/`, Nanuq prints `rust_div`: its `/` is Rust Polars' division, which
divides two integer columns as integers (see [Missing data](missing_data.html)). Here the
columns are floats, so both give the same numbers.
"""

nbText: """
Because expressions are lazy, no computations have taken place yet. That's what we need
contexts for.

## Contexts

Polars expressions need a *context* in which they are executed to produce a result.
Depending on the context it is used in, the same Polars expression can produce different
results. In this section, we will learn about the four most common contexts that Polars
provides¹:

1. `select`
2. `with_columns`
3. `filter`
4. `group_by`

We use the dataframe below to show how each of the contexts works.

"""

nanuq """
The original has a `birthdate` column of dates, which Nanuq does not have yet. Here, on both
sides, it is a `birth_year` column of integers.
"""

tabs """
df = pl.DataFrame(
    {
        "name": ["Alice Archer", "Ben Brown", "Chloe Cooper", "Daniel Donovan"],
        "birth_year": [1997, 1985, 1983, 1981],
        "weight": [57.9, 72.5, 53.6, 83.1],  # (kg)
        "height": [1.56, 1.77, 1.65, 1.75],  # (m)
    }
)

df
""":
  nbCode:
    let df = newDataFrame(
      series("name", ["Alice Archer", "Ben Brown", "Chloe Cooper", "Daniel Donovan"]),
      series("birth_year", [1997, 1985, 1983, 1981]),
      series("weight", [57.9, 72.5, 53.6, 83.1]),  # (kg)
      series("height", [1.56, 1.77, 1.65, 1.75]))  # (m)
    nbShow df

nbText: """
### `select`

The selection context `select` applies expressions over columns. The context `select` may
produce new columns that are aggregations, combinations of other columns, or literals:
"""

tabs """
df.select(
    bmi=bmi_expr,
    avg_bmi=bmi_expr.mean(),
    ideal_max_bmi=25,
)
""":
  nbCode:
    let selected = df.select(
      bmiExpr.alias("bmi"),
      bmiExpr.mean.alias("avg_bmi"),
      lit(25).alias("ideal_max_bmi"))
    nbShow selected

nanuq """
Nim has no keyword arguments that name new columns, so the names go in `alias`, and a
literal is wrapped in `lit`.
"""

nbText: """
The expressions in a context `select` must produce series that are all the same length or
they must produce a scalar. Scalars will be broadcast to match the length of the remaining
series. Literals, like the number used above, are also broadcast.

Note that broadcasting can also occur within expressions. For instance, consider the
expression below:
"""

tabs """
df.select(deviation=(bmi_expr - bmi_expr.mean()) / bmi_expr.std())
""":
  nbCode:
    let deviation = df.select(
      ((bmiExpr - bmiExpr.mean) / bmiExpr.std).alias("deviation"))
    nbShow deviation

nbText: """
Both the subtraction and the division use broadcasting within the expression because the
subexpressions that compute the mean and the standard deviation evaluate to single values.

The context `select` is very flexible and powerful and allows you to evaluate arbitrary
expressions independent of, and in parallel to, each other. This is also true of the other
contexts that we will see next.

### `with_columns`

The context `with_columns` is very similar to the context `select`. The main difference
between the two is that the context `with_columns` creates a new dataframe that contains the
columns from the original dataframe and the new columns according to its input expressions,
whereas the context `select` only includes the columns selected by its input expressions:
"""

tabs """
df.with_columns(
    bmi=bmi_expr,
    avg_bmi=bmi_expr.mean(),
    ideal_max_bmi=25,
)
""":
  nbCode:
    let withBmi = df.withColumns(
      bmiExpr.alias("bmi"),
      bmiExpr.mean.alias("avg_bmi"),
      lit(25).alias("ideal_max_bmi"))
    nbShow withBmi

nbText: """
Because of this difference between `select` and `with_columns`, the expressions used in a
context `with_columns` must produce series that have the same length as the original columns
in the dataframe, whereas it is enough for the expressions in the context `select` to
produce series that have the same length among them.

### `filter`

The context `filter` filters the rows of a dataframe based on one or more expressions that
evaluate to the Boolean data type.
"""

nanuq """
The original keeps the people born between 31 December 1982 and 1 January 1996, with
`is_between` on two dates; with birth years that is 1983 to 1995. Nanuq's `filter` takes one
predicate, so the two conditions are joined with `and`.
"""

tabs """
df.filter(
    pl.col("birth_year").is_between(1983, 1995),
    pl.col("height") > 1.7,
)
""":
  nbCode:
    let filtered = df.filter(
      col("birth_year").isBetween(1983, 1995) and col("height") > 1.7)
    nbShow filtered

nbText: """
### `group_by` and aggregations

In the context `group_by`, rows are grouped according to the unique values of the grouping
expressions. You can then apply expressions to the resulting groups, which may be of
variable lengths.

When using the context `group_by`, you can use an expression to compute the groupings
dynamically:
"""

tabs """
df.group_by(
    (pl.col("birth_year") // 10 * 10).alias("decade"),
).agg(pl.col("name"))
""":
  nbCode:
    nbShow df.groupBy(
      (col.birth_year div 10 * 10).alias("decade")
    ).agg(col.name)

nanuq """
In the original the decade is `pl.col("birthdate").dt.year() // 10 * 10`.
"""

nbText: """
After using `group_by` we use `agg` to apply aggregating expressions to the groups. Since in
the example above we only specified the name of a column, we get the groups of that column
as lists.

We can specify as many grouping expressions as we'd like and the context `group_by` will
group the rows according to the distinct values across the expressions specified. Here, we
group by a combination of decade of birth and whether the person is shorter than 1.7
metres:
"""

tabs """
df.group_by(
    (pl.col("birth_year") // 10 * 10).alias("decade"),
    (pl.col("height") < 1.7).alias("short?"),
).agg(pl.col("name"))
""":
  nbCode:
    nbShow df.groupBy(
      (col.birth_year div 10 * 10).alias("decade"),
      (col.height < 1.7).alias("short?")
    ).agg(col.name)

nbText: """
The resulting dataframe, after applying aggregating expressions, contains one column per
each grouping expression on the left and then as many columns as needed to represent the
results of the aggregating expressions. In turn, we can specify as many aggregating
expressions as we want:
"""

tabs """
df.group_by(
    (pl.col("birth_year") // 10 * 10).alias("decade"),
    (pl.col("height") < 1.7).alias("short?"),
).agg(
    pl.len(),
    pl.col("height").max().alias("tallest"),
    pl.col("weight", "height").mean().name.prefix("avg_"),
)
""":
  nbCode:
    let groups = df.groupBy(
      (col("birth_year") div 10 * 10).alias("decade"),
      (col("height") < 1.7).alias("short?"),
    ).agg(
      len(),
      col("height").max.alias("tallest"),
      col("weight", "height").mean.name.prefix("avg_"),
    )
    nbShow groups

nbText: """
See also `group_by_dynamic` and `rolling` for other grouping contexts.

## Expression expansion

The last example contained two grouping expressions and three aggregating expressions, and
yet the resulting dataframe contained six columns instead of five. If we look closely, the
last aggregating expression mentioned two different columns: “weight” and “height”.

Polars expressions support a feature called *expression expansion*. Expression expansion is
like a shorthand notation for when you want to apply the same transformation to multiple
columns. As we have seen, the expression

```python
pl.col("weight", "height").mean().name.prefix("avg_")
```

will compute the mean value of the columns “weight” and “height” and will rename them as
“avg_weight” and “avg_height”, respectively. In fact, the expression above is equivalent to
using the two following expressions:

```python
[
    pl.col("weight").mean().alias("avg_weight"),
    pl.col("height").mean().alias("avg_height"),
]
```

In this case, this expression expands into two independent expressions that Polars can
execute in parallel. In other cases, we may not be able to know in advance how many
independent expressions an expression will unfold into.

Consider this simple but elucidative example:

```python
(pl.col(pl.Float64) * 1.1).name.suffix("*1.1")
```

This expression will multiply all columns with data type `Float64` by `1.1`. The number of
columns this applies to depends on the schema of each dataframe. In the case of the
dataframe we have been using, it applies to two columns:
"""

tabs """
expr = (pl.col(pl.Float64) * 1.1).name.suffix("*1.1")
df.select(expr)
""":
  nbCode:
    let expr = (col(float) * 1.1).name.suffix("*1.1")
    let expanded = df.select(expr)
    nbShow expanded

nbText: """
In the case of the dataframe `df2` below, the same expression expands to 0 columns because
no column has the data type `Float64`:
"""

tabs """
df2 = pl.DataFrame(
    {
        "ints": [1, 2, 3, 4],
        "letters": ["A", "B", "C", "D"],
    }
)
df2.select(expr)
""":
  nbCode:
    let df2 = newDataFrame(
      series("ints", [1, 2, 3, 4]),
      series("letters", ["A", "B", "C", "D"]))
    let expandedNone = df2.select(expr)
    nbShow expandedNone

nbText: """
It is equally easy to imagine a scenario where the same expression would expand to dozens
of columns.

Next, you will learn about
[the lazy API and the function `explain`](lazy_api.html#previewing-the-query-plan), which
you can use to preview what an expression will expand to given a schema.

## Conclusion

Because expressions are lazy, when you use an expression inside a context Polars can try to
simplify your expression before running the data transformation it expresses. Separate
expressions within a context are embarrassingly parallel and Polars will take advantage of
that, while also parallelizing expression execution when using expression expansion.
Further performance gains can be obtained when using
[the lazy API of Polars](lazy_api.html), which is introduced next.

We have only scratched the surface of the capabilities of expressions. There are a ton more
expressions and they can be combined in a variety of ways. See the
[section on expressions](basic_operations.html) for a deeper dive on the different types of
expressions available.

---

¹ There are additional List and SQL contexts which are covered later in this guide. But for
simplicity, we leave them out of scope for now.
"""

bookSave()
