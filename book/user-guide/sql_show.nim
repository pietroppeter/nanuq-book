import nanuqbook
bookInit()

nbText: "# SQL: SHOW TABLES"

attribution userGuide("SHOW TABLES", "sql/show", "")

nbText: """
In Polars, the `SHOW TABLES` statement is used to list all the tables that have been
registered in the current `SQLContext`. When you register a DataFrame with the
`SQLContext`, you give it a name that can be used to refer to the DataFrame in subsequent
SQL statements. The `SHOW TABLES` statement allows you to see a list of all the registered
tables, along with their names.

The syntax for the `SHOW TABLES` statement in Polars is as follows:

```
SHOW TABLES
```

Here's an example of how to use the `SHOW TABLES` statement in Polars:
"""

tabs """
import polars as pl

# Create some DataFrames and register them with the SQLContext
df1 = pl.LazyFrame(
    {
        "name": ["Alice", "Bob", "Charlie", "David"],
        "age": [25, 30, 35, 40],
    }
)
df2 = pl.LazyFrame(
    {
        "name": ["Ellen", "Frank", "Gina", "Henry"],
        "age": [45, 50, 55, 60],
    }
)
ctx = pl.SQLContext(mytable1=df1, mytable2=df2)

tables = ctx.execute("SHOW TABLES", eager=True)
tables
""":
  nbCode:
    import nanuq

    # Create some DataFrames and register them with the SQLContext
    let df1 = newDataFrame:
      name: ["Alice", "Bob", "Charlie", "David"]
      age: [25, 30, 35, 40]
    let df2 = newDataFrame:
      name: ["Ellen", "Frank", "Gina", "Henry"]
      age: [45, 50, 55, 60]
    let ctx = newSQLContext({"mytable1": df1.lazy, "mytable2": df2.lazy})

    let tables = ctx.execute("SHOW TABLES", eager = true)
    nbShow tables

nanuq """
`ctx.tables` gives the same names as a Nim `seq[string]`.
"""

nbText: """
In this example, we create two DataFrames and register them with the `SQLContext` using
different names. We then execute a `SHOW TABLES` statement using the `execute()` method of
the `SQLContext` object, which returns a DataFrame containing a list of all the registered
tables and their names. The resulting DataFrame is then printed using the `print()`
function.

Note that the `SHOW TABLES` statement only lists tables that have been registered with the
current `SQLContext`. If you register a DataFrame with a different `SQLContext` or in a
different Python session, it will not appear in the list of tables returned by
`SHOW TABLES`.
"""

bookSave()
