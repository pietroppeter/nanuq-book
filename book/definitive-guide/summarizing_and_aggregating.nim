import nanuqbook
bookInit()

nbText: "# Summarizing and aggregating"

attribution definitiveGuide(13, "Summarizing and Aggregating",
  "Data is read from `data/definitive-guide/`. Left out: the examples on `sales.csv` " &
  "(15 MB, origin not stated), which show the same group-by methods on another table. " &
  "Group-bys get `maintain_order=True` on the Python side where the order shows.")

nbText: """
Summarizing means turning many rows into few: one per group, one per window of time, or
one per row across columns. This chapter goes through the ways Polars (and Nanuq) do it.

## Split, apply, and combine

A group-by *splits* the rows by the values of one or more columns, *applies* an
aggregation to each group, and *combines* the results into a new frame.

## GroupBy context

`group_by` alone computes nothing; it waits for an aggregation.
"""

tabs """
import polars as pl

fruit = pl.read_csv("data/definitive-guide/fruit.csv")
fruit_grouped = fruit.group_by("is_round", maintain_order=True)
fruit_grouped.len()
""":
  nbCode:
    import nanuq

    let fruit = readCsv("data/definitive-guide/fruit.csv")
    let fruitGrouped = fruit.groupBy("is_round")
    nbShow fruitGrouped.len()

nbText: """
The rest of the chapter uses the Top 2000 of 2023, the yearly list of the 2000 most
popular songs according to the listeners of the Dutch radio station NPO Radio 2. It comes
as an Excel file whose first row is a title, so one row is skipped:
"""

tabs """
top2000 = pl.read_excel(
    "data/definitive-guide/top2000-2023.xlsx", read_options={"skip_rows": 1}
).set_sorted("positie")
top2000.head()
""":
  nbCode:
    let top2000 = readExcel(
      "data/definitive-guide/top2000-2023.xlsx", skipRows = 1
    ).setSorted("positie")
    nbShow top2000.head()

nanuq """
Python passes the options of its Excel engine as a dictionary (`read_options`); Nanuq's
`readExcel` has them as parameters. Both read the file with calamine.
"""

nbText: """
Without an aggregation, a column becomes a list per group: all the songs of each year,
as "artist - title".
"""

tabs """
(
    top2000.group_by("jaar")
    .agg(
        songs=pl.concat_str(
            pl.col("artiest"), pl.lit(" - "), pl.col("titel")
        ),
    )
    .sort("jaar", descending=True)
)
""":
  nbCode:
    nbShow top2000.groupBy("jaar")
      .agg(
        concatStr([col.artiest, lit(" - "), col.titel]).alias("songs"))
      .sort("jaar", descending = true)

nbText: """
### The descriptives

`head` and `tail` keep the first and last rows of each group. Since the list is sorted by
position, these are the best and worst ranked songs of each year:
"""

tabs """
(
    top2000.group_by("jaar", maintain_order=True)
    .head(3)
    .sort("jaar", descending=True, maintain_order=True)
    .head(9)
)
""":
  nbCode:
    nbShow top2000.groupBy("jaar")
      .head(3)
      .sort("jaar", descending = true, maintainOrder = true)
      .head(9)

tabs """
(
    top2000.group_by("jaar", maintain_order=True)
    .tail(3)
    .sort("jaar", descending=True, maintain_order=True)
    .head(9)
)
""":
  nbCode:
    nbShow top2000.groupBy("jaar")
      .tail(3)
      .sort("jaar", descending = true, maintainOrder = true)
      .head(9)

nanuq """
Both tabs keep the order within a year in the final sort (`maintain_order=True`), so the
three songs of a year stay in list order.
"""

nbText: """
And the artists with the most songs in the list:
"""

tabs """
top2000.group_by("artiest").len().sort("len", "artiest", descending=[True, False]).head(10)
""":
  nbCode:
    nbShow top2000.groupBy("artiest").len().sort(["len", "artiest"], descending = [true, false]).head(10)

nanuq """
Ties on the count are broken by name in both tabs, so that the tenth place is the same.
The book goes on with `max`, `sum`, `n_unique`, `mean` and `quantile` on a group-by of a
sales table; Nanuq has the same shortcuts (`groupBy(…).max()`, …).
"""

nbText: """
## Row-wise aggregations

A fold walks over columns, carrying an accumulator from one to the next:
"""

tabs """
fold_example = pl.DataFrame({"col1": [2], "col2": [3], "col3": [4]})

fold_example.with_columns(
    sum=pl.fold(
        acc=pl.lit(0),
        function=lambda acc, x: acc + x,
        exprs=pl.col("*"),
    )
)
""":
  nbCode:
    let foldExample = newDataFrame:
      col1: [2]
      col2: [3]
      col3: [4]

    nbShow foldExample.withColumns(
      fold(
        acc = lit(0),
        f = proc (acc, x: Series): Series = acc + x,
        exprs = col("*")).alias("sum"))

nbText: """
The columns to fold can be any expressions, here each product weighted:
"""

