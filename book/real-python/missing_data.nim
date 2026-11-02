import nanuqbook
bookInit()

nbText: "# Missing data"

attribution realPython("How to Deal With Missing Data in Polars", "polars-missing-data",
  "polars-missing-data",
  "The data is the tutorial's: `tips.parquet` (restaurant bills, with some values taken " &
  "out), `sales_trends.csv` and `ft_exercise.parquet` (episodes of *Fawlty Towers*), in " &
  "`data/real-python/`. Cells that repeat an earlier one are left out.")

nbText: """
## Finding the gaps

A table of restaurant bills and tips with some values missing, read lazily, and how many
nulls each column has:
"""

tabs """
import polars as pl

tips = pl.scan_parquet("data/real-python/tips.parquet")

tips.collect()
""":
  nbCode:
    import nanuq

    let tips = scanParquet("data/real-python/tips.parquet")

    nbShow tips.collect

tabs """
(tips.null_count()).collect()
""":
  nbCode:
    nbShow tips.nullCount.collect

nbText: """
Rows where both the bill and the tip are missing:
"""

tabs """
(tips.filter(pl.col("total").is_null() & pl.col("tip").is_null())).collect()
""":
  nbCode:
    nbShow tips.filter(col.total.isNull and col.tip.isNull).collect

nbText: """
## Dropping and filling

Dropping the rows without a bill removes those, and a missing tip can become 0:
"""

tabs """
(
    tips.drop_nulls(pl.col("total")).filter(
        pl.col("total").is_null() & pl.col("tip").is_null()
    )
).collect()
""":
  nbCode:
    nbShow tips.dropNulls("total").filter(
      col.total.isNull and col.tip.isNull).collect

nanuq """
Python's `drop_nulls` takes column names or expressions (here `pl.col("total")`); Nanuq's
takes names.
"""

tabs """
(
    tips.drop_nulls(pl.col("total"))
    .with_columns(pl.col("tip").fill_null(0))
    .filter(pl.col("tip").is_null())
).collect()
""":
  nbCode:
    nbShow tips.dropNulls("total")
      .withColumns(col.tip.fillNull(0))
      .filter(col.tip.isNull).collect

nbText: """
A missing `time` (lunch or dinner) can be taken from the row before, as the bills are in order:
"""

tabs """
(tips.filter(pl.col("time").is_null())).collect()
""":
  nbCode:
    nbShow tips.filter(col.time.isNull).collect

tabs """
(tips.filter(pl.col("record_id").is_in([2, 3, 4, 14, 15, 16]))).collect()
""":
  nbCode:
    nbShow tips.filter(col.record_id.isIn([2, 3, 4, 14, 15, 16])).collect

tabs """
(
    tips.drop_nulls("total")
    .with_columns(pl.col("tip").fill_null(0))
    .with_columns(pl.col("time").fill_null(strategy="forward"))
    .filter(pl.col("record_id").is_in([3, 15]))
).collect()
""":
  nbCode:
    nbShow tips.dropNulls("total")
      .withColumns(col.tip.fillNull(0))
      .withColumns(col.time.fillNull(FillNullStrategy.Forward))
      .filter(col.record_id.isIn([3, 15])).collect

nbText: """
## Several columns at once

`all_horizontal` checks a condition across columns, row by row; its negation keeps the rows that
have at least one of the two:
"""

tabs """
(tips.filter(pl.all_horizontal(pl.col("total", "tip").is_null()))).collect()
""":
  nbCode:
    nbShow tips.filter(allHorizontal(col("total", "tip").isNull)).collect

tabs """
(
    tips.filter(~pl.all_horizontal(pl.col("total", "tip").is_null()))
    .with_columns(pl.col("tip").fill_null(0))
    .with_columns(pl.col("time").fill_null(strategy="forward"))
).null_count().collect()
""":
  nbCode:
    nbShow tips.filter(not allHorizontal(col("total", "tip").isNull))
      .withColumns(col.tip.fillNull(0))
      .withColumns(col.time.fillNull(FillNullStrategy.Forward))
      .nullCount.collect

nbText: """
Filling by data type, with selectors:
"""

