import nanuqbook
bookInit()

nbText: "# Reshaping"

attribution definitiveGuide(15, "Reshaping",
  "Left out: " &
  "`partition_by(as_dict=True)`. The frames of `partition_by` are printed one by one " &
  "on both sides.")

nbText: """
The same data can be laid out in more than one shape. Reshaping moves values between rows
and columns without changing what they say.

## Wide versus long dataframes

In a *wide* frame each subject is a column, one row per student:
"""

tabs """
import polars as pl

grades_wide = pl.DataFrame(
    {
        "student": ["Jeroen", "Thijs", "Ritchie"],
        "math": [85, 78, 92],
        "science": [90, 82, 85],
        "history": [88, 80, 87],
    }
)

grades_wide
""":
  nbCode:
    import std/sugar
    import nanuq

    let gradesWide = newDataFrame:
      student: ["Jeroen", "Thijs", "Ritchie"]
      math: [85, 78, 92]
      science: [90, 82, 85]
      history: [88, 80, 87]
    nbShow gradesWide

nbText: """
In a *long* frame each grade is a row, with the subject in a column of its own. Wide is
easier to read; long is easier to filter, group and plot.
"""

tabs """
grades_long = pl.DataFrame(
    {
        "student": [
            "Jeroen",
            "Jeroen",
            "Jeroen",
            "Thijs",
            "Thijs",
            "Thijs",
            "Ritchie",
            "Ritchie",
            "Ritchie",
        ],
        "subject": [
            "Math",
            "Science",
            "History",
            "Math",
            "Science",
            "History",
            "Math",
            "Science",
            "History",
        ],
        "grade": [85, 90, 88, 78, 82, 80, 92, 85, 87],
    }
)

grades_long
""":
  nbCode:
    let gradesLong = newDataFrame:
      student: ["Jeroen", "Jeroen", "Jeroen", "Thijs", "Thijs", "Thijs",
                "Ritchie", "Ritchie", "Ritchie"]
      subject: ["Math", "Science", "History", "Math", "Science", "History",
                "Math", "Science", "History"]
      grade: [85, 90, 88, 78, 82, 80, 92, 85, 87]
    nbShow gradesLong

nbText: """
## Pivot to a wider dataframe

`pivot` goes from long to wide: the distinct values of the `on` column become columns, one
row per `index` value, and the cells come from `values`.
"""

tabs """
grades = pl.DataFrame(
    {
        "student": [
            "Jeroen",
            "Jeroen",
            "Jeroen",
            "Thijs",
            "Thijs",
            "Thijs",
            "Ritchie",
            "Ritchie",
            "Ritchie",
        ],
        "subject": [
            "Math",
            "Science",
            "History",
            "Math",
            "Science",
            "History",
            "Math",
            "Science",
            "History",
        ],
        "grade": [85, 90, 88, 78, 82, 80, 92, 85, 87],
    }
)

grades.pivot(index="student", on="subject", values="grade")
""":
  nbCode:
    let grades = gradesLong
    nbShow grades.pivot(index = "student", on = "subject", values = "grade")

nbText: """
When a student has more than one grade per subject, a cell gets several values, and they
have to be combined:
"""

tabs """
multiple_grades = pl.DataFrame(
    {
        "student": [
            "Jeroen",
            "Jeroen",
            "Jeroen",
            "Jeroen",
            "Jeroen",
            "Jeroen",
            "Thijs",
            "Thijs",
            "Thijs",
            "Thijs",
            "Thijs",
            "Thijs",
        ],
        "subject": [
            "Math",
            "Math",
            "Math",
            "Science",
            "Science",
            "Science",
            "Math",
            "Math",
            "Math",
            "Science",
            "Science",
            "Science",
        ],
        "grade": [85, 88, 85, 60, 66, 63, 51, 79, 62, 82, 85, 82],
    }
)

multiple_grades
""":
  nbCode:
    let multipleGrades = newDataFrame:
      student: ["Jeroen", "Jeroen", "Jeroen", "Jeroen", "Jeroen", "Jeroen",
                "Thijs", "Thijs", "Thijs", "Thijs", "Thijs", "Thijs"]
      subject: ["Math", "Math", "Math", "Science", "Science", "Science",
                "Math", "Math", "Math", "Science", "Science", "Science"]
      grade: [85, 88, 85, 60, 66, 63, 51, 79, 62, 82, 85, 82]
    nbShow multipleGrades

nanuq """
Python names the aggregation with a string, Nanuq with the enum `PivotAgg` (`First`,
`Last`, `Sum`, `Min`, `Max`, `Mean`, `Median`, `Len`, and `Item`, the default, which
fails when a cell gets more than one value).
"""

tabs """
multiple_grades.pivot(
    index="student", on="subject", values="grade", aggregate_function="mean"
)
""":
  nbCode:
    nbShow multipleGrades.pivot(index = "student", on = "subject", values = "grade",
                                aggregateFunction = PivotAgg.Mean)