tabs """
products = pl.DataFrame(
    {
        "product_A": [10, 20, 30],
        "product_B": [20, 30, 40],
        "product_C": [30, 40, 50],
    }
)

weights = {"product_A": 0.5, "product_B": 1.5, "product_C": 2.0}

weighted_exprs = [
    (pl.col(product) * weight).alias(product)
    for product, weight in weights.items()
]

products_with_weighted_sum = products.with_columns(
    weighted_sum=pl.fold(
        acc=pl.lit(0),
        function=lambda acc, x: acc + x,
        exprs=weighted_exprs,
    )
)

products_with_weighted_sum
""":
  nbCode:
    import std/[sugar, tables]

    let products = newDataFrame:
      product_A: [10, 20, 30]
      product_B: [20, 30, 40]
      product_C: [30, 40, 50]

    let weights = {"product_A": 0.5, "product_B": 1.5, "product_C": 2.0}.toOrderedTable

    let weightedExprs = sugar.collect:
      for product, weight in weights:
        (col(product) * weight).alias(product)

    let productsWithWeightedSum = products.withColumns(
      fold(
        acc = lit(0),
        f = proc (acc, x: Series): Series = acc + x,
        exprs = weightedExprs).alias("weighted_sum"))

    nbShow productsWithWeightedSum

nbText: """
## Window functions in selection context

`over` ranks each song within its year, and keeps all rows. The book then shows ten
random rows:
"""

tabs """
print(
    top2000.select(
        "jaar",
        "artiest",
        "titel",
        "positie",
        year_rank=pl.col("positie").rank().over("jaar"),
    ).sample(10, seed=42)
)
""":
  nbCode:
    echo top2000.select(
      col.jaar,
      col.artiest,
      col.titel,
      col.positie,
      col.positie.rank.over("jaar").alias("year_rank"),
    ).sample(10, seed = 42)

nanuq """
The random rows differ between the tabs even with the same seed (Nanuq's Polars crate is
older than py-polars'), so both are printed rather than compared.
"""

nbText: """
## Dynamic grouping

Grouping by windows of time (`group_by_dynamic`) is covered in the user guide chapter
[Time series: grouping](../user-guide/time_series_grouping.html).

## Rolling aggregations

Two stores, sales every other weekday in April 2024:
"""

tabs """
from datetime import date

dates = pl.date_range(
    start=date(2024, 4, 1),
    end=date(2024, 4, 26),
    interval="2d",
    eager=True,
)
dates = dates.filter(dates.dt.weekday() < 6)
dates_repeated = pl.concat([dates, dates]).sort()

small_sales_df = (
    pl.DataFrame(
        {
            "date": dates_repeated,
            "store": ["Store A", "Store B"] * dates.len(),
            "sales": [
                200, 150, 220, 160, 250, 180, 270, 190, 280, 210,
                210, 170, 220, 180, 240, 190, 250, 200, 260, 210,
            ],
        }
    )
    .set_sorted("date")
    .set_sorted("store")
)
small_sales_df
""":
  nbCode:
    let dates = select(
        dateRange(date(2024, 4, 1), date(2024, 4, 26), "2d").alias("date"))
      .filter(col.date.dt.weekday < 6)
    let datesRepeated = concat([dates, dates]).sort("date")

    var stores: seq[string]
    for i in 0 ..< dates.height: stores.add ["Store A", "Store B"]

    let smallSalesDf = datesRepeated.hstack([
        series("store", stores),
        series("sales", [
          200, 150, 220, 160, 250, 180, 270, 190, 280, 210,
          210, 170, 220, 180, 240, 190, 250, 200, 260, 210])])
      .setSorted("date")
      .setSorted("store")
    nbShow smallSalesDf

nanuq """
Python builds the dates as a Series; in Nanuq a date range is an expression, so the dates
are a one-column frame, and the other columns are stacked next to it with `hstack`.
"""

nbText: """
A rolling window of 7 days per store sums the sales of the last week at every date; a join
puts the result next to each day's sales:
"""

tabs """
result = small_sales_df.rolling(
    index_column="date",
    period="7d",
    group_by="store",
).agg(
    sum_of_last_7_days_sales=pl.sum("sales")
)

final_df = small_sales_df.join(result, on=["date", "store"])

final_df
""":
  nbCode:
    let result = smallSalesDf.rolling(
      indexColumn = "date",
      period = "7d",
      groupBy = "store",
    ).agg(
      col.sales.sum.alias("sum_of_last_7_days_sales"))

    let finalDf = smallSalesDf.join(result, on = ["date", "store"])

    nbShow finalDf

nbText: """
## Upsampling

Upsampling adds the missing days, with nulls:
"""

tabs """
upsampled_small_sales_df = small_sales_df.upsample(
    time_column="date", every="1d", group_by="store", maintain_order=True
)

upsampled_small_sales_df
""":
  nbCode:
    let upsampledSmallSalesDf = smallSalesDf.upsample(
      timeColumn = "date", every = "1d", groupBy = "store", maintainOrder = true)

    nbShow upsampledSmallSalesDf

nbText: """
which can then be filled: the store name forward, the sales by linear interpolation.
"""

tabs """
upsampled_small_sales_df.select(
    "date", pl.col("store").forward_fill(), pl.col("sales").interpolate()
)
""":
  nbCode:
    nbShow upsampledSmallSalesDf.select(
      col.date, col.store.forwardFill, col.sales.interpolate)

bookSave()