tabs """
import polars.selectors as cs

scientists = pl.LazyFrame(
    {
        "scientist_id": [1, 2, 3, 4, 5],
        "first_name": ["Isaac", "Louis", None, "Charles", "Marie"],
        "last_name": [None, "Pasteur", "Einstein", "Darwin", "Curie"],
        "birth_year": [1642, 1822, None, 1809, 1867],
        "death_year": [1726, 1895, 1955, None, 1934],
    }
)

(
    scientists.with_columns(cs.string().fill_null("Unknown")).with_columns(
        cs.integer().fill_null(0)
    )
).collect()
""":
  nbCode:
    let scientists = newDataFrame(
      series("scientist_id", [1, 2, 3, 4, 5]),
      series("first_name", [some("Isaac"), some("Louis"), none(string), some("Charles"),
                            some("Marie")]),
      series("last_name", [none(string), some("Pasteur"), some("Einstein"), some("Darwin"),
                           some("Curie")]),
      series("birth_year", [some(1642), some(1822), none(int), some(1809), some(1867)]),
      series("death_year", [some(1726), some(1895), some(1955), none(int), some(1934)])).lazy

    nbShow scientists.withColumns(col(string).fillNull("Unknown")).withColumns(
      col(SomeInteger).fillNull(0)).collect

nanuq """
Nanuq selects columns by Nim type: `col(string)` is `cs.string()` and `col(SomeInteger)` is
`cs.integer()`.
"""

nbText: """
## Not a number is not null

`NaN` and infinities are values, not nulls, so `fill_null` leaves them alone. Turning them into
nulls first lets them be filled like the rest, here with a straight-line guess from the last two
years:
"""

tabs """
sales_trends = pl.scan_csv("data/real-python/sales_trends.csv")

(
    sales_trends.with_columns(
        pl.col("next_year").replace(
            [float("inf"), -float("inf"), float("NaN")], None
        )
    ).with_columns(
        pl.col("next_year").fill_null(
            pl.col("current_year")
            + (pl.col("current_year") - pl.col("last_year"))
        )
    )
).collect()
""":
  nbCode:
    let salesTrends = scanCsv("data/real-python/sales_trends.csv")

    nbShow salesTrends.withColumns(
        choose(if col.next_year.isFinite: col.next_year).alias("next_year")
      ).withColumns(
        col.next_year.fillNull(
          col.current_year + (col.current_year - col.last_year))
      ).collect

nanuq """
Nanuq's `replace` cannot replace by a null yet (its new values are plain Nim values), so the Nim
tab keeps the finite values with a `choose` that has no `else`: the other rows, infinities and
`NaN`, become null.
"""

nbText: """
## Exercise: Fawlty Towers

The tutorial ends with an exercise on a table of the twelve episodes of *Fawlty Towers* with
gaps in it. Here is how many, and the solution:
"""

tabs """
episodes = pl.scan_parquet("data/real-python/ft_exercise.parquet")

episodes.null_count().collect()
""":
  nbCode:
    let episodes = scanParquet("data/real-python/ft_exercise.parquet")

    nbShow episodes.nullCount.collect

tabs """
(
    episodes.with_columns(
        pl.when(pl.col("episode") == 6)
        .then(pl.col("series").fill_null(strategy="forward"))
        .otherwise(pl.col("series").fill_null(strategy="backward"))
    )
    .with_columns(
        pl.when(pl.col("episode") == 4)
        .then(pl.col("title").fill_null("The Hotel Inspectors"))
        .otherwise(pl.col("title").fill_null("Waldorf Salad"))
    )
    .with_columns(pl.col("original_date").interpolate())
).collect()
""":
  nbCode:
    nbShow episodes.withColumns(
        choose(if col.episode == 6: col.series.fillNull(FillNullStrategy.Forward)
               else: col.series.fillNull(FillNullStrategy.Backward)).alias("series"))
      .withColumns(
        choose(if col.episode == 4: col.title.fillNull("The Hotel Inspectors")
               else: col.title.fillNull("Waldorf Salad")).alias("title"))
      .withColumns(col.original_date.interpolate)
      .collect

nanuq """
The tutorial's solution ends with `.null_count()`, to show that nothing is missing any more;
the port shows the filled table instead. Each `choose` in the Nim tab gets an `alias`, so that
it replaces its column for sure.
"""

bookSave()
