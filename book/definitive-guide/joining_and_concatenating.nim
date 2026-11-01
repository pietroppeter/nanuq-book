import nanuqbook
bookInit()

nbText: "# Joining and concatenating"

attribution definitiveGuide(14, "Joining and Concatenating",
  "Left out: the inexact (asof) joins and the campaign attribution use case built on them, " &
  "`how=\"align\"` and `align_frames`, and `vstack`, `hstack`, `append` and `extend`, which " &
  "Nanuq does not have yet.")

nbText: """
Data often comes in more than one table. A join puts two tables side by side, matching
their rows by key; a concatenation stacks them, one under (or next to) the other.

## Joining

### Join strategies

Two small frames that share some of their keys:
"""

tabs """
import polars as pl

df_left = pl.DataFrame({"key": ["A", "B", "C", "D"], "value": [1, 2, 3, 4]})

df_right = pl.DataFrame({"key": ["B", "C", "D", "E"], "value": [5, 6, 7, 8]})
""":
  nbCode:
    import nanuq

    let dfLeft = newDataFrame:
      key: ["A", "B", "C", "D"]
      value: [1, 2, 3, 4]
    let dfRight = newDataFrame:
      key: ["B", "C", "D", "E"]
      value: [5, 6, 7, 8]

nanuq """
The strategy is a value of the enum `JoinType` (`Inner`, the default, `Left`, `Right`,
`Full`, `Semi`, `Anti`, `Cross`), named as in Rust Polars, where Python uses strings.
"""

nbText: "#### Inner: only the keys found on both sides"

tabs """
df_left.join(df_right, on="key", how="inner")
""":
  nbCode:
    nbShow dfLeft.join(dfRight, on = ["key"], how = Inner)

nbText: """
#### Full: every key from either side

The `value` column of the right frame gets a suffix, since the left one has the same name.
"""

tabs """
df_left.join(df_right, on="key", how="full", suffix="_other")
""":
  nbCode:
    nbShow dfLeft.join(dfRight, on = ["key"], how = Full, suffix = "_other")

nbText: "#### Left: every key of the left frame"

tabs """
df_left.join(df_right, on="key", how="left")
""":
  nbCode:
    nbShow dfLeft.join(dfRight, on = ["key"], how = Left)

nbText: "#### Right: every key of the right frame"

tabs """
df_left.join(df_right, on="key", how="right")
""":
  nbCode:
    nbShow dfLeft.join(dfRight, on = ["key"], how = Right)

nbText: "#### Cross: every row of the left frame with every row of the right one"

tabs """
df_left.join(df_right, how="cross")
""":
  nbCode:
    nbShow dfLeft.join(dfRight, how = Cross)

nbText: "#### Semi: the left rows that have a match, with the left columns only"

tabs """
df_left.join(df_right, on="key", how="semi")
""":
  nbCode:
    nbShow dfLeft.join(dfRight, on = ["key"], how = Semi)

nbText: "#### Anti: the left rows that have no match"

tabs """
df_left.join(df_right, on="key", how="anti")
""":
  nbCode:
    nbShow dfLeft.join(dfRight, on = ["key"], how = Anti)

nbText: """
### Joining on multiple columns

With several key columns, rows match only when all of them are equal: Dave lives in San
Francisco on the left and works in Chicago on the right, so he drops out.
"""

tabs """
residences_left = pl.DataFrame(
    {
        "name": ["Alice", "Bob", "Charlie", "Dave"],
        "city": ["NY", "LA", "NY", "SF"],
        "age": [25, 30, 35, 40],
    }
)

departments_right = pl.DataFrame(
    {
        "name": ["Alice", "Bob", "Charlie", "Dave"],
        "city": ["NY", "LA", "NY", "Chicago"],
        "department": ["Finance", "Marketing", "Engineering", "Operations"],
    }
)

residences_left.join(departments_right, on=["name", "city"], how="inner")
""":
  nbCode:
    let residencesLeft = newDataFrame:
      name: ["Alice", "Bob", "Charlie", "Dave"]
      city: ["NY", "LA", "NY", "SF"]
      age: [25, 30, 35, 40]
    let departmentsRight = newDataFrame:
      name: ["Alice", "Bob", "Charlie", "Dave"]
      city: ["NY", "LA", "NY", "Chicago"]
      department: ["Finance", "Marketing", "Engineering", "Operations"]
    nbShow residencesLeft.join(departmentsRight, on = ["name", "city"], how = Inner)

nbText: """
### Validation

A join can check the shape of the relation it expects. Many employees work in one
department, so this is a many-to-one join: the keys must be unique on the right.
"""

tabs """
employees = pl.DataFrame(
    {
        "employee_id": [1, 2, 3, 4],
        "name": ["Alice", "Bob", "Charlie", "Dave"],
        "department_id": [10, 10, 30, 10],
    }
)

departments = pl.DataFrame(
    {
        "department_id": [10, 20, 30],
        "department_name": [
            "Information Technology",
            "Finance",
            "Human Resources",
        ],
    }
)

employees.join(departments, on="department_id", how="left", validate="m:1")
""":
  nbCode:
    let employees = newDataFrame:
      employee_id: [1, 2, 3, 4]
      name: ["Alice", "Bob", "Charlie", "Dave"]
      department_id: [10, 10, 30, 10]
    var departments = newDataFrame:
      department_id: [10, 20, 30]
      department_name: ["Information Technology", "Finance", "Human Resources"]
    nbShow employees.join(departments, on = ["department_id"], how = Left,
                          validate = ManyToOne)

