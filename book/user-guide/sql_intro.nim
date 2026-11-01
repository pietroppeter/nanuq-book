import nanuqbook
bookInit()

nbText: "# SQL: introduction"

attribution userGuide("Introduction", "sql/intro",
  "The data is read from `data/polars/` instead of `docs/assets/data/`. The pandas frame of " &
  "the multiple-sources example is a Polars frame on both sides (the book's Python has no " &
  "pandas). Left out: registering pandas frames and the newer guide's Iceberg catalogs, " &
  "which Polars 2.1 and Nanuq do not have.")

nbText: """
While Polars supports interaction with SQL, it's recommended that users familiarize
themselves with the [expression syntax](expressions_and_contexts.html) to produce more
readable and expressive code. As the DataFrame interface is primary, new features are
typically added to the expression API first. However, if you already have an existing SQL
codebase or prefer the use of SQL, Polars does offers support for this.

> **Execution.** There is no separate SQL engine because Polars translates SQL queries into
> expressions, which are then executed using its own engine. This approach ensures that
> Polars maintains its performance and scalability advantages as a native DataFrame
> library, while still providing users with the ability to work with SQL.
"""

nanuq """
The same holds for Nanuq: a query goes to Polars' SQL front end, which turns it into the
same plan as the expressions would.
"""

nbText: """
## Context

Polars uses the `SQLContext` object to manage SQL queries. The context contains a mapping
of `DataFrame` and `LazyFrame` identifier names to their corresponding datasets[^1]. The
example below starts a `SQLContext`:
"""

tabs """
import polars as pl

ctx = pl.SQLContext()
""":
  nbCode:
    import nanuq

    var ctx = newSQLContext()

nbText: """
## Register Dataframes

There are several ways to register DataFrames during `SQLContext` initialization.

- register all `LazyFrame` and `DataFrame` objects in the global namespace.
- register explicitly via a dictionary mapping, or kwargs.
"""

tabs """
df = pl.DataFrame({"a": [1, 2, 3]})
lf = pl.LazyFrame({"b": [4, 5, 6]})

# Register all dataframes in the global namespace: registers both "df" and "lf"
ctx = pl.SQLContext(register_globals=True)

# Register an explicit mapping of identifier name to frame
ctx = pl.SQLContext(frames={"table_one": df, "table_two": lf})

# Register frames using kwargs; dataframe df as "df" and lazyframe lf as "lf"
ctx = pl.SQLContext(df=df, lf=lf)
""":
  nbCode:
    let df = newDataFrame:
      a: [1, 2, 3]
    let lf = newDataFrame(series("b", [4, 5, 6])).lazy

    # Register an explicit mapping of identifier name to frame
    ctx = newSQLContext({"table_one": df.lazy, "table_two": lf})

    # Register frames by variable name; dataframe df as "df" and lazyframe lf as "lf"
    ctx = sqlContext(df, lf)

nanuq """
Nim has no global namespace to search at run time, so there is no `register_globals`:
the macro `sqlContext(df, lf)` registers the frames you pass under the names of their
variables, which covers both it and the kwargs form. The mapping holds frames of one kind,
so the DataFrame goes in as `df.lazy`.
"""

nbText: """
Once the `SQLContext` is initialized, we can register additional Dataframes or unregister
existing Dataframes with:

- `register`
- `register_globals`
- `register_many`
- `unregister`
"""

nanuq """
Nanuq has `register(name, frame)`, `register({"name": frame, ...})` for many at once, and
`unregister(name)`; `tables` lists the registered names.
"""

nbText: """
## Execute queries and collect results

SQL queries are always executed in lazy mode to take advantage of the full set of query
planning optimizations, so we have two options to collect the result:

- Set the parameter `eager` to True in `SQLContext`; this ensures that Polars automatically
  collects the LazyFrame results from `execute` calls.
- Set the parameter `eager` to True when executing a query with `execute`, or explicitly
  collect the result using `collect`.

We execute SQL queries by calling `execute` on a `SQLContext`.
"""

tabs """
pokemon = pl.scan_csv("data/polars/pokemon.csv")
with pl.SQLContext(register_globals=True, eager=True) as ctx:
    df_small = ctx.execute("SELECT * from pokemon LIMIT 5")
df_small
""":
  nbCode:
    let pokemon = scanCsv("data/polars/pokemon.csv")
    let pokemonCtx = sqlContext(pokemon)
    let dfSmall = pokemonCtx.execute("SELECT * from pokemon LIMIT 5", eager = true)
    nbShow dfSmall

