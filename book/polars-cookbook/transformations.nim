import nanuqbook
bookInit()

nbText: "# Data transformation techniques"

attribution polarsCookbook(4, "Data Transformation Techniques",
  "Data is read from `data/polars-cookbook/`. Group-bys followed by `head` keep their " &
  "order (`maintain_order=True`) on both sides, so the two tabs show the same groups. " &
  "Left out: setting the string length through `os.environ`.")

nbText: """
This chapter of the cookbook is about aggregating: over a whole column, per group, across
columns, and over a window. Most of it uses Contoso, a made-up retail chain whose sales
SQLBI generates for Power BI demos, and the last part the Pokémon table.

## Simple aggregations

### How to do it...
"""

tabs """
import polars as pl

df = pl.read_csv('data/polars-cookbook/contoso_sales.csv', try_parse_dates=True)
df.head()
""":
  nbCode:
    import nanuq

    var df = readCsv("data/polars-cookbook/contoso_sales.csv", tryParseDates = true)
    nbShow df.head()

nbText: """
Summing all the numeric columns at once, with a selector:
"""

tabs """
from polars import selectors as cs
(
    df
    .select(cs.numeric())
    .sum()
)
""":
  nbCode:
    nbShow df.select(col(SomeNumber)).sum()

nanuq """
`col(SomeNumber)` is Nanuq's `cs.numeric()`.
"""

nbText: """
One column, as a Series or in an expression:
"""

tabs """
s = df.select('Quantity').to_series()
s.sum()
""":
  nbCode:
    let s = df.select("Quantity").toSeries
    echo s.sum.item(int)

tabs """
df.select(pl.col('Quantity').sum())
""":
  nbCode:
    nbShow df.select(col.Quantity.sum)

tabs """
df.select(
    pl.col('Customer Name').first().alias('Cust Name First'),
    pl.col('Customer Name').last().alias('Cust Name Last')
)
""":
  nbCode:
    nbShow df.select(
      col("Customer Name").first.alias("Cust Name First"),
      col("Customer Name").last.alias("Cust Name Last"))

tabs """
df.select(cs.numeric()).describe()
""":
  nbCode:
    nbShow df.select(col(SomeNumber)).describe()

nbText: """
### There is more...

A condition summed counts the rows where it holds, and `filter` inside an expression
aggregates only some rows:
"""

tabs """
df.select(
    (pl.col('Quantity') >= 4).sum()
)
""":
  nbCode:
    nbShow df.select((col.Quantity >= 4).sum)

tabs """
df.select(
    pl.col('Quantity').filter(pl.col('Store Name')=='Online store').sum()
)
""":
  nbCode:
    nbShow df.select(col.Quantity.filter(col("Store Name") == "Online store").sum)

nbText: """
## Using group by aggregations

### How to do it...

`agg` takes one or more expressions, evaluated per group:
"""

tabs """
(
    df
    .group_by('Brand', maintain_order=True)
    .agg(pl.col('Quantity').sum().alias('Sum of Quantity'))
    .head()
)
""":
  nbCode:
    nbShow df
      .groupBy("Brand", maintainOrder = true)
      .agg(col.Quantity.sum.alias("Sum of Quantity"))
      .head()

tabs """
(
    df
    .group_by('Brand')
    .agg(
        pl.col('Unit Price').sum().alias('Sum of Quantity'),
        pl.col('Unit Price').mean().alias('Average Unit Price'),
    )
    .sort('Average Unit Price', descending=True)
    .head()
)
""":
  nbCode:
    nbShow df
      .groupBy("Brand")
      .agg(
        col("Unit Price").sum.alias("Sum of Quantity"),
        col("Unit Price").mean.alias("Average Unit Price"))
      .sort("Average Unit Price", descending = true)
      .head()

nbText: """
Two ways to the same mean, plus the first and last values of other columns. The last
`sort` decides the order:
"""

tabs """
(
    df
    .group_by('Brand')
    .agg(
        pl.col('Unit Price').mean().round(2).alias('Average Unit Price'),
        (pl.col('Unit Price').sum() / pl.len()).round(2).alias('Average Unit Price 2'),
        pl.col('Customer Name').first(),
        pl.col('Category').last()
    )
    .sort('Average Unit Price', descending=True)
    .sort('Brand')
    .head()
)
""":
  nbCode:
    nbShow df
      .groupBy("Brand")
      .agg(
        col("Unit Price").mean.round(2).alias("Average Unit Price"),
        (col("Unit Price").sum / len()).round(2).alias("Average Unit Price 2"),
        col("Customer Name").first,
        col.Category.last)
      .sort("Average Unit Price", descending = true)
      .sort("Brand")
      .head()

nbText: """
The same query on a LazyFrame, from `scan_csv`:
"""

