import nanuqbook
bookInit()

nbText: "# Getting started"

attribution polarsCookbook(1, "Getting Started with Python Polars",
  "Data is read from `data/polars-cookbook/`. `str.to_titlecase` is `str.to_uppercase` " &
  "here. Left out: `from_numpy`, most of the Series " &
  "recipe, `flags`, `show_graph` (it draws the query plan with Graphviz), and the recipe on " &
  "data larger than memory, which needs a Chicago taxi trips file that the book does not ship.")

nbText: """
The first chapter of the cookbook introduces the three building blocks of Polars,
DataFrame, Series and LazyFrame, then the everyday moves: selecting, filtering, adding
columns and chaining it all together. Most of it is on the Titanic passenger list.

## The Polars DataFrame

A DataFrame is a table of named columns, each with one data type. You can build one from
literal data:
"""

tabs """
import polars as pl

df = pl.DataFrame({
    'nums': [1,2,3,4,5],
    'letters': ['a','b','c','d','e']
})
df.head()
""":
  nbCode:
    import nanuq

    var df = newDataFrame:
      nums: [1, 2, 3, 4, 5]
      letters: ["a", "b", "c", "d", "e"]
    nbShow df.head()

nbText: "Or read it from a file:"

tabs """
df = pl.read_csv('data/polars-cookbook/titanic_dataset.csv')
df.head()
""":
  nbCode:
    df = readCsv("data/polars-cookbook/titanic_dataset.csv")
    nbShow df.head()

nbText: "A frame knows its schema, its column names and types, and its shape:"

tabs """
df.schema
""":
  nbCode:
    echo df.schema

tabs """
df.columns
""":
  nbCode:
    echo df.columns

tabs """
df.dtypes
""":
  nbCode:
    echo df.dtypes

tabs """
df.shape
""":
  nbCode:
    echo df.shape

tabs """
df.height
""":
  nbCode:
    echo df.height

tabs """
df.width
""":
  nbCode:
    echo df.width

nanuq """
The recipe also shows `df.flags` (which columns Polars knows to be sorted) and
`pl.from_numpy`. Nanuq has neither: in Nim you build a frame from sequences.
"""

nbText: """
## The Polars Series

A Series is one named column. Nanuq builds them with `series` and puts them together into
frames, but it has no Series methods yet, so this recipe is left out except for the
constructor:
"""

tabs """
s = pl.Series('col', [1,2,3,4,5])
s.head().to_frame()
""":
  nbCode:
    let s = series("col", [1, 2, 3, 4, 5])
    nbShow newDataFrame(s).head()

nanuq """
Nanuq shows the Series as a one-column frame, so the Python side does too (`to_frame`). It has no `to_series` and `get_column`
returning a Series yet; to get a column's values out, use `toList`
(`df.toList("Age", Option[float])`).
"""

nbText: """
## The Polars LazyFrame

A LazyFrame is a query plan: nothing is computed until you `collect` it, which lets Polars
optimize the whole query first.
"""

tabs """
data = {'name': ['Sarah',  'Mike', 'Bob', 'Ashley']}
lf = pl.LazyFrame(data)
lf.collect().head()
""":
  nbCode:
    let names = newDataFrame:
      name: ["Sarah", "Mike", "Bob", "Ashley"]
    nbShow names.lazy.collect.head()

nanuq """
Nanuq has no `LazyFrame` constructor from data: you build a DataFrame and call `lazy` on
it.
"""

nbText: "`scanCsv` reads a file lazily:"

tabs """
lf = pl.scan_csv('data/polars-cookbook/titanic_dataset.csv')
lf.head().collect()
""":
  nbCode:
    let lf = scanCsv("data/polars-cookbook/titanic_dataset.csv")
    nbShow lf.head().collect

tabs """
df.lazy().head(3).collect()
""":
  nbCode:
    nbShow df.lazy.head(3).collect

nbText: "A LazyFrame can tell its schema without reading the data:"

tabs """
lf.collect_schema()
""":
  nbCode:
    echo lf.collectSchema

