import nanuqbook
bookInit()

nbText: "# SQL: SELECT"

attribution userGuide("SELECT", "sql/select",
  "The data is read from `data/polars/` instead of `docs/assets/data/`. Left out: the " &
  "table functions with named options (Nanuq's Rust Polars is older than Python Polars " &
  "2.1's), and the `read_ndjson`, `read_parquet` and `read_ipc` examples, which use them.")

nbText: """
In Polars SQL, the `SELECT` statement is used to retrieve data from a table into a
`DataFrame`. The basic syntax of a `SELECT` statement in Polars SQL is as follows:

```sql
SELECT column1, column2, ...
FROM table_name;
```

Here, `column1`, `column2`, etc. are the columns that you want to select from the table.
You can also use the wildcard `*` to select all columns. `table_name` is the name of the
table or that you want to retrieve data from. In the sections below we will cover some of
the more common SELECT variants
"""

tabs """
import polars as pl

df = pl.DataFrame(
    {
        "country": ["USA", "USA", "USA", "USA", "USA", "Netherlands"],
        "city": [
            "New York",
            "Los Angeles",
            "Chicago",
            "Houston",
            "Phoenix",
            "Amsterdam",
        ],
        "population": [8399000, 3997000, 2705000, 2320000, 1680000, 900000],
    }
)

ctx = pl.SQLContext(population=df, eager=True)

ctx.execute("SELECT * FROM population")
""":
  nbCode:
    import nanuq

    let population = newDataFrame:
      country: ["USA", "USA", "USA", "USA", "USA", "Netherlands"]
      city: ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Amsterdam"]
      population: [8399000, 3997000, 2705000, 2320000, 1680000, 900000]

    let ctx = sqlContext(population)

    nbShow ctx.execute("SELECT * FROM population", eager = true)

nanuq """
`sqlContext(population)` registers the frame under its variable's name, as Python's
`SQLContext(population=df)` does with a keyword. Each `execute` asks for an eager result.
"""

nbText: """
### GROUP BY

The `GROUP BY` statement is used to group rows in a table by one or more columns and
compute aggregate functions on each group.
"""

tabs """
result = ctx.execute(
    '''
        SELECT country, AVG(population) as avg_population
        FROM population
        GROUP BY country
    '''
)
result
""":
  nbCode:
    nbShow ctx.execute("""
        SELECT country, AVG(population) as avg_population
        FROM population
        GROUP BY country
    """, eager = true)

nbText: """
### ORDER BY

The `ORDER BY` statement is used to sort the result set of a query by one or more columns
in ascending or descending order.
"""

tabs """
result = ctx.execute(
    '''
        SELECT city, population
        FROM population
        ORDER BY population
    '''
)
result
""":
  nbCode:
    nbShow ctx.execute("""
        SELECT city, population
        FROM population
        ORDER BY population
    """, eager = true)

nbText: "### JOIN"

tabs """
income = pl.DataFrame(
    {
        "country": [
            "USA",
            "USA",
            "USA",
            "USA",
            "Netherlands",
            "Netherlands",
            "Netherlands",
        ],
        "city": [
            "New York",
            "Los Angeles",
            "Chicago",
            "Houston",
            "Amsterdam",
            "Rotterdam",
            "Utrecht",
        ],
        "income": [55000, 62000, 48000, 52000, 42000, 38000, 41000],
    }
)
ctx.register_many(income=income)
result = ctx.execute(
    '''
        SELECT income.*, population.population
        FROM population
        LEFT JOIN income ON population.city = income.city
    '''
)
result
""":
  nbCode:
    let income = newDataFrame:
      country: ["USA", "USA", "USA", "USA", "Netherlands", "Netherlands", "Netherlands"]
      city: ["New York", "Los Angeles", "Chicago", "Houston", "Amsterdam", "Rotterdam",
             "Utrecht"]
      income: [55000, 62000, 48000, 52000, 42000, 38000, 41000]
    ctx.register({"income": income})
    nbShow ctx.execute("""
        SELECT income.*, population.population
        FROM population
        LEFT JOIN income ON population.city = income.city
    """, eager = true)

nbText: """
### Functions

Polars provides a wide range of SQL functions, including:

- Mathematical functions: `ABS`, `EXP`, `LOG`, `ASIN`, `ACOS`, `ATAN`, etc.
- String functions: `LOWER`, `UPPER`, `LTRIM`, `RTRIM`, `STARTS_WITH`,`ENDS_WITH`.
- Aggregation functions: `SUM`, `AVG`, `MIN`, `MAX`, `COUNT`, `STDDEV`, `FIRST` etc.
- Array functions: `EXPLODE`, `UNNEST`,`ARRAY_SUM`,`ARRAY_REVERSE`, etc.

For a full list of supported functions go the
[API documentation](https://docs.rs/polars-sql/latest/src/polars_sql/keywords.rs.html). The
example below demonstrates how to use a function in a query
"""

tabs """
result = ctx.execute(
    '''
        SELECT city, population
        FROM population
        WHERE STARTS_WITH(country,'U')
    '''
)
result
""":
  nbCode:
    nbShow ctx.execute("""
        SELECT city, population
        FROM population
        WHERE STARTS_WITH(country,'U')
    """, eager = true)

nbText: """
### Table Functions

In the examples earlier we first generated a DataFrame which we registered in the
`SQLContext`. Polars also support directly reading from CSV, Parquet, JSON and IPC in your
SQL query using table functions `read_xxx`.
"""

tabs """
result = ctx.execute(
    '''
        SELECT *
        FROM read_csv('data/polars/iris.csv')
    '''
)
result
""":
  nbCode:
    nbShow ctx.execute("""
        SELECT *
        FROM read_csv('data/polars/iris.csv')
    """, eager = true)

nbText: """
The path can also be a glob, or a list of paths or globs, as in
`read_parquet(['a.parquet', 'b.parquet'])`.

`read_csv` also accepts named options after the path, with the same names and meaning as
the options of `scan_csv`. Write them as `name => value` (or `name := value`):
"""

nanuq """
Nanuq's Rust Polars (0.55.2, the newest on crates.io) is older than the one inside Python
Polars 2.1, and its SQL takes only the path in table functions, so the examples with
named options are left out.
"""

nbText: """
The supported options are:

- Layout: `has_header`, `separator`, `quote_char`, `comment_prefix`, `skip_rows`,
  `skip_rows_after_header`, `skip_lines`, `encoding`.
- Names and types: `new_columns`, `schema`, `schema_overrides`, `infer_schema`,
  `infer_schema_length`, `infer_schema_files`, `try_parse_dates`, `decimal_comma`.
- Values and errors: `null_values`, `ignore_errors`.
- Ragged rows and multiple files: `truncate_ragged_lines`, `missing_columns`,
  `extra_columns`, `include_file_paths`.

Values are SQL literals:

- `NULL` stands for `None`, as in `infer_schema_length => NULL` to infer the schema from
  the whole file, or `quote_char => NULL` to turn quoting off.
- Lists use brackets: `new_columns => ['a', 'b']`.
- `schema`, `schema_overrides` and per-column `null_values` take a dictionary, with types
  written as SQL type names: `schema_overrides => {'id': 'INT', 'name': 'VARCHAR'}`.
  `schema_overrides` also accepts a list of type names, by position.
- Escape sequences need an `E''` string, as in `separator => E'\t'` for tab-separated
  files.

Unlike `scan_csv`, `read_csv` tries to parse dates by default (`try_parse_dates => true`).
"""

bookSave()
