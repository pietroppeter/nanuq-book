import nanuqbook
bookInit()

nbText: "# Getting started"

attribution polarsCookbook(1, "Getting Started with Python Polars",
  "Data is read from `data/polars-cookbook/`. Left out: `from_numpy`, " &
  "`flags`, `show_graph` (it draws the query plan with Graphviz), and the recipe on " &
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

A Series is one named column: one dimension, one data type. You can build one directly:
"""

nanuq """
Nanuq shows a Series as a one-column frame (`toFrame`), so the Python side does too
(`to_frame`).
"""

tabs """
s = pl.Series('col', [1,2,3,4,5])
s.head().to_frame()
""":
  nbCode:
    let s = series("col", [1, 2, 3, 4, 5])
    nbShow s.head.toFrame

nbText: """
or take one out of a frame: `to_series` takes a column by position (the first by
default), `get_column` by name.
"""

tabs """
data = {'a': [1,2,3], 'b': [4,5,6]}
s_a = (
    pl.DataFrame(data)
    .to_series()
)
s_a.head().to_frame()
""":
  nbCode:
    let data = newDataFrame:
      a: [1, 2, 3]
      b: [4, 5, 6]
    let sA = data.toSeries()
    nbShow sA.head.toFrame

tabs """
s_b = (
    pl.DataFrame(data)
    .to_series(1)
)
s_b.head().to_frame()
""":
  nbCode:
    let sB = data.toSeries(1)
    nbShow sB.head.toFrame

nanuq """
`data.getColumn("b")` can also be written `data["b"]`, as in Python.
"""

tabs """
s_b2 = (
    pl.DataFrame(data)
    .get_column('b')
)
s_b2.head().to_frame()
""":
  nbCode:
    let sB2 = data.getColumn("b")
    nbShow sB2.head.toFrame

nbText: """
A Series knows its length, its name and its data type:
"""

nanuq """
A Series has one dimension, so where Python's `shape` is the tuple `(5,)`, Nanuq has
`len`.
"""

tabs """
print(s.shape)
print(s.name)
print(s.dtype)
""":
  nbCode:
    echo s.len
    echo s.name
    echo s.dtype

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
    nbShow df.select(col(["Survived", "Ticket", "Fare"])).head()

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

tabs """
df.with_columns(pl.col('Sex').str.to_titlecase()).head()
""":
  nbCode:
    nbShow df.withColumns(col.Sex.str.toTitlecase).head()

nanuq """
`toTitlecase` is new in Nanuq 0.3, and needs Polars' `nightly` feature: the release
libraries have it, while a library built from source with stable Rust raises an
`InvalidOperationError`.
"""

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
    nbShow df.select(col(["PassengerId", "Survived", "Sex", "Age", "Fare"])).head()

nbText: """
Several new columns in one `withColumns` are computed in parallel; a chain of
`withColumns` runs them one after the other. Both give the same table:
"""

tabs """
best_practice = (
    df.with_columns(
        pl.col('Fare').max().alias('Max Fare'),
        pl.lit('Titanic'),
        pl.col('Sex').str.to_titlecase()
    )
)
best_practice.head()
""":
  nbCode:
    let bestPractice = df.withColumns(
      col.Fare.max.alias("Max Fare"),
      lit("Titanic"),
      col.Sex.str.toTitlecase)
    nbShow bestPractice.head()

tabs """
not_so_good_practice = (
    df
    .with_columns(pl.col('Fare').max().alias('Max Fare'))
    .with_columns(pl.lit('Titanic'))
    .with_columns(pl.col('Sex').str.to_titlecase())
)
not_so_good_practice.head()
""":
  nbCode:
    let notSoGoodPractice = df
      .withColumns(col.Fare.max.alias("Max Fare"))
      .withColumns(lit("Titanic"))
      .withColumns(col.Sex.str.toTitlecase)
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
    let cols = ["Name", "Sex", "Age", "Fare", "Cabin", "Pclass", "Survived"]

    var steps = df.select(col(cols))
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
      .select(col(cols))
      .filter(col.Age >= 35)
      .sort(["Age", "Name"])
    nbShow chained.head()

nanuq """
Nim's `select` takes expressions, so the list of names goes through `col`, which takes an
array (or a `seq`) of names since Nanuq 0.3.
"""

nanuq """
Nim's method call syntax chains without the parentheses Python needs: a line that starts
with `.` continues the expression above it.
"""

bookSave()
