import nanuqbook
bookInit()

nbText: "# Joining and concatenating"

attribution definitiveGuide(14, "Joining and Concatenating",
  "Left out: `how=\"align\"` and `align_frames`, and `vstack`, `hstack`, `append` and " &
  "`extend`, which Nanuq does not have yet.")

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

nbText: """
## Inexact joining

Sometimes keys don't match exactly: a sale happens some time after the campaign that
caused it, a reading comes in a few seconds after the event it measures. An asof join
(`join_asof`) matches each row on the left with the *nearest* row on the right, instead of
an equal one. Take two small frames with integer keys:
"""

tabs """
df_left = pl.DataFrame({"int_id": [10, 5], "value": ["b", "a"]})

df_right = pl.DataFrame({"int_id": [4, 7, 12], "value": [1, 2, 3]})
""":
  nbCode:
    var asofLeft = newDataFrame:
      int_id: [10, 5]
      value: ["b", "a"]
    let asofRight = newDataFrame:
      int_id: [4, 7, 12]
      value: [1, 2, 3]

nbText: """
Both keys must be sorted. `df_left` isn't, and the book shows the join failing on it
(`InvalidOperationError`, left commented out). Once it is sorted, every left row gets the
last right row whose key is at or below its own:
"""

nanuq """
`joinAsof` takes the key as `on` (a column name or an expression), like Python. Nanuq
raises the same `InvalidOperationError` for unsorted keys.
"""

tabs """
df_left = df_left.sort("int_id")
df_right = df_right

df_left.join_asof(df_right, on="int_id")
""":
  nbCode:
    asofLeft = asofLeft.sort("int_id")

    nbShow asofLeft.joinAsof(asofRight, on = "int_id")

nbText: """
The key column appears once, with the left values. With `coalesce=False` the right key is
kept too, so you see which row was matched:
"""

tabs """
df_left.join_asof(
    df_right,
    on="int_id",
    coalesce=False,
)
""":
  nbCode:
    nbShow asofLeft.joinAsof(asofRight, on = "int_id", coalesce = false)

nbText: """
When the keys have different names, use `left_on` and `right_on`:
"""

tabs """
df_left.join_asof(
    df_right.rename({"int_id": "int_id_right"}),
    left_on="int_id",
    right_on="int_id_right",
)
""":
  nbCode:
    nbShow asofLeft.joinAsof(asofRight.rename({"int_id": "int_id_right"}),
                           leftOn = "int_id", rightOn = "int_id_right")

nbText: """
### Inexact join strategies

Which row counts as nearest is the `strategy`: `"backward"` (the default) looks for the
last key at or before, `"forward"` for the first key at or after, and `"nearest"` for the
closest either way. `tolerance` sets how far away a match may be; farther rows get nulls.
The two frames again:
"""

tabs """
print(df_left)
print(df_right)
""":
  nbCode:
    echo asofLeft
    echo asofRight

nanuq """
In Nanuq the strategy is a value of the enum `AsofStrategy`: `Backward`, `Forward` or
`Nearest`. The tolerance is a number for numeric keys, and a Polars interval (`"60d"`) or
a std/times one (`60.days`) for temporal keys.
"""

tabs """
df_left.join_asof(
    df_right,
    on="int_id",
    tolerance=3,
    strategy="backward",
)
""":
  nbCode:
    nbShow asofLeft.joinAsof(asofRight, on = "int_id", tolerance = 3, strategy = Backward)

tabs """
df_left.join_asof(
    df_right,
    on="int_id",
    tolerance=3,
    strategy="forward",
)
""":
  nbCode:
    nbShow asofLeft.joinAsof(asofRight, on = "int_id", tolerance = 3, strategy = Forward)

tabs """
df_left.join_asof(
    df_right,
    on="int_id",
    tolerance=3,
    strategy="nearest",
)
""":
  nbCode:
    nbShow asofLeft.joinAsof(asofRight, on = "int_id", tolerance = 3, strategy = Nearest)

nanuq """
The book's “Additional fine-tuning” covers `allow_exact_matches` and `check_sortedness`;
Nanuq has both, as `allowExactMatches` and `checkSortedness`.
"""

