import nanuqbook
bookInit()

nbText: "# Reshaping and Tidy Data"

attribution modernPolars("Reshaping and Tidy Data", "tidy",
  "The data is the book's NBA 2015-16 results (scraped from basketball-reference.com by the " &
  "book), read from `data/modern-polars/nba/`; the scraping code is left out. Plots and the " &
  "statsmodels regression are left out, and tables show 10 rows instead of 5.")

nbText: """
There's a [whole paper](https://vita.had.co.nz/papers/tidy-data.pdf) by Hadley Wickham about
tidy data but it's in a PDF so you're probably not going to read it. Here's the paper's
definition of tidy data:

1. Each variable forms a column.
2. Each observation forms a row.
3. Each type of observational unit forms a table.

As Dr Wickham notes, this is [Codd's 3rd Normal Form](https://en.wikipedia.org/wiki/Third_normal_form)
but in statspeak rather than databasespeak.

The meaning of "variable" and "observation" depend on what we're studying, so tidy data is a
concept that you mostly learn through experience and ✨vibes✨.

Now we'll explore what tidy data looks like for an NBA results dataset.

## Get the data
"""

tabs """
import polars as pl

nba_glob = "data/modern-polars/nba/*.csv"
pl.scan_csv(nba_glob).head().collect()
""":
  nbCode:
    import nanuq

    let nbaGlob = "data/modern-polars/nba/*.csv"
    nbShow scanCsv(nbaGlob).head.collect

nanuq """
The book downloads one page per month of the 2015-16 season with `pd.read_html`, keeps five
columns under new names, and saves each month as a CSV, messy on purpose. The port starts from
those CSVs.
"""

nbText: """
## Cleaning 🧹

Nothing super interesting here:
"""

tabs """
games_pl = (
    pl.scan_csv(nba_glob)
    .with_columns(
        pl.col("date").str.strptime(pl.Date, "%a, %b %d, %Y"),
    )
    .sort("date")
    .with_row_index("game_id")
)
games_pl.head().collect()
""":
  nbCode:
    let gamesPl = scanCsv(nbaGlob)
      .withColumns(
        col.date.str.strptime(Date, "%a, %b %d, %Y"))
      .sort("date")
      .withRowIndex("game_id")
    nbShow gamesPl.head.collect

nbText: """
Polars does have a
[`drop_nulls`](https://docs.pola.rs/api/python/stable/reference/dataframe/api/polars.DataFrame.drop_nulls.html)
method but the only parameter it takes is `subset`, which lets you consider null values just for
a subset of the columns. Polars `drop_nulls` will drop the row if *any* values are null. If you
only want to drop when all values are null, the docs recommend
`.filter(~pl.all_horizontal(pl.all().is_null()))`.

A previous version of the Polars example used
[`pl.fold`](https://docs.pola.rs/user-guide/expressions/folds/), which is for fast horizontal
operations. It doesn't come up anywhere else in this book, so consider this your warning that it
exists.

## Pivot and Melt

Here's a simple explanation of `pivot`ing and `melt`ing. If you already know what pivot and
melt are, feel free to scroll past this bit.

### Pivot

Suppose you have a dataframe that looks like this:
"""

tabs """
from datetime import date

prices = pl.DataFrame({
    "date": [*[date(2020, 1, 1)]*4, *[date(2020, 1, 2)]*4, *[date(2020, 1, 3)]*4],
    "ticker": [*["AAPL", "TSLA", "MSFT", "NFLX"]*3],
    "price": [100, 200, 300, 400, 110, 220, 330, 420, 105, 210, 315, 440],
})
prices
""":
  nbCode:
    import std/sequtils

    let prices = newDataFrame(
      series("date", sequtils.repeat(date(2020, 1, 1), 4) & sequtils.repeat(date(2020, 1, 2), 4) &
                     sequtils.repeat(date(2020, 1, 3), 4)),
      series("ticker", cycle(["AAPL", "TSLA", "MSFT", "NFLX"], 3)),
      series("price", [100, 200, 300, 400, 110, 220, 330, 420, 105, 210, 315, 440]))
    nbShow prices

nbText: """
You can call `df.pivot` to get a dataframe that looks like this:
"""

tabs """
pivoted = prices.pivot(index="date", values="price", on="ticker")
pivoted
""":
  nbCode:
    let pivoted = prices.pivot(index = "date", values = "price", on = "ticker")
    nbShow pivoted

