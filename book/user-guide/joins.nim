import nanuqbook
bookInit()

nbText: "# Joins"

attribution userGuide("Joins", "transformations/joins",
  "Left out: the non-equi join `join_where`.")

nbText: """
A join operation combines columns from one or more dataframes into a new dataframe. The
different “joining strategies” and matching criteria used by the different types of joins
influence how columns are combined and also what rows are included in the result of the
join operation.

The most common type of join is an “equi join”, in which rows are matched by a key
expression. Polars supports several joining strategies for equi joins, which determine
exactly how we handle the matching of rows. Polars also supports “non-equi joins”, a type of
join where the matching criterion is not an equality, and a type of join where rows are
matched by key proximity, called “asof join”.

## Quick reference table

The table below acts as a quick reference for people who know what they are looking for. If
you want to learn about joins in general and how to work with them in Polars, feel free to
skip the table and keep reading below.

| Type                  | Function                   | Brief description |
| --------------------- | -------------------------- | ----------------- |
| Equi inner join       | `join(..., how="inner")`   | Keeps rows that matched both on the left and right. |
| Equi left outer join  | `join(..., how="left")`    | Keeps all rows from the left plus matching rows from the right. Non-matching rows from the left have their right columns filled with `null`. |
| Equi right outer join | `join(..., how="right")`   | Keeps all rows from the right plus matching rows from the left. Non-matching rows from the right have their left columns filled with `null`. |
| Equi full join        | `join(..., how="full")`    | Keeps all rows from either dataframe, regardless of whether they match or not. Non-matching rows from one side have the columns from the other side filled with `null`. |
| Equi semi join        | `join(..., how="semi")`    | Keeps rows from the left that have a match on the right. |
| Equi anti join        | `join(..., how="anti")`    | Keeps rows from the left that do not have a match on the right. |
| Non-equi inner join   | `join_where`               | Finds all possible pairings of rows from the left and right that satisfy the given predicate(s). |
| Asof join             | `join_asof`/`join_asof_by` | Like a left outer join, but matches on the nearest key instead of on exact key matches. |
| Cartesian product     | `join(..., how="cross")`   | Computes the [Cartesian product](https://en.wikipedia.org/wiki/Cartesian_product) of the two dataframes. |
"""

nanuq """
In Nanuq the strategies are values of the enum `JoinType`, named as in Rust Polars, where
Python Polars uses strings: `join(..., how = Inner)` (the default), `Left`, `Right`, `Full`,
`Semi`, `Anti` and `Cross`. Nanuq has `joinAsof` but no `join_where` yet, so the section on
non-equi joins is left out below.
"""

nbText: """
## Equi joins

In an equi join, rows are matched by checking equality of a key expression. You can do an
equi join with the function `join` by specifying the name of the column to be used as key. For the
examples, we will be loading some (modified) Monopoly property data.

First, we load a dataframe that contains property names and their colour group in the game:
"""

tabs """
import polars as pl

props_groups = pl.read_csv("data/polars/monopoly_props_groups.csv").head(5)
props_groups
""":
  nbCode:
    import nanuq

    let propsGroups = readCsv("data/polars/monopoly_props_groups.csv").head(5)
    nbShow propsGroups

nbText: "Next, we load a dataframe that contains property names and their price in the game:"

tabs """
props_prices = pl.read_csv("data/polars/monopoly_props_prices.csv").head(5)
props_prices
""":
  nbCode:
    let propsPrices = readCsv("data/polars/monopoly_props_prices.csv").head(5)
    nbShow propsPrices

nbText: """
Now, we join both dataframes to create a dataframe that contains property names, colour
groups, and prices:
"""

tabs """
props_groups.join(props_prices, on="property_name")
""":
  nbCode:
    let joined = propsGroups.join(propsPrices, on = ["property_name"])
    nbShow joined

nanuq """
In Nanuq `on` always takes a list of keys, even when there is only one.
"""

nbText: """
The result has four rows but both dataframes used in the operation had five rows. Polars
uses a joining strategy to determine what happens with rows that have multiple matches or
with rows that have no match at all. By default, Polars computes an “inner join” but there
are [other join strategies that we show next](#join-strategies).

In the example above, the two dataframes conveniently had the column we wish to use as key
with the same name and with the values in the exact same format. Suppose, for the sake of
argument, that one of the dataframes had a differently named column and the other had the
property names in lower case:
"""

tabs """
props_groups2 = props_groups.with_columns(
    pl.col("property_name").str.to_lowercase(),
)
props_groups2
""":
  nbCode:
    let propsGroups2 = propsGroups.withColumns(col("property_name").str.toLowercase)
    nbShow propsGroups2

tabs """
props_prices2 = props_prices.select(
    pl.col("property_name").alias("name"), pl.col("cost")
)
props_prices2
""":
  nbCode:
    let propsPrices2 = propsPrices.select(col("property_name").alias("name"), col("cost"))
    nbShow propsPrices2

nbText: """
In a situation like this, where we may want to perform the same join as before, we can
leverage `join`'s flexibility and specify arbitrary expressions to compute the joining key
on the left and on the right, allowing one to compute row keys dynamically:
"""