tabs """
(
    pl.scan_csv('data/polars-cookbook/contoso_sales.csv', try_parse_dates=True)
    .group_by('Brand')
    .agg(
        pl.col('Unit Price').mean().round(2).alias('Average Unit Price'),
        (pl.col('Unit Price').sum() / pl.len()).round(2).alias('Average Unit Price 2'),
        pl.col('Customer Name').first(),
        pl.col('Category').last()
    )
    .sort('Average Unit Price', descending=True)
    .sort('Brand')
    .collect()
    .head()
)
""":
  nbCode:
    nbShow scanCsv("data/polars-cookbook/contoso_sales.csv", tryParseDates = true)
      .groupBy("Brand")
      .agg(
        col("Unit Price").mean.round(2).alias("Average Unit Price"),
        (col("Unit Price").sum / len()).round(2).alias("Average Unit Price 2"),
        col("Customer Name").first,
        col.Category.last)
      .sort("Average Unit Price", descending = true)
      .sort("Brand")
      .collect
      .head()

nbText: """
Long brand names are cut in the printed table; a wider string limit shows them whole:
"""

tabs """
with pl.Config(fmt_str_lengths=50):
    print(df.select('Brand').unique(maintain_order=True).head(10))
""":
  nbCode:
    withConfig(fmtStrLengths = 50):
      echo df.select("Brand").unique(maintainOrder = true).head(10)

nanuq """
The book sets `pl.Config.set_fmt_str_lengths = 50`, which replaces the method instead of
calling it, and then the environment variable `POLARS_FMT_STR_LEN`. Both tabs use the
scoped config instead (`withConfig` in Nim), and keep the order of `unique`.
"""

nbText: """
### There is more...

A group-by can be iterated: one frame per group.
"""

tabs """
for name, data in df.group_by(['Brand'], maintain_order=True):
    print(name[0], type(data))
""":
  nbCode:
    for name, data in df.groupBy("Brand"):
      echo name[0], " ", $typeof(data)

nanuq """
The key of each group is a `seq[string]`, one value per grouping column, like Python's
tuple.
"""

nbText: """
A column without an aggregation becomes a list per group. `maintain_order=True` keeps the
groups in the order they first appear:
"""

tabs """
(
    df
    .group_by('Brand', maintain_order=True)
    .agg(pl.col('Quantity'))
    .head()
)
""":
  nbCode:
    nbShow df
      .groupBy("Brand", maintainOrder = true)
      .agg(col.Quantity)
      .head()

nbText: """
Grouping keys can be expressions too, here the year of the order date:
"""

tabs """
(
    df
    .group_by(
        pl.col('Brand'),
        'Customer Country',
        pl.col('Order Date').dt.year().alias('Order Year'),
        maintain_order=True,
        )
    .agg(pl.col('Unit Price').mean())
    .head()
)
""":
  nbCode:
    nbShow df
      .groupBy(
        [col.Brand,
         col("Customer Country"),
         col("Order Date").dt.year.alias("Order Year")],
        maintainOrder = true)
      .agg(col("Unit Price").mean)
      .head()

nbText: """
## Aggregating values across multiple columns

### How to do it...

The Pokémon table has six stats per Pokémon; their total is a row-wise sum.
"""

tabs """
df = pl.read_csv('data/polars-cookbook/pokemon.csv')
df.head()
""":
  nbCode:
    df = readCsv("data/polars-cookbook/pokemon.csv")
    nbShow df.head()

tabs """
(
    df
    .with_columns(
        pl.sum_horizontal('HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed').alias('Total 2')
    )
    .head()
)
""":
  nbCode:
    nbShow df
      .withColumns(
        sumHorizontal(col("HP", "Attack", "Defense", "Sp. Atk", "Sp. Def", "Speed")).alias("Total 2"))
      .head()

nanuq """
The book starts with `df.select(…).sum_horizontal()`, a frame-level row sum that gives a
Series; Nanuq has the expression only.
"""

tabs """
(
    df
    .with_columns(
        pl.concat_list('HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed').list.sum().alias('Total 2')
    )
    .head()
)
""":
  nbCode:
    nbShow df
      .withColumns(
        concatList(col("HP", "Attack", "Defense", "Sp. Atk", "Sp. Def", "Speed")).list.sum.alias("Total 2"))
      .head()

nbText: """
`reduce` and `fold` take a function of two Series. `fold` starts from a given value (here
100), `reduce` from the first column:
"""

tabs """
cols = ['HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed']
(
    df
    .with_columns(
        pl.reduce(
            function=lambda acc, col: acc + col,
            exprs=pl.col(cols)
        )
        .alias('Total 2')
    )
    .head()
)
""":
  nbCode:
    let cols = ["HP", "Attack", "Defense", "Sp. Atk", "Sp. Def", "Speed"]
    nbShow df
      .withColumns(
        reduce(
          f = proc (acc, x: Series): Series = acc + x,
          exprs = col(cols))
        .alias("Total 2"))
      .head()