nbText: """
When department 10 appears twice on the right, the same join fails:
"""

tabs """
departments = pl.DataFrame(
    {
        "department_id": [10, 20, 10],
        "department_name": [
            "Information Technology",
            "Finance",
            "Human Resources",
        ],
    }
)

try:
    employees.join(departments, on="department_id", how="left", validate="m:1")
except pl.exceptions.ComputeError as e:
    print(type(e).__name__)
""":
  nbCode:
    departments = newDataFrame:
      department_id: [10, 20, 10]
      department_name: ["Information Technology", "Finance", "Human Resources"]
    try:
      discard employees.join(departments, on = ["department_id"], how = Left,
                             validate = ManyToOne)
    except ComputeError:
      echo "ComputeError"

nanuq """
`validate` takes the enum `JoinValidation` (`ManyToMany`, the default, `ManyToOne`,
`OneToMany`, `OneToOne`) for Python's `"m:m"`, `"m:1"`, `"1:m"` and `"1:1"`. The book leaves
the failing cell commented out; here both sides run it and catch the error, which Nanuq
raises with the same type as Python since 0.3.
"""

nanuq """
The book's next part is about inexact joins (`join_asof`), which match each row with the
nearest key, and a use case that credits sales to marketing campaigns with them. Nanuq has
no asof joins yet, so that part is left out.
"""

nbText: """
## Vertical and horizontal concatenation

### Vertical: one frame under the other
"""

tabs """
df1 = pl.DataFrame(
    {
        "id": [1, 2, 3],
        "value": ["a", "b", "c"],
    }
)
df2 = pl.DataFrame(
    {
        "id": [4, 5],
        "value": ["d", "e"],
    }
)
pl.concat([df1, df2], how="vertical")
""":
  nbCode:
    let df1 = newDataFrame:
      id: [1, 2, 3]
      value: ["a", "b", "c"]
    let df2 = newDataFrame:
      id: [4, 5]
      value: ["d", "e"]
    nbShow concat([df1, df2], how = Vertical)

nbText: """
### Horizontal: side by side

The shorter frame is padded with nulls.
"""

tabs """
df1 = pl.DataFrame(
    {
        "id": [1, 2, 3],
        "value": ["a", "b", "c"],
    }
)
df2 = pl.DataFrame(
    {
        "value2": ["x", "y"],
    }
)
pl.concat([df1, df2], how="horizontal_extend")
""":
  nbCode:
    let df3 = newDataFrame:
      value2: ["x", "y"]
    nbShow concat([df1, df3], how = Horizontal)

nanuq """
Since Python Polars 2.0, `how="horizontal"` refuses frames of different heights, and
`"horizontal_extend"` pads them, so the Python side uses that. Nanuq follows Rust Polars
0.55, whose `Horizontal` still pads.
"""

nbText: """
### Diagonal: the union of the columns

Columns that a frame lacks are filled with nulls.
"""

tabs """
df1 = pl.DataFrame(
    {
        "id": [1, 2, 3],
        "value": ["a", "b", "c"],
    }
)
df2 = pl.DataFrame(
    {
        "value": ["d", "e"],
        "value2": ["x", "y"],
    }
)
pl.concat([df1, df2], how="diagonal")
""":
  nbCode:
    let df4 = newDataFrame:
      value: ["d", "e"]
      value2: ["x", "y"]
    nbShow concat([df1, df4], how = Diagonal)

nanuq """
The book also shows `how="align"` and `pl.align_frames`, which line up rows by key before
stacking. Nanuq does not have them yet.
"""

nbText: """
### Relaxed

A plain vertical concatenation needs the same data types in both frames. The relaxed one
casts the columns to a common supertype: here integers and floats become floats, strings
and integers become strings.
"""

tabs """
df1 = pl.DataFrame(
    {
        "id": [1, 2, 3],
        "value": ["a", "b", "c"],
    }
)
df2 = pl.DataFrame(
    {
        "id": [4.0, 5.0],
        "value": [1, 2],
    }
)
try:
    pl.concat([df1, df2], how="vertical")
except pl.exceptions.SchemaError as e:
    print(type(e).__name__)
""":
  nbCode:
    let df5 = newDataFrame:
      id: [4.0, 5.0]
      value: [1, 2]
    try:
      discard concat([df1, df5], how = Vertical)
    except PolarsError as e:
      echo e.name

nanuq """
Both fail, but not with the same error type: Python's eager `concat` raises a
`SchemaError`, while Nanuq's runs as a lazy query, whose planner raises an
`InvalidOperationError`. Catch `PolarsError`, the parent of both, to be safe.
"""

tabs """
pl.concat([df1, df2], how="vertical_relaxed")
""":
  nbCode:
    nbShow concat([df1, df5], how = VerticalRelaxed)

nanuq """
The chapter ends with `vstack`, `hstack`, `append` and `extend`, which add frames or
Series in place. Nanuq does not have them yet; `concat` covers what they do.
"""

bookSave()