nanuq """
In Nanuq these are `leftOn` and `rightOn`, which take column names or expressions.
"""

tabs """
props_groups2.join(
    props_prices2,
    left_on="property_name",
    right_on=pl.col("name").str.to_lowercase(),
)
""":
  nbCode:
    let byName = propsGroups2.join(propsPrices2,
      leftOn = [col("property_name")], rightOn = [col("name").str.toLowercase])
    nbShow byName

nbText: """
Because we are joining on the right with an expression, Polars preserves the column
“property_name” from the left and the column “name” from the right so we can have access to
the original values that the key expressions were applied to.
"""

nbText: """
## Join strategies

When computing a join with `df1.join(df2, ...)`, we can specify one of many different
join strategies. A join strategy specifies what rows to keep from each dataframe based on
whether they match rows from the other dataframe.

### Inner join

In an inner join the resulting dataframe only contains the rows from the left and right
dataframes that matched. That is the default strategy used by `join` and above we can see
an example of that. We repeat the example here and explicitly specify the join strategy:
"""

tabs """
props_groups.join(props_prices, on="property_name", how="inner")
""":
  nbCode:
    let innerJoin = propsGroups.join(propsPrices, on = ["property_name"], how = Inner)
    nbShow innerJoin

nbText: """
The result does not include the row from `props_groups` that contains “The Shire” and the
result also does not include the row from `props_prices` that contains “Sesame Street”.

### Left join

A left outer join is a join where the result contains all the rows from the left dataframe
and the rows of the right dataframe that matched any rows from the left dataframe.
"""

tabs """
props_groups.join(props_prices, on="property_name", how="left")
""":
  nbCode:
    let leftJoin = propsGroups.join(propsPrices, on = ["property_name"], how = Left)
    nbShow leftJoin

nbText: """
If there are any rows from the left dataframe that have no matching rows on the right
dataframe, they get the value `null` on the new columns.

### Right join

Computationally speaking, a right outer join is exactly the same as a left outer join, but
with the arguments swapped. Here is an example:
"""

tabs """
result = props_groups.join(props_prices, on="property_name", how="right")
result
""":
  nbCode:
    let rightJoin = propsGroups.join(propsPrices, on = ["property_name"], how = Right)
    nbShow rightJoin

nbText: """
We show that `df1.join(df2, how="right", ...)` is the same as
`df2.join(df1, how="left", ...)`, up to the order of the columns of the result, with the
computation below:
"""

nanuq """
Python checks it with `DataFrame.equals`, which Nanuq does not have yet, so the Nim version
compares the two frames as text.
"""

tabs """
print(
    result.equals(
        props_prices.join(
            props_groups,
            on="property_name",
            how="left",
        ).select(pl.col("group"), pl.col("property_name"), pl.col("cost"))
    )
)
""":
  nbCode:
    let swapped = propsPrices.join(propsGroups, on = ["property_name"], how = Left)
      .select(col("group"), col("property_name"), col("cost"))
    echo $rightJoin == $swapped

nbText: """
### Full join

A full outer join will keep all of the rows from the left and right dataframes, even if they
don't have matching rows in the other dataframe:
"""

tabs """
props_groups.join(props_prices, on="property_name", how="full")
""":
  nbCode:
    let fullJoin = propsGroups.join(propsPrices, on = ["property_name"], how = Full)
    nbShow fullJoin

nbText: """
In this case, we see that we get two columns `property_name` and `property_name_right` to
make up for the fact that we are matching on the column `property_name` of both dataframes
and there are some names for which there are no matches. The two columns help differentiate
the source of each row data. If we wanted to force `join` to coalesce the two columns
`property_name` into a single column, we could set `coalesce=True` explicitly:
"""

tabs """
props_groups.join(
    props_prices,
    on="property_name",
    how="full",
    coalesce=True,
)
""":
  nbCode:
    import std/options

    let fullCoalesced = propsGroups.join(propsPrices, on = ["property_name"], how = Full,
                                         coalesce = some(true))
    nbShow fullCoalesced

nbText: """
When not set, the parameter `coalesce` is determined automatically from the join strategy
and the key(s) specified, which is why the inner, left, and right, joins acted as if
`coalesce=True`, even though we didn't set it.
"""

nanuq """
In Nanuq `coalesce` is an `Option[bool]`, so setting it is `coalesce = some(true)`.
"""

nbText: """
### Semi join

A semi join will return the rows of the left dataframe that have a match in the right
dataframe, but we do not actually join the matching rows:
"""

tabs """
props_groups.join(props_prices, on="property_name", how="semi")
""":
  nbCode:
    let semiJoin = propsGroups.join(propsPrices, on = ["property_name"], how = Semi)
    nbShow semiJoin

nbText: """
A semi join acts as a sort of row filter based on a second dataframe.

### Anti join

Conversely, an anti join will return the rows of the left dataframe that do not have a
match in the right dataframe:
"""