nbText: """
### Use case: marketing campaign attribution

A shop ran marketing campaigns, each for one product type, and wants to know which sales
came after which campaign. A campaign counts for the sales of its product type in the 60
days after it. First the campaigns:
"""

tabs """
campaigns = pl.scan_csv("data/definitive-guide/campaigns.csv")
campaigns.head(1).collect()
""":
  nbCode:
    var campaigns = scanCsv("data/definitive-guide/campaigns.csv")
    nbShow campaigns.head(1).collect

tabs """
campaigns.select(pl.col("Product Type").unique()).collect()
""":
  nbCode:
    nbShow campaigns.select(col("Product Type").unique).collect

nbText: """
and the sales:
"""

tabs """
transactions = pl.scan_csv("data/definitive-guide/transactions.csv")
transactions.head(1).collect()
""":
  nbCode:
    var transactions = scanCsv("data/definitive-guide/transactions.csv")
    nbShow transactions.head(1).collect

nbText: """
Both date columns are read as strings, so they are parsed first. Then each sale, sorted
by date, is joined with the last campaign for the same product type (`by`) at most 60 days
before it:
"""

nanuq """
`str.toDatetime` parses straight to microseconds (its `timeUnit` defaults to
`Microseconds`), where the book parses to nanoseconds and casts. `by` takes a column name
or a list of them.
"""

tabs """
transactions = transactions.with_columns(
    pl.col("Sale Date")
    .str.to_datetime("%Y-%m-%d %H:%M:%S%.f")
    .cast(pl.Datetime("us")),
)
campaigns = campaigns.with_columns(
    pl.col("Campaign Date").str.to_datetime("%Y-%m-%d %H:%M:%S"),
)

sales_with_campaign_df = (
    transactions.sort("Sale Date")
    .join_asof(
        campaigns.sort("Campaign Date"),
        left_on="Sale Date",
        right_on="Campaign Date",
        by="Product Type",
        strategy="backward",
        tolerance="60d",
        check_sortedness=False,
    )
    .collect()
)
sales_with_campaign_df
""":
  nbCode:
    transactions = transactions.withColumns(
      col("Sale Date").str.toDatetime("%Y-%m-%d %H:%M:%S%.f"))
    campaigns = campaigns.withColumns(
      col("Campaign Date").str.toDatetime("%Y-%m-%d %H:%M:%S"))

    let salesWithCampaignDf = transactions.sort("Sale Date")
      .joinAsof(
        campaigns.sort("Campaign Date"),
        leftOn = "Sale Date",
        rightOn = "Campaign Date",
        by = "Product Type",
        strategy = Backward,
        tolerance = "60d",
        checkSortedness = false)
      .collect
    nbShow salesWithCampaignDf

nbText: """
Did the campaigns make people buy more? The mean quantity per product type and campaign
(null: no campaign in the 60 days before):
"""

tabs """
(
    sales_with_campaign_df.group_by("Product Type", "Campaign Name")
    .agg(pl.col("Quantity").mean())
    .sort("Product Type", "Campaign Name")
)
""":
  nbCode:
    nbShow salesWithCampaignDf.groupBy("Product Type", "Campaign Name")
      .agg(col("Quantity").mean)
      .sort(["Product Type", "Campaign Name"])

nbText: """
Books had a campaign at the very end of the year:
"""

tabs """
campaigns.filter(pl.col("Product Type") == "Books").collect()
""":
  nbCode:
    nbShow campaigns.filter(col("Product Type") == "Books").collect

nbText: """
and only a few book sales came after it, before the data ends:
"""

nanuq """
Python turns the string into a datetime literal with `pl.lit(...).str.to_datetime()`;
in Nim it is a std/times `DateTime`, which Nanuq compares with the column directly.
"""

tabs """
(
    transactions.filter(
        (pl.col("Product Type") == "Books")
        & (
            pl.col("Sale Date")
            > pl.lit("2023-12-31 21:00:00").str.to_datetime()
        )
    ).collect()
)
""":
  nbCode:
    import std/times
    nbShow transactions.filter(
      (col("Product Type") == "Books") and
      (col("Sale Date") > dateTime(2023, mDec, 31, 21, zone = utc()))).collect

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
