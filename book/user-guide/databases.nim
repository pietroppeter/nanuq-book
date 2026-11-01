import nanuqbook
bookInit()

nbText: "# Databases"

attribution userGuide("Databases", "io/database",
  "The examples use a SQLite file, `data/polars/records.db`, instead of a PostgreSQL server, " &
  "and the Python side uses the ADBC engine (`adbc-driver-sqlite`) instead of SQLAlchemy " &
  "and ConnectorX. The table is written first and then read back, with " &
  "`if_table_exists=\"replace\"` so that the two tabs can write the same table. The pip " &
  "install lines are left out.")

nanuq """
Nanuq talks to databases through the optional module `nanuq/database`, which uses Nim's
[db_connector](https://github.com/nim-lang/db_connector) package (the database modules
that left Nim's standard library). For now it supports SQLite: `readDatabase` takes an open
`DbConn`, `readDatabaseUri` a `sqlite:///path` URI, and `writeDatabase` writes a frame to a
table. The engines discussed below are the Python ones.
"""

nbText: """
## Write to a database

We can write to a database with Polars using the `pl.write_database` function.

### Engines

As with reading from a database below, Polars uses an *engine* to write to a database. The
currently supported engines are:

- [SQLAlchemy](https://www.sqlalchemy.org/) and
- Arrow Database Connectivity (ADBC)

#### ADBC

ADBC can also be used to write to a database. Writing is supported for the same databases
that support reading with ADBC.

In this example, we write the `DataFrame` to a table called `records` in the database:
"""

tabs """
import polars as pl

uri = "sqlite:///data/polars/records.db"
df = pl.DataFrame({"foo": [1, 2, 3]})

df.write_database(table_name="records", connection=uri, engine="adbc",
                  if_table_exists="replace")
""":
  nbCode:
    import nanuq, nanuq/database
    import db_connector/db_sqlite

    let conn = open("data/polars/records.db", "", "", "")
    let df = newDataFrame(series("foo", [1, 2, 3]))

    echo df.writeDatabase("records", conn, ifTableExists = IfTableExists.Replace)

nbText: """
## Read from a database

Polars can read from a database using the `pl.read_database_uri` and `pl.read_database`
functions.

### Difference between `read_database_uri` and `read_database`

Use `pl.read_database_uri` if you want to specify the database connection with a connection
string called a `uri`. For example, the following snippet shows a query to read all columns
from the `records` table in a SQLite database where we use the `uri` to connect:
"""

tabs """
query = "SELECT * FROM records"

pl.read_database_uri(query=query, uri=uri, engine="adbc")
""":
  nbCode:
    let uri = "sqlite:///data/polars/records.db"
    let query = "SELECT * FROM records"

    nbShow readDatabaseUri(query = query, uri = uri)

nbText: """
On the other hand, use `pl.read_database` if you want to connect via a connection object
you created yourself, such as an SQLAlchemy engine or, as here, a connection of Python's
own `sqlite3` module (Nim's `db_sqlite` in the other tab):
"""

tabs """
import sqlite3

connection = sqlite3.connect("data/polars/records.db")

pl.read_database(query=query, connection=connection)
""":
  nbCode:
    nbShow readDatabase(query = query, connection = conn)
    conn.close()

nbText: """
Note that `pl.read_database_uri` is likely to be faster than `pl.read_database` if you are
using a SQLAlchemy or DBAPI2 connection as these connections may load the data row-wise into
Python before copying the data again to the column-wise Apache Arrow format.

### Engines

Polars doesn't manage connections and data transfer from databases by itself. Instead,
external libraries (known as *engines*) handle this.

When using `pl.read_database`, you specify the engine when you create the connection
object. When using `pl.read_database_uri`, you can specify one of two engines to read from
the database:

- [ConnectorX](https://github.com/sfu-db/connector-x) and
- [ADBC](https://arrow.apache.org/docs/format/ADBC.html)

Both engines have native support for Apache Arrow and so can read data directly into a
Polars `DataFrame` without copying the data.

#### ConnectorX

ConnectorX is the default engine and
[supports numerous databases](https://github.com/sfu-db/connector-x#sources) including
Postgres, Mysql, SQL Server and Redshift. ConnectorX is written in Rust and stores data in
Arrow format to allow for zero-copy to Polars.

#### ADBC

ADBC (Arrow Database Connectivity) is an engine supported by the Apache Arrow project. ADBC
aims to be both an API standard for connecting to databases and libraries implementing this
standard in a range of languages.

It is still early days for ADBC so support for different databases is limited. At present,
drivers for ADBC are only available for
[Postgres](https://pypi.org/project/adbc-driver-postgresql/),
[SQLite](https://pypi.org/project/adbc-driver-sqlite/) and
[Snowflake](https://pypi.org/project/adbc-driver-snowflake/). As ADBC is not the default
engine, you must specify the engine as an argument to `pl.read_database_uri`, as above.
"""

bookSave()