tabs """
lf.collect_schema().len()
""":
  nbCode:
    echo lf.collectSchema.len

nbText: """
`explain` shows the plan Polars will run. Only the two selected columns are read from the
file, as the projection `2/12 COLUMNS` shows.
"""

tabs """
print(
    lf
    .select(pl.col('Name', 'Age'))
    .explain()
    , sep='\n'
)
""":
  nbCode:
    echo lf.select(col("Name", "Age")).explain

nanuq """
The recipe also draws the plan with `show_graph`, which needs Graphviz. Nanuq has no
`show_graph`.
"""

nbText: """
## Selecting columns and filtering data

`select` picks columns, by name or by expression:
"""

tabs """
df.select(pl.col(['Survived', 'Ticket', 'Fare'])).head()
""":
  nbCode:
    nbShow df.select(col("Survived", "Ticket", "Fare")).head()

tabs """
df.select(
    pl.col('Survived'),
    pl.col('Ticket'),
    pl.col('Fare')
).head()
""":
  nbCode:
    nbShow df.select(col.Survived, col.Ticket, col.Fare).head()

nbText: """
`withColumns` keeps all the columns and adds (or replaces) the ones you give, so with
existing columns it changes nothing:
"""

tabs """
df.with_columns(
    pl.col('Survived'),
    pl.col('Ticket'),
    pl.col('Fare')
).head()
""":
  nbCode:
    nbShow df.withColumns(col.Survived, col.Ticket, col.Fare).head()

nanuq """
Python's `select` and `with_columns` also take bare column names (`df.select(['Survived',
'Ticket', 'Fare'])`); Nim's take expressions, so names go through `col`.
"""

nbText: "`filter` keeps the rows where a condition holds:"

tabs """
df.filter((pl.col('Age') >= 30)).head()
""":
  nbCode:
    nbShow df.filter(col.Age >= 30).head()

tabs """
df.filter(
    (pl.col('Age') >= 30) & (pl.col('Sex')=='male')
).head()
""":
  nbCode:
    nbShow df.filter(col.Age >= 30 and col.Sex == "male").head()

nbText: """
Columns can also be picked by a regular expression on their names, or by type:
"""

tabs """
df.select(pl.col('^[a-zA-Z]{0,4}$')).head()
""":
  nbCode:
    nbShow df.select(col("^[a-zA-Z]{0,4}$")).head()

tabs """
df.select(pl.col(pl.String)).head()
""":
  nbCode:
    nbShow df.select(col(string)).head()

tabs """
import polars.selectors as cs

df.select(cs.numeric()).head()
""":
  nbCode:
    nbShow df.select(col(SomeNumber)).head()

tabs """
df.select(cs.matches('se|ed')).head()
""":
  nbCode:
    nbShow df.select(col("^.*(se|ed).*$")).head()

nanuq """
Nanuq has no `polars.selectors` module: Polars' selectors are `col` with a Nim type or
typeclass (`col(SomeNumber)` for `cs.numeric()`) or a regular expression. `cs.matches`
looks for the pattern anywhere in the name; `col` takes a whole-name regex between `^` and
`$`. Python's `df[['Age', 'Sex']]` indexing is `select` in Nim.
"""

nbText: """
## Creating, modifying, and deleting columns

An aggregation in `withColumns` is broadcast to every row:
"""

tabs """
df.with_columns(
    pl.col('Fare').max().alias('Max Fare')
).head()
""":
  nbCode:
    nbShow df.withColumns(col.Fare.max.alias("Max Fare")).head()

tabs """
df.with_columns(
    (pl.col('Fare').max() - pl.col('Fare').mean()).alias('Max Fare - Avg Fare')
).head()
""":
  nbCode:
    nbShow df.withColumns((col.Fare.max - col.Fare.mean).alias("Max Fare - Avg Fare")).head()

nbText: "A literal gets the name `literal`, unless you alias it:"

