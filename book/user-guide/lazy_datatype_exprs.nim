import nanuqbook
bookInit()

nbText: "# Lazy: datatype expressions"

attribution userGuide("DataType expressions", "lazy/datatype_exprs",
  "Nanuq 0.6 has `dtypeOf` with `display`, `innerDtype` and `cast`, but not yet " &
  "`collect_dtype`, `wrap_in_list`, `to_signed_integer` or `matches`: those examples are " &
  "shown in Python only, and a box says what Nanuq does instead.")

nbText: """
In your lazy queries, you may want to reason about the datatypes of columns or expressions used
in your queries. DataType expressions allow for the inspection and manipulation of datatypes that
are used in your query. The datatypes are resolved during query planning and behave the same as
static datatypes during runtime.

DataType expressions can be especially useful when you don't have full control over input data.
This can occur when you try to compartmentalize code, write utility functions or are loading
data from heterogeneous data sources. DataType expressions also allow you to express relations
between the datatype of expressions or columns.

## Basic Usage

DataType expressions often start with `pl.dtype_of`. This allows inspecting the datatype of a
column or expression.

```python
dtype_expr = pl.dtype_of("UserID")

# For debugging you can collect the output datatype in a specific context.
schema = pl.Schema({ 'UserID': pl.UInt64, 'Name': pl.String })
dtype_expr.collect_dtype(schema)
```

```text
UInt64
```

These expressions can be manipulated in various ways to transform them into the datatype that
you need.

```python
dtype_expr.wrap_in_list().collect_dtype(schema)

dtype_expr.to_signed_integer().collect_dtype(schema)
```

```text
List(UInt64)
Int64
```
"""

nanuq """
Nanuq's `dtypeOf` builds the same kind of expression, but has no `collectDtype` and no
operations that make a new type out of it (`wrapInList`, `toSignedInteger` and the like). To
learn a type up front in Nim, ask the schema of the query: `lf.collectSchema["UserID"]` is a
`DataType` (here `UInt64`), and Nim code can build the others from it (`List(UInt64)`).
"""

nbText: """
You can also inspect information about the datatype to use at runtime.
"""

tabs """
import polars as pl
import polars.selectors as cs

schema = pl.Schema({ 'UserID': pl.UInt64, 'Name': pl.String })
df = schema.to_frame()
df.select(
    userid_dtype_name = pl.dtype_of('UserID').display(),
)
""":
  nbCode:
    import nanuq

    let df = newDataFrame(
      series("UserID", newSeq[uint64]()), series("Name", newSeq[string]()))
    nbShow df.select(
      dtypeOf("UserID").display.alias("userid_dtype_name"))

nanuq """
The guide also selects `userid_is_signed = pl.dtype_of('UserID').matches(cs.signed_integer())`
(false here). Nanuq's `DtypeOf` has no `matches` yet; `isSignedInteger(df.schema["UserID"])`
answers the same question in Nim, before the query runs.
"""

nbText: """
## Expressing relations between datatypes

Datatypes can help with utility functions by being able to express the relation between the
output datatype of two expressions. The following example allows you to express that
`map_batches` has the same output datatype as input datatype.
"""

tabs """
def inspect(expr: pl.Expr) -> pl.Expr:
    def print_and_return(s: pl.Series) -> pl.Series:
        print(s)
        return s

    return expr.map_batches(
        print_and_return,

        # Clarify that the expression returns the same datatype as the input
        # datatype.
        return_dtype=pl.dtype_of(expr),
    )

df = pl.DataFrame({
    'UserID': [1, 2, 3, 4, 5],
    'Name': ["Alice", "Bob", "Charlie", "Diana", "Ethan"],
})
df.select(inspect(pl.col('Name')))
""":
  nbCode:
    proc inspect(e: Expr): Expr =
      proc printAndReturn(s: Series): Series =
        echo s
        s

      # without a returnDtype, Nanuq's mapBatches already says the result
      # has the type of its input
      e.mapBatches(printAndReturn)

    let users = newDataFrame:
      UserID: [1, 2, 3, 4, 5]
      Name: ["Alice", "Bob", "Charlie", "Diana", "Ethan"]
    nbShow users.select(inspect(col.Name))

nbText: """
Similarly, you want to express that one column needs to be casted to the datatype of another
column.
"""

tabs """
df = pl.DataFrame({
    'UserID': [1, 2, 3, 4, 5],
    'Name': ["Alice", "Bob", "Charlie", "Diana", "Ethan"],
}).with_columns(
    pl.col('UserID').cast(pl.dtype_of('Name'))
)
df
""":
  nbCode:
    let casted = users.withColumns(
      col.UserID.cast(dtypeOf("Name")))
    nbShow casted

bookSave()