nanuq """
`eager = true` is a parameter of `execute` only (it decides at compile time whether the
result is a DataFrame or a LazyFrame), and a context needs no `with` block.
"""

nbText: """
## Execute queries from multiple sources

SQL queries can be executed just as easily from multiple sources. In the example below, we
register:

- a CSV file (loaded lazily)
- a NDJSON file (loaded lazily)
- a Pandas DataFrame

And join them together using SQL. Lazy reading lets you only load the necessary rows and
columns from the files.
"""

tabs """
with open("data/polars/products_categories.json", "w") as temp_file:
    json_data = '''{"product_id": 1, "category": "Category 1"}
{"product_id": 2, "category": "Category 1"}
{"product_id": 3, "category": "Category 2"}
{"product_id": 4, "category": "Category 2"}
{"product_id": 5, "category": "Category 3"}'''

    temp_file.write(json_data)

with open("data/polars/products_masterdata.csv", "w") as temp_file:
    csv_data = '''product_id,product_name
1,Product A
2,Product B
3,Product C
4,Product D
5,Product E'''

    temp_file.write(csv_data)

sales_data = pl.DataFrame(
    {
        "product_id": [1, 2, 3, 4, 5],
        "sales": [100, 200, 150, 250, 300],
    }
)

with pl.SQLContext(
    products_masterdata=pl.scan_csv("data/polars/products_masterdata.csv"),
    products_categories=pl.scan_ndjson("data/polars/products_categories.json"),
    sales_data=sales_data,
    eager=True,
) as ctx:
    query = '''
    SELECT
        product_id,
        product_name,
        category,
        sales
    FROM
        products_masterdata
    LEFT JOIN products_categories USING (product_id)
    LEFT JOIN sales_data USING (product_id)
    '''
    result = ctx.execute(query)
result
""":
  nbCode:
    writeFile("data/polars/products_categories.json", """{"product_id": 1, "category": "Category 1"}
{"product_id": 2, "category": "Category 1"}
{"product_id": 3, "category": "Category 2"}
{"product_id": 4, "category": "Category 2"}
{"product_id": 5, "category": "Category 3"}""")

    writeFile("data/polars/products_masterdata.csv", """product_id,product_name
1,Product A
2,Product B
3,Product C
4,Product D
5,Product E""")

    let salesData = newDataFrame:
      product_id: [1, 2, 3, 4, 5]
      sales: [100, 200, 150, 250, 300]

    let sources = newSQLContext({
      "products_masterdata": scanCsv("data/polars/products_masterdata.csv"),
      "products_categories": scanNdjson("data/polars/products_categories.json"),
      "sales_data": salesData.lazy})
    let query = """
    SELECT
        product_id,
        product_name,
        category,
        sales
    FROM
        products_masterdata
    LEFT JOIN products_categories USING (product_id)
    LEFT JOIN sales_data USING (product_id)
    """
    nbShow sources.execute(query, eager = true)

nbText: """
## Compatibility

Polars does not support the complete SQL specification, but it does support a subset of
the most common statement types.

> **Dialect.** Where possible, Polars aims to follow PostgreSQL syntax definitions and
> function behaviour.

For example, here is a non-exhaustive list of some of the supported functionality:

- Write a `CREATE` statements: `CREATE TABLE xxx AS ...`
- Write a `SELECT` statements containing:`WHERE`,`ORDER`,`LIMIT`,`GROUP BY`,`UNION` and
  `JOIN` clauses ...
- Write Common Table Expressions (CTE's) such as: `WITH tablename AS`
- Explain a query: `EXPLAIN SELECT ...`
- List registered tables: `SHOW TABLES`
- Drop a table: `DROP TABLE [IF EXISTS] tablename`
- Truncate a table: `TRUNCATE TABLE [IF EXISTS] tablename`

The following are some features that are not yet supported:

- `INSERT`, `UPDATE` or `DELETE` statements
- Meta queries such as `ANALYZE`

In the upcoming sections we will cover each of the statements in more detail.

[^1]: Additionally it also tracks the [common table expressions](sql_cte.html) as well.
"""

bookSave()