tabs """
df.with_columns(pl.lit('Titanic')).head()
""":
  nbCode:
    nbShow df.withColumns(lit("Titanic")).head()

tabs """
df.with_row_index().head()
""":
  nbCode:
    nbShow df.withRowIndex().head()

nbText: "An expression on an existing column replaces it:"

nanuq """
The recipe title-cases the `Sex` column with `str.to_titlecase()`. Nanuq does not have
`toTitlecase` yet (Rust Polars has it behind its `nightly` feature), so this page
upper-cases instead, with `str.to_uppercase()` on the Python side too.
"""

tabs """
df.with_columns(pl.col('Sex').str.to_uppercase()).head()
""":
  nbCode:
    nbShow df.withColumns(col.Sex.str.toUppercase).head()

tabs """
df.with_columns(
    pl.col('Fare').max()
).head()
""":
  nbCode:
    nbShow df.withColumns(col.Fare.max).head()

nbText: "To delete columns, `drop` them, or `select` the ones to keep:"

tabs """
df.drop(['Pclass', 'Name', 'SibSp', 'Parch', 'Ticket', 'Cabin', 'Embarked']).head()
""":
  nbCode:
    nbShow df.drop(["Pclass", "Name", "SibSp", "Parch", "Ticket", "Cabin", "Embarked"]).head()

tabs """
df.select(['PassengerId', 'Survived', 'Sex', 'Age', 'Fare']).head()
""":
  nbCode:
    nbShow df.select(col("PassengerId", "Survived", "Sex", "Age", "Fare")).head()

nbText: """
Several new columns in one `withColumns` are computed in parallel; a chain of
`withColumns` runs them one after the other. Both give the same table:
"""

tabs """
best_practice = (
    df.with_columns(
        pl.col('Fare').max().alias('Max Fare'),
        pl.lit('Titanic'),
        pl.col('Sex').str.to_uppercase()
    )
)
best_practice.head()
""":
  nbCode:
    let bestPractice = df.withColumns(
      col.Fare.max.alias("Max Fare"),
      lit("Titanic"),
      col.Sex.str.toUppercase)
    nbShow bestPractice.head()

tabs """
not_so_good_practice = (
    df
    .with_columns(pl.col('Fare').max().alias('Max Fare'))
    .with_columns(pl.lit('Titanic'))
    .with_columns(pl.col('Sex').str.to_uppercase())
)
not_so_good_practice.head()
""":
  nbCode:
    let notSoGoodPractice = df
      .withColumns(col.Fare.max.alias("Max Fare"))
      .withColumns(lit("Titanic"))
      .withColumns(col.Sex.str.toUppercase)
    nbShow notSoGoodPractice.head()

nbText: """
## Method chaining

Each method returns a new frame, so the steps of an analysis can be written one per line
or chained into a single expression.
"""

tabs """
cols = ['Name', 'Sex', 'Age', 'Fare', 'Cabin', 'Pclass', 'Survived']

df = df.select(cols)
df = df.filter(pl.col('Age')>=35)
df = df.sort(by=['Age', 'Name'])
df.head()
""":
  nbCode:
    let cols = col("Name", "Sex", "Age", "Fare", "Cabin", "Pclass", "Survived")

    var steps = df.select(cols)
    steps = steps.filter(col.Age >= 35)
    steps = steps.sort(["Age", "Name"])
    nbShow steps.head()

tabs """
df = pl.read_csv('data/polars-cookbook/titanic_dataset.csv')
df = (
    df
    .select(cols)
    .filter(pl.col('Age')>=35)
    .sort(by=['Age', 'Name'])
)
df.head()
""":
  nbCode:
    let chained = df
      .select(cols)
      .filter(col.Age >= 35)
      .sort(["Age", "Name"])
    nbShow chained.head()

nanuq """
In Nim, `cols` is a selector, `col` with several names, rather than a list of names: `col`
does not take an array yet.
"""

nanuq """
Nim's method call syntax chains without the parentheses Python needs: a line that starts
with `.` continues the expression above it.
"""

bookSave()