tabs """
props_groups.join(props_prices, on="property_name", how="anti")
""":
  nbCode:
    let antiJoin = propsGroups.join(propsPrices, on = ["property_name"], how = Anti)
    nbShow antiJoin

nanuq """
Not ported yet: the original's section on **non-equi joins** (`join_where`), where a
predicate such as `pl.col("cash") > pl.col("cost")` decides which rows pair up.
"""

nbText: """
## Asof join

An `asof` join is like a left join except that we match on nearest key rather than equal
keys. In Polars we can do an asof join with the `join_asof` method.

For the asof join we will consider a scenario inspired by the stock market. Suppose a stock
market broker has a dataframe called `df_trades` showing transactions it has made for
different stocks.
"""

nanuq """
In Nim the times are std/times `DateTime`s. Nanuq stores them as UTC instants in a
`Datetime` column without a time zone, like Python's naive `datetime`.
"""

tabs """
from datetime import datetime

df_trades = pl.DataFrame(
    {
        "time": [
            datetime(2020, 1, 1, 9, 1, 0),
            datetime(2020, 1, 1, 9, 1, 0),
            datetime(2020, 1, 1, 9, 3, 0),
            datetime(2020, 1, 1, 9, 6, 0),
        ],
        "stock": ["A", "B", "B", "C"],
        "trade": [101, 299, 301, 500],
    }
)
df_trades
""":
  nbCode:
    import std/times

    proc at(hour, minute: int): DateTime =
      dateTime(2020, mJan, 1, hour, minute, 0, zone = utc())

    let dfTrades = newDataFrame(
      series("time", [at(9, 1), at(9, 1), at(9, 3), at(9, 6)]),
      series("stock", ["A", "B", "B", "C"]),
      series("trade", [101, 299, 301, 500]))
    nbShow dfTrades

nbText: """
The broker has another dataframe called `df_quotes` showing prices it has quoted for these
stocks:
"""

tabs """
df_quotes = pl.DataFrame(
    {
        "time": [
            datetime(2020, 1, 1, 9, 0, 0),
            datetime(2020, 1, 1, 9, 2, 0),
            datetime(2020, 1, 1, 9, 4, 0),
            datetime(2020, 1, 1, 9, 6, 0),
        ],
        "stock": ["A", "B", "C", "A"],
        "quote": [100, 300, 501, 102],
    }
)
df_quotes
""":
  nbCode:
    let dfQuotes = newDataFrame(
      series("time", [at(9, 0), at(9, 2), at(9, 4), at(9, 6)]),
      series("stock", ["A", "B", "C", "A"]),
      series("quote", [100, 300, 501, 102]))
    nbShow dfQuotes

nbText: """
You want to produce a dataframe showing for each trade the most recent quote provided _on
or before_ the time of the trade. You do this with `join_asof` (using the default
`strategy = "backward"`). To avoid joining between trades on one stock with a quote on
another you must specify an exact preliminary join on the stock column with `by="stock"`.
"""

nanuq """
In Nanuq the strategy is a value of the enum `AsofStrategy` (`Backward`, the default,
`Forward` or `Nearest`).
"""

tabs """
df_trades.join_asof(df_quotes, on="time", by="stock", check_sortedness=False)
""":
  nbCode:
    let dfAsofJoin = dfTrades.joinAsof(dfQuotes, on = "time", by = "stock",
                                       checkSortedness = false)
    nbShow dfAsofJoin

nbText: """
If you want to make sure that only quotes within a certain time range are joined to the
trades you can specify the `tolerance` argument. In this case we want to make sure that the
last preceding quote is within 1 minute of the trade so we set `tolerance = "1m"`.
"""

nanuq """
The tolerance can also be a std/times interval: `tolerance = 1.minutes`.
"""

tabs """
df_trades.join_asof(
    df_quotes, on="time", by="stock", tolerance="1m", check_sortedness=False
)
""":
  nbCode:
    let dfAsofToleranceJoin = dfTrades.joinAsof(dfQuotes, on = "time", by = "stock",
                                                tolerance = "1m", checkSortedness = false)
    nbShow dfAsofToleranceJoin

nbText: """
## Cartesian product

Polars allows you to compute the
[Cartesian product](https://en.wikipedia.org/wiki/Cartesian_product) of two dataframes,
producing a dataframe where all rows of the left dataframe are paired up with all the rows
of the right dataframe. To compute the Cartesian product of two dataframes, you can pass the
strategy `how="cross"` to the function `join` without specifying any of `on`, `left_on`,
and `right_on`:
"""

tabs """
players = pl.DataFrame({"name": ["Alice", "Bob"], "cash": [78, 135]})
tokens = pl.DataFrame({"monopoly_token": ["hat", "shoe", "boat"]})
players.select(pl.col("name")).join(tokens, how="cross")
""":
  nbCode:
    let players = newDataFrame(series("name", ["Alice", "Bob"]), series("cash", [78, 135]))
    let tokens = newDataFrame(series("monopoly_token", ["hat", "shoe", "boat"]))
    let crossJoin = players.select(col("name")).join(tokens, how = Cross)
    nbShow crossJoin


bookSave()