nbText: """
Any expression works too: `pl.element()` stands for the values of one cell. Here, the
spread between the best and the worst grade:
"""

tabs """
multiple_grades.pivot(
    index="student",
    on="subject",
    values="grade",
    aggregate_function=pl.element().max() - pl.element().min(),
)
""":
  nbCode:
    nbShow multipleGrades.pivot(index = "student", on = "subject", values = "grade",
                                aggregateFunction = element().max - element().min)

nbText: """
A pivot has to look at the data to know which columns it makes, so it is eager. On a
LazyFrame, when you know the values of the `on` column in advance, you can write the pivot
yourself as a group-by with one filtered aggregation per value:
"""

nanuq """
Python builds the aggregations with a generator; Nim with `collect` from std/sugar
(written `sugar.collect`, since a LazyFrame has a `collect` too). The
aggregation function is a Nim proc. Nanuq's lazy `pivot` also takes the expected values,
as a frame: `lf.pivot(on = "col2", onColumns = newDataFrame(series("col2", ["x", "y"])),
index = "col1", values = "col3", aggregateFunction = element().tanh.mean)`.
"""

tabs """
lf = pl.LazyFrame(
    {
        "col1": ["a", "a", "a", "b", "b", "b"],
        "col2": ["x", "x", "x", "x", "y", "y"],
        "col3": [6, 7, 3, 2, 5, 7],
    }
)

index = pl.col("col1")
on = pl.col("col2")
values = pl.col("col3")
unique_column_values = ["x", "y"]
aggregate_function = lambda col: col.tanh().mean()

lf.group_by(index).agg(
    aggregate_function(values.filter(on == value)).alias(value)
    for value in unique_column_values
).collect()
""":
  nbCode:
    let lf = newDataFrame(
      series("col1", ["a", "a", "a", "b", "b", "b"]),
      series("col2", ["x", "x", "x", "x", "y", "y"]),
      series("col3", [6, 7, 3, 2, 5, 7])).lazy

    let index = col("col1")
    let on = col("col2")
    let values = col("col3")
    let uniqueColumnValues = ["x", "y"]
    proc aggregateFunction(c: Expr): Expr = c.tanh.mean

    let aggs = sugar.collect:
      for value in uniqueColumnValues:
        aggregateFunction(values.filter(on == value)).alias(value)
    nbShow lf.groupBy(index).agg(aggs).collect

nbText: """
## Unpivot to a longer dataframe

`unpivot` goes the other way: the `on` columns become two, one with the old column name
and one with its value, and the `index` columns are repeated.
"""

tabs """
grades_wide.unpivot(
    index=["student"],
    on=["math", "science", "history"],
    variable_name="subject",
    value_name="grade",
)
""":
  nbCode:
    nbShow gradesWide.unpivot(
      index = ["student"],
      on = ["math", "science", "history"],
      variableName = "subject",
      valueName = "grade")

nbText: "With more identifying columns, all of them go in `index`:"

tabs """
df = pl.DataFrame(
    {
        "student": ["Jeroen", "Thijs", "Ritchie", "Jeroen", "Thijs", "Ritchie"],
        "class": [
            "Math101",
            "Math101",
            "Math101",
            "Math102",
            "Math102",
            "Math102",
        ],
        "age": [20, 21, 22, 20, 21, 22],
        "semester": ["Fall", "Fall", "Fall", "Spring", "Spring", "Spring"],
        "math": [85, 78, 92, 88, 79, 95],
        "science": [90, 82, 85, 92, 81, 87],
        "history": [88, 80, 87, 85, 82, 89],
    }
)
df
""":
  nbCode:
    let df = newDataFrame(
      series("student", ["Jeroen", "Thijs", "Ritchie", "Jeroen", "Thijs", "Ritchie"]),
      series("class", ["Math101", "Math101", "Math101", "Math102", "Math102", "Math102"]),
      series("age", [20, 21, 22, 20, 21, 22]),
      series("semester", ["Fall", "Fall", "Fall", "Spring", "Spring", "Spring"]),
      series("math", [85, 78, 92, 88, 79, 95]),
      series("science", [90, 82, 85, 92, 81, 87]),
      series("history", [88, 80, 87, 85, 82, 89]))
    nbShow df

tabs """
df.unpivot(
    index=["student", "class", "age", "semester"],
    on=["math", "science", "history"],
    variable_name="subject",
    value_name="grade",
)
""":
  nbCode:
    nbShow df.unpivot(
      index = ["student", "class", "age", "semester"],
      on = ["math", "science", "history"],
      variableName = "subject",
      valueName = "grade")

nbText: """
## Transposing

`transpose` turns rows into columns and columns into rows, like a matrix. The old column
names can be kept in a column of their own, and the new columns can be named:
"""

nanuq """
Python passes the new names as a generator, made from the four column names: Polars
takes only the three it needs, one per row. Nanuq takes a seq with exactly one name per
row.
"""

