import nanuqbook
bookInit()

nbText: "# Debugging chained operations"

attribution polarsCookbook(12, "Testing and Debugging in Polars",
  "Two recipes of the chapter: debugging chained operations, and inspecting the query " &
  "plan. Data is read from `data/polars-cookbook/`. Left out: `show_graph`, " &
  "`explain(optimized=False)` and the testing recipes with pytest and cuallee.")

nbText: """
A long chain of methods reads well, but when it fails, which step was it? This recipe
takes a lazy query on a table of Pokémon apart, step by step.
"""

tabs """
import polars as pl

lf = pl.scan_csv('data/polars-cookbook/pokemon.csv')
""":
  nbCode:
    import nanuq

    let lf = scanCsv("data/polars-cookbook/pokemon.csv")

nbText: """
The query ranks the Pokémon on three of their stats, keeps a few columns and shows the
five with the lowest total. `rank` with the `Dense` method gives tied values the same rank
and leaves no gaps.
"""

tabs """
(
    lf
    .with_columns(
        pl.col('Attack').rank(method='dense').alias('Atk Rank'),
        pl.col('Defense').rank(method='dense').alias('Def Rank'),
        pl.col('Speed').rank(method='dense').alias('Spe Rank'),
    )
    .select(
        'Name',
        'Total',
        'Attack',
        'Defense',
        'Speed',
        pl.col('^*Rank$')
    )
    .sort('Total')
    .head()
    .collect()
)
""":
  nbCode:
    nbShow lf
      .withColumns(
        col.Attack.rank(Dense).alias("Atk Rank"),
        col.Defense.rank(Dense).alias("Def Rank"),
        col.Speed.rank(Dense).alias("Spe Rank"))
      .select(col("Name", "Total", "Attack", "Defense", "Speed"), col("^*Rank$"))
      .sort("Total")
      .head()
      .collect

nanuq """
`rank` is new in Nanuq 0.3. Its method is the enum `RankMethod` (`Average`, the default,
`Min`, `Max`, `Dense`, `Ordinal`, `Random`), passed by position since Python's argument
name, `method`, is a Nim keyword.
"""

nbText: """
Now with a typo, `Deffense`. In a lazy query, the error comes when the plan is resolved,
at `collect`, not at the line with the typo:
"""

tabs """
try:
    (
        lf
        .with_columns(
            pl.col('Attack').rank(method='dense').alias('Atk Rank'),
            pl.col('Defense').rank(method='dense').alias('Def Rank'),
            pl.col('Speed').rank(method='dense').alias('Spe Rank'),
        )
        .select(
            'Name',
            'Total',
            'Attack',
            'Deffense',
            'Speed',
            pl.col('^*Rank$')
        )
        .sort('Total')
        .head()
        .collect()
    )
except pl.exceptions.ColumnNotFoundError as e:
    print(type(e).__name__)
""":
  nbCode:
    try:
      discard lf
        .withColumns(
          col.Attack.rank(Dense).alias("Atk Rank"),
          col.Defense.rank(Dense).alias("Def Rank"),
          col.Speed.rank(Dense).alias("Spe Rank"))
        .select(col("Name", "Total", "Attack", "Deffense", "Speed"), col("^*Rank$"))
        .sort("Total")
        .head()
        .collect
    except ColumnNotFoundError:
      echo "ColumnNotFoundError"

nbText: """
The recipe's way to find the culprit: comment out steps until the query runs. Without the
`select`, it does:
"""

tabs """
(
    lf
    .with_columns(
        pl.col('Attack').rank(method='dense').alias('Atk Rank'),
        pl.col('Defense').rank(method='dense').alias('Def Rank'),
        pl.col('Speed').rank(method='dense').alias('Spe Rank'),
    )
    # .select(
    #     'Name',
    #     'Total',
    #     'Attack',
    #     'Deffense',
    #     'Speed',
    #     pl.col('^*Rank$')
    # )
    .sort('Total')
    .head()
    .collect()
)
""":
  nbCode:
    nbShow lf
      .withColumns(
        col.Attack.rank(Dense).alias("Atk Rank"),
        col.Defense.rank(Dense).alias("Def Rank"),
        col.Speed.rank(Dense).alias("Spe Rank"))
      # .select(col("Name", "Total", "Attack", "Deffense", "Speed"), col("^*Rank$"))
      .sort("Total")
      .head()
      .collect