tabs """
(
    df
    .with_columns(
        pl.fold(
            acc=pl.lit(100),
            function=lambda acc, col: acc + col,
            exprs=pl.col(cols)
        )
        .alias('Total 2')
    )
    .head()
)
""":
  nbCode:
    nbShow df
      .withColumns(
        fold(
          acc = lit(100),
          f = proc (acc, x: Series): Series = acc + x,
          exprs = col(cols))
        .alias("Total 2"))
      .head()

nbText: """
### There is more...

A fold with *and* keeps the Pokémon whose stats are all above 80; `all_horizontal` says
the same in one call:
"""

tabs """
(
    df
    .filter(
        pl.fold(
            acc=pl.lit(True),
            function=lambda acc, col: acc & col,
            exprs=pl.col(cols) > 80
        )
    )
    .head()
)
""":
  nbCode:
    nbShow df
      .filter(
        fold(
          acc = lit(true),
          f = proc (acc, x: Series): Series = acc and x,
          exprs = col(cols) > 80))
      .head()

tabs """
(
    df
    .filter(
        pl.all_horizontal(pl.col(cols) > 80)
    )
    .head()
)
""":
  nbCode:
    nbShow df
      .filter(allHorizontal(col(cols) > 80))
      .head()

nbText: """
Folding strings concatenates them. Since `Type 2` is sometimes empty (null), so is the
result in those rows; `concat_str` does the same:
"""

tabs """
str_cols = ['Name', 'Type 1', 'Type 2']
str_combined = pl.fold(acc=pl.lit(''), function=lambda acc, col: acc + col, exprs=str_cols).alias('Str Combined')
str_cols.append(str_combined)
df.select(str_cols).head()
""":
  nbCode:
    block:
      let strCombined = fold(
        acc = lit(""),
        f = proc (acc, x: Series): Series = acc + x,
        exprs = col("Name", "Type 1", "Type 2")).alias("Str Combined")
      nbShow df.select(col("Name", "Type 1", "Type 2"), strCombined).head()

tabs """
str_cols = ['Name', 'Type 1', 'Type 2']
df.select(pl.concat_str(str_cols)).head()
""":
  nbCode:
    nbShow df.select(concatStr([col.Name, col("Type 1"), col("Type 2")])).head()

nbText: """
## Computing over groups with window functions

### How to do it...

Back to the sales, with a sales amount per line:
"""

tabs """
df = pl.read_csv('data/polars-cookbook/contoso_sales.csv', try_parse_dates=True)
df = df.with_columns(
    (pl.col('Quantity') * pl.col('Net Price')).round(2).alias('Sales Amount')
)
df.head()
""":
  nbCode:
    df = readCsv("data/polars-cookbook/contoso_sales.csv", tryParseDates = true)
    df = df.withColumns(
      (col.Quantity * col("Net Price")).round(2).alias("Sales Amount"))
    nbShow df.head()

nbText: """
`over` computes an aggregation per group but keeps one value per row, so the result has as
many rows as the frame:
"""

tabs """
sales_by_cat = df.select(
    'Category',
    'Subcategory',
    pl.col('Sales Amount').sum().over('Category').alias('Sales Amt per Cat')
)
sales_by_cat.head()
""":
  nbCode:
    let salesByCat = df.select(
      col.Category,
      col.Subcategory,
      col("Sales Amount").sum.over("Category").alias("Sales Amt per Cat"))
    nbShow salesByCat.head()

tabs """
sales_by_cat.filter(pl.col('Category')=='Audio').unique(maintain_order=True).head()
""":
  nbCode:
    nbShow salesByCat.filter(col.Category == "Audio").unique(maintainOrder = true).head()

tabs """
df.shape, sales_by_cat.shape
""":
  nbCode:
    echo (df.shape, salesByCat.shape)

nbText: """
Windows over two columns:
"""

tabs """
(
    df
    .select(
        'Category',
        'Brand',
        'Subcategory',
        pl.col('Sales Amount').mean().over('Category', 'Brand').alias('Avg Sales per Cat and Brand')
    )
    .filter(
        (pl.col('Category')=='Computers')
    )
    .unique()
    .sort('Brand', 'Subcategory')
    .head(10)
)
""":
  nbCode:
    nbShow df
      .select(
        col.Category,
        col.Brand,
        col.Subcategory,
        col("Sales Amount").mean.over("Category", "Brand").alias("Avg Sales per Cat and Brand"))
      .filter(col.Category == "Computers")
      .unique()
      .sort(["Brand", "Subcategory"])
      .head(10)

nanuq """
The book sorts by `Brand` only, which leaves the order within a brand open; both tabs sort
by subcategory as well.
"""

bookSave()