tabs """
report_columns = (f"report_{i + 1}" for i, _ in enumerate(grades_wide.columns))

grades_wide.transpose(
    include_header=True,
    header_name="original_headers",
    column_names=report_columns,
)
""":
  nbCode:
    let reportColumns = sugar.collect:
      for i in 0 ..< gradesWide.height: "report_" & $(i + 1)

    nbShow gradesWide.transpose(
      includeHeader = true,
      headerName = "original_headers",
      columnNames = reportColumns)

nbText: """
## Exploding

A list column can be turned into rows, one per value, with the other columns repeated:
"""

tabs """
grades_nested = pl.DataFrame(
    {
        "student": ["Jeroen", "Thijs", "Ritchie"],
        "math": [[85, 90, 88], [78, 82, 80], [92, 85, 87]],
    }
)

grades_nested
""":
  nbCode:
    var gradesNested = newDataFrame:
      student: ["Jeroen", "Thijs", "Ritchie"]
      math: [@[85, 90, 88], @[78, 82, 80], @[92, 85, 87]]

    nbShow gradesNested

tabs """
grades_nested.explode("math")
""":
  nbCode:
    nbShow gradesNested.explode("math")

nbText: "Several list columns explode together only when their lists have the same lengths, row by row:"

tabs """
grades_nested = pl.DataFrame(
    {
        "student": ["Jeroen", "Thijs", "Ritchie"],
        "math": [[85, 90, 88], [78, 82, 80], [92, 85, 87]],
        "science": [[85, 90, 88], [78, 82], [92, 85, 87]],
        "history": [[85, 90, 88], [78, 82], [92, 85, 87]],
    }
)

grades_nested
""":
  nbCode:
    gradesNested = newDataFrame:
      student: ["Jeroen", "Thijs", "Ritchie"]
      math: [@[85, 90, 88], @[78, 82, 80], @[92, 85, 87]]
      science: [@[85, 90, 88], @[78, 82], @[92, 85, 87]]
      history: [@[85, 90, 88], @[78, 82], @[92, 85, 87]]

    nbShow gradesNested

tabs """
# This raises a ShapeError:
# grades_nested.explode("math", "science", "history")
""":
  nbCode:
    # This raises a ShapeError:
    # gradesNested.explode("math", "science", "history")
    doAssertRaises(ShapeError):
      discard gradesNested.explode(["math", "science", "history"])

nbText: "Unpivoting first gives one list per row, which then explodes on its own:"

tabs """
grades_nested_long = grades_nested.unpivot(
    index="student", variable_name="subject", value_name="grade"
)

grades_nested_long
""":
  nbCode:
    let gradesNestedLong = gradesNested.unpivot(
      index = ["student"], variableName = "subject", valueName = "grade")

    nbShow gradesNestedLong

tabs """
grades_nested_long.explode("grade")
""":
  nbCode:
    nbShow gradesNestedLong.explode("grade")

nbText: "Lists of lists explode one level at a time:"

tabs """
nested_lists = pl.DataFrame(
    {
        "id": [1, 2],
        "nested_value": [[["a", "b"]], [["c"], ["d", "e"]]],
    },
    strict=False,
)
nested_lists
""":
  nbCode:
    let nestedLists = newDataFrame:
      id: [1, 2]
      nested_value: [@[@["a", "b"]], @[@["c"], @["d", "e"]]]
    nbShow nestedLists

tabs """
nested_lists.explode("nested_value")
""":
  nbCode:
    nbShow nestedLists.explode("nested_value")

tabs """
nested_lists.explode("nested_value").explode("nested_value")
""":
  nbCode:
    nbShow nestedLists.explode("nested_value").explode("nested_value")

nbText: """
## Partition into multiple dataframes

`partition_by` splits a frame into one frame per value of a column:
"""

tabs """
sales = pl.DataFrame(
    {
        "OrderID": [1, 2, 3, 4, 5, 6],
        "Product": ["A", "B", "A", "C", "B", "A"],
        "Quantity": [10, 5, 8, 7, 3, 12],
        "Region": ["North", "South", "North", "West", "South", "West"],
    }
)
""":
  nbCode:
    let sales = newDataFrame:
      OrderID: [1, 2, 3, 4, 5, 6]
      Product: ["A", "B", "A", "C", "B", "A"]
      Quantity: [10, 5, 8, 7, 3, 12]
      Region: ["North", "South", "North", "West", "South", "West"]

nanuq """
`partitionBy` returns a `seq[DataFrame]` where Python returns a list; both sides print
the frames one by one.
"""

tabs """
for part in sales.partition_by("Region"):
    print(part)
""":
  nbCode:
    for part in sales.partitionBy("Region"):
      echo part

nbText: "Without the key column:"

tabs """
for part in sales.partition_by("Region", include_key=False):
    print(part)
""":
  nbCode:
    for part in sales.partitionBy("Region", includeKey = false):
      echo part

nanuq """
The book ends the section with `as_dict=True`, which returns a dictionary from each key
(a tuple) to its frame. Nanuq's `partitionBy` has no such option; in Nim, pair the frames
with their keys yourself, for example in a `Table`.
"""

bookSave()