nanuq """
The recipe also collects first and runs the chain eagerly, so that the error points at its
step. Nanuq's eager methods run a lazy query each, so that gives the same error.
"""

nbText: """
Another way to keep a chain readable: give the steps names. Python does it with functions
and `pipe`; in Nim a proc that takes a LazyFrame is called with the same dot syntax as a
method, so no `pipe` is needed.
"""

tabs """
def add_ranks(lf: pl.LazyFrame) -> pl.LazyFrame:
    return (
        lf
        .with_columns(
            pl.col('Attack').rank(method='dense').alias('Atk Rank'),
            pl.col('Defense').rank(method='dense').alias('Def Rank'),
            pl.col('Speed').rank(method='dense').alias('Spe Rank'),
        )
    )

def keep_cols(lf: pl.LazyFrame) -> pl.LazyFrame:
    return (
        lf
        .select(
            'Name',
            'Total',
            'Attack',
            'Defense',
            'Speed',
            pl.col('^*Rank$')
        )
    )

(
    lf
    .pipe(add_ranks)
    .pipe(keep_cols)
    .sort('Total')
    .head()
    .collect()
)
""":
  nbCode:
    proc addRanks(lf: LazyFrame): LazyFrame =
      lf.withColumns(
        col.Attack.rank(Dense).alias("Atk Rank"),
        col.Defense.rank(Dense).alias("Def Rank"),
        col.Speed.rank(Dense).alias("Spe Rank"))

    proc keepCols(lf: LazyFrame): LazyFrame =
      lf.select(col("Name", "Total", "Attack", "Defense", "Speed"), col("^*Rank$"))

    nbShow lf.addRanks.keepCols.sort("Total").head().collect

nbText: """
## Inspecting and optimizing the query plan

One more step, a filter on the Pokémon's types:
"""

tabs """
def keep_grass_or_fire(lf):
    accepted_types = ['Grass', 'Fire']
    return (
        lf
        .filter(
            (pl.col('Type 1').is_in(accepted_types))
            | (pl.col('Type 2').is_in(accepted_types))
        )
    )
""":
  nbCode:
    proc keepGrassOrFire(lf: LazyFrame): LazyFrame =
      let acceptedTypes = ["Grass", "Fire"]
      lf.filter(col("Type 1").isIn(acceptedTypes) or col("Type 2").isIn(acceptedTypes))

nbText: """
`explain` prints the plan Polars will run, after optimization. Read it from the bottom up:
the CSV scan reads only the columns the query needs, and the filter sits right above it.
"""

tabs """
print(
    lf
    .pipe(add_ranks)
    .pipe(keep_grass_or_fire)
    .pipe(keep_cols)
    .explain()
)
""":
  nbCode:
    echo lf.addRanks.keepGrassOrFire.keepCols.explain

nbText: """
The order of the steps matters. The ranks are computed before the filter here, on all the
Pokémon. Filtering first, the ranks are computed among grass and fire types only: a
different query, with a different plan.
"""

tabs """
print(
    lf
    .pipe(keep_grass_or_fire)
    .pipe(keep_cols)
    .pipe(add_ranks)
    .explain()
)
""":
  nbCode:
    echo lf.keepGrassOrFire.keepCols.addRanks.explain

nanuq """
Wait: `keep_cols` before `add_ranks` selects the rank columns before they exist. The regex
`^*Rank$` matches no column at that point, so it selects nothing, and the query still runs.
Nanuq's `explain` has no `optimized = false` yet, and no `show_graph`.
"""

bookSave()