nbText: """
As you can see, `.pivot` creates a dataframe where the columns are the unique labels from one
column ("ticker"), alongside the index column ("date"). The values for the non-index columns are
taken from the corresponding rows of the `values` column ("price").

If our dataframe had multiple prices for the same ticker on the same date, we would use the
`aggregate_function` parameter of the `.pivot` method, e.g.:
`prices.pivot(..., aggregate_function="mean")`. Pivoting with an aggregate function gives us
similar behaviour to what Excel calls "pivot tables".

### Melt / Unpivot

Melt is the inverse of pivot. While pivot takes us from *long* data to *wide* data, melt goes
from wide to long.

Note: Polars has recently replaced its `melt` method with an `unpivot` method.

If we call `.unpivot(index="date", value_name="price")` on our pivoted dataframe we get our
original dataframe back:
"""

tabs """
pivoted.unpivot(index="date", value_name="price")
""":
  nbCode:
    nbShow pivoted.unpivot(index = "date", valueName = "price")

nbText: """
## Tidy NBA data

Suppose we want to calculate the days of rest each team had before each game. In the current
structure this is difficult because we need to track both the `home_team` and `away_team`
columns. We'll use `.unpivot` so that there's a single `team` column. This makes it easier to
add a `rest` column with the per-team rest days between games.
"""

tabs """
tidy_pl = (
    games_pl
    .unpivot(
        index=["game_id", "date"],
        on=["away_team", "home_team"],
        value_name="team",
    )
    .sort("game_id")
    .with_columns((
        pl.col("date")
        .alias("rest")
        .diff().over("team")
        .dt.total_days() - 1).cast(pl.Int8))
    .drop_nulls("rest")
    .collect()
)
tidy_pl
""":
  nbCode:
    let tidyPl = gamesPl
      .unpivot(
        index = ["game_id", "date"],
        on = ["away_team", "home_team"],
        valueName = "team")
      .sort("game_id")
      .withColumns((
        col.date
          .alias("rest")
          .diff.over("team")
          .dt.totalDays - 1).cast(int8))
      .dropNulls("rest")
      .collect
    nbShow tidyPl

nbText: """
Now we use `.pivot` so that this days-of-rest data can be added back to the original dataframe.
We'll also add columns for the spread between the home team's rest and away team's rest, and a
flag for whether the home team won.
"""

tabs """
by_game_pl = (
    tidy_pl
    .pivot(
        values="rest",
        index=["game_id", "date"],
        on="variable"
    )
    .rename({"away_team": "away_rest", "home_team": "home_rest"})
)
joined_pl = (
    by_game_pl
    .join(games_pl.collect(), on=["game_id", "date"])
    .with_columns([
        pl.col("home_points").alias("home_win") > pl.col("away_points"),
        pl.col("home_rest").alias("rest_spread") - pl.col("away_rest"),
    ])
)
joined_pl
""":
  nbCode:
    let byGamePl = tidyPl
      .pivot(
        values = "rest",
        index = ["game_id", "date"],
        on = "variable")
      .rename({"away_team": "away_rest", "home_team": "home_rest"})
    let joinedPl = byGamePl
      .join(gamesPl.collect, on = ["game_id", "date"])
      .withColumns(
        col.home_points.alias("home_win") > col.away_points,
        col.home_rest.alias("rest_spread") - col.away_rest)
    nbShow joinedPl

nbText: """
Here's a lightly edited quote from *Modern Pandas*:

> One somewhat subtle point: an "observation" depends on the question being asked. So really,
> we have two tidy datasets, `tidy` for answering team-level questions, and `joined` for
> answering game-level questions.

The book now plots each team's average days of rest, home and away, and the distribution of
`rest_spread`:
"""

tabs """
delta_pl = joined_pl["rest_spread"]
delta_pl.value_counts().drop_nulls().sort("rest_spread")
""":
  nbCode:
    nbShow joinedPl.valueCounts("rest_spread").dropNulls.sort("rest_spread")

nanuq """
The book draws this as a bar chart (with seaborn and matplotlib, which the port leaves out),
and then the home team's win rate for each `rest_spread` between -3 and 3. The port shows the
counts the first chart is made of.
"""

nbText: """
## Stack / Unstack vs Melt / Pivot

Pandas has special methods `stack` and `unstack` for reshaping data with a MultiIndex. Polars
doesn't have an index, so the equivalent Polars code will use `melt` / `pivot`.
"""

tabs """
rest_pl = (
    tidy_pl
    .group_by(["date", "variable"], maintain_order=True)
    .agg(pl.col("rest").mean())
)
rest_pl
""":
  nbCode:
    let restPl = tidyPl
      .groupBy("date", "variable")
      .agg(col.rest.mean)
    nbShow restPl

nbText: """
In Polars we use `.pivot` to do what in Pandas would require `.unstack`:
"""

tabs """
rest_pl.pivot(index="date", on="variable", values="rest")
""":
  nbCode:
    nbShow restPl.pivot(index = "date", on = "variable", values = "rest")

nbText: """
The moving average of rest days, which the book plots:
"""

tabs """
(
    rest_pl.pivot(index="date", values="rest", on="variable")
    .filter(pl.col("away_team") < 7)
    .sort("date")
    .select([pl.col("date"), pl.col(pl.Float64).rolling_mean(7)])
)
""":
  nbCode:
    nbShow restPl.pivot(index = "date", values = "rest", on = "variable")
      .filter(col.away_team < 7)
      .sort("date")
      .select(col.date, col(float).rollingMean(7))

nbText: """
## Mini Project: Home Court Advantage?

We may as well do some (not very rigorous) analysis: let's see if home advantage is a real
thing.

### Find the win percent for each team

We want to control for the strength of the teams playing. The team's victory percentage is
probably not a good control but it's what we'll use:
"""

tabs """
win_col = pl.col("win")
wins_pl = (
    joined_pl.unpivot(
        index=["game_id", "date", "home_win"],
        value_name="team",
        variable_name="is_home",
        on=["home_team", "away_team"],
    )
    .with_columns(pl.col("home_win").alias("win") == (pl.col("is_home") == "home_team"))
    .group_by(["team", "is_home"])
    .agg(
        [
            win_col.sum().alias("n_wins"),
            win_col.count().alias("n_games"),
            win_col.mean().alias("win_pct"),
        ]
    )
    .sort(["team", "is_home"])
)
wins_pl
""":
  nbCode:
    let winCol = col.win
    let winsPl = joinedPl.unpivot(
        index = ["game_id", "date", "home_win"],
        valueName = "team",
        variableName = "is_home",
        on = ["home_team", "away_team"])
      .withColumns(col.home_win.alias("win") == (col.is_home == "home_team"))
      .groupBy("team", "is_home")
      .agg(
        winCol.sum.alias("n_wins"),
        winCol.count.alias("n_games"),
        winCol.mean.alias("win_pct"))
      .sort(["team", "is_home"])
    nbShow winsPl

nbText: """
Now we calculate the win percent by team, regardless of whether they're home or away:
"""

tabs """
win_percent_pl = (
    wins_pl.group_by("team", maintain_order=True).agg(
        pl.col("n_wins").sum().alias("win_pct") / pl.col("n_games").sum()
    )
)
win_percent_pl
""":
  nbCode:
    let winPercentPl = winsPl.groupBy("team").agg(
      col.n_wins.sum.alias("win_pct") / col.n_games.sum)
    nbShow winPercentPl

nbText: """
The book plots these as bars, and then home court advantage against overall win percentage:
"""

tabs """
wins_to_plot_pl = (
    wins_pl.pivot(index="team", on="is_home", values="win_pct")
    .with_columns(
        [
            pl.col("home_team").alias("Home Win % - Away %") - pl.col("away_team"),
            (pl.col("home_team").alias("Overall %") + pl.col("away_team")) / 2,
        ]
    )
)
wins_to_plot_pl
""":
  nbCode:
    let winsToPlotPl = winsPl.pivot(index = "team", on = "is_home", values = "win_pct")
      .withColumns(
        col.home_team.alias("Home Win % - Away %") - col.away_team,
        (col.home_team.alias("Overall %") + col.away_team) / 2)
    nbShow winsToPlotPl

nbText: """
Let's add the win percent back to the dataframe and run a regression:
"""

tabs """
reg_df_pl = (
    joined_pl.join(win_percent_pl, left_on="home_team", right_on="team")
    .rename({"win_pct": "home_strength"})
    .join(win_percent_pl, left_on="away_team", right_on="team")
    .rename({"win_pct": "away_strength"})
    .with_columns(
        [
            pl.col("home_points").alias("point_diff") - pl.col("away_points"),
            pl.col("home_rest").alias("rest_diff") - pl.col("away_rest"),
            pl.col("home_win").cast(pl.UInt8),  # for statsmodels
        ]
    )
)
reg_df_pl.sort("game_id").head()
""":
  nbCode:
    let regDfPl = joinedPl.join(winPercentPl, leftOn = ["home_team"], rightOn = ["team"])
      .rename({"win_pct": "home_strength"})
      .join(winPercentPl, leftOn = ["away_team"], rightOn = ["team"])
      .rename({"win_pct": "away_strength"})
      .withColumns(
        col.home_points.alias("point_diff") - col.away_points,
        col.home_rest.alias("rest_diff") - col.away_rest,
        col.home_win.cast(uint8))  # for statsmodels
    nbShow regDfPl.sort("game_id").head

nanuq """
The book fits a logit model with statsmodels
(`home_win ~ home_strength + away_strength + home_rest + away_rest`) on this frame; that step is
Python's, so the port stops at the frame. Both tabs sort by `game_id` before `head`: a join does
not keep any row order unless asked to, so the first five rows would differ.
"""

nbText: """
## Summary

This was mostly a demonstration of `.pivot` and `.melt`, with several different examples of
reshaping data in Polars.
"""

bookSave()
