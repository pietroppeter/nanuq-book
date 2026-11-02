import nanuqbook
bookInit()

nbText: "# Grouping data"

attribution realPython("How to Group Data Using Polars .group_by()", "polars-groupby",
  "polars-groupby",
  "The data is the UCI Student Performance dataset (Cortez and Silva, 2008, CC BY 4.0), " &
  "as the tutorial's Parquet files: `data/real-python/math.parquet`, `portuguese.parquet` " &
  "and `course.parquet` (both courses, with a `subject` column), plus `math_classes.parquet` " &
  "(absences per class). Cells that repeat an earlier one are left out.")

nbText: """
Students of two Portuguese schools, one row per student and course, with their grades in three
periods (`G1`, `G2`, `G3`, out of 20) and how many classes they missed (`absences`).

## Aggregating a whole column

The most absences in the maths course, and who had them:
"""

tabs """
import polars as pl

math_students = pl.read_parquet("data/real-python/math.parquet")

(math_students.select(pl.col("absences").max()))
""":
  nbCode:
    import nanuq

    let mathStudents = readParquet("data/real-python/math.parquet")

    nbShow mathStudents.select(col.absences.max)

tabs """
(
    math_students.select(pl.col("student_id", "absences")).filter(
        pl.col("absences") == pl.col("absences").max()
    )
)
""":
  nbCode:
    nbShow mathStudents.select(col("student_id", "absences")).filter(
      col.absences == col.absences.max)

nbText: """
Several aggregations at once, named with keyword arguments in Python and with `alias` in Nim:
"""

tabs """
(
    math_students.select(
        min=pl.col("absences").min(),
        max=pl.col("absences").max(),
        mean=pl.col("absences").mean(),
    )
)
""":
  nbCode:
    nbShow mathStudents.select(
      col.absences.min.alias("min"),
      col.absences.max.alias("max"),
      col.absences.mean.alias("mean"))

nanuq """
Nim has keyword arguments too, but not an open set of them, so Nanuq names a new column with
`alias` (or `name.suffix` and the like).
"""

nbText: """
Aggregating across columns instead, row by row:
"""

tabs """
math_students.select(
    "student_id",
    "G1",
    "G2",
    "G3",
    total=pl.sum_horizontal("G1", "G2", "G3"),
    mean=pl.mean_horizontal("G1", "G2", "G3"),
)
""":
  nbCode:
    nbShow mathStudents.select(
      col.student_id,
      col.G1,
      col.G2,
      col.G3,
      sumHorizontal(["G1", "G2", "G3"]).alias("total"),
      meanHorizontal(["G1", "G2", "G3"]).alias("mean"))

nbText: """
## Grouping by one column

The same statistics for the Portuguese course, and then for both courses at once, from the
table that holds them both:
"""

tabs """
portuguese_students = pl.read_parquet("data/real-python/portuguese.parquet")

(
    portuguese_students.select(
        min=pl.col("absences").min(),
        max=pl.col("absences").max(),
        mean=pl.col("absences").mean(),
    )
)
""":
  nbCode:
    let portugueseStudents = readParquet("data/real-python/portuguese.parquet")

    nbShow portugueseStudents.select(
      col.absences.min.alias("min"),
      col.absences.max.alias("max"),
      col.absences.mean.alias("mean"))

tabs """
all_students = pl.read_parquet("data/real-python/course.parquet")

(
    all_students.group_by("subject").agg(
        min=pl.col("absences").min(),
        max=pl.col("absences").max(),
        mean=pl.col("absences").mean(),
    )
)
""":
  nbCode:
    let allStudents = readParquet("data/real-python/course.parquet")

    nbShow allStudents.groupBy("subject").agg(
      col.absences.min.alias("min"),
      col.absences.max.alias("max"),
      col.absences.mean.alias("mean"))

nbText: """
An aggregation that is not one value: a list of the final grades of each age group,
"""

tabs """
(
    math_students.group_by("age").agg(
        passes=pl.col("G3"),
    )
)
""":
  nbCode:
    nbShow mathStudents.groupBy("age").agg(
      col.G3.alias("passes"))

nbText: """
and only the grades of good marks (13 or more) among students who missed more classes than
average in their age group:
"""

tabs """
(
    math_students.group_by("age").agg(
        passes=pl.col("G3").filter(
            pl.col("absences") > pl.col("absences").mean(), pl.col("G3") >= 13
        )
    )
)
""":
  nbCode:
    nbShow mathStudents.groupBy("age").agg(
      col.G3.filter(
        col.absences > col.absences.mean and col.G3 >= 13).alias("passes"))

nanuq """
Python's `Expr.filter` takes several predicates and joins them with *and*; Nanuq's takes one,
so the Nim tab joins them itself.
"""

nbText: """
Counting them instead, and the share they are of all the poor attenders:
"""

tabs """
(
    math_students.group_by("age")
    .agg(
        passes=pl.col("G3")
        .filter(
            pl.col("absences") > pl.col("absences").mean(), pl.col("G3") >= 13
        )
        .count(),
        poor_attenders=pl.col("G3")
        .filter(pl.col("absences") > pl.col("absences").mean())
        .count(),
    )
    .select(
        pl.col("age", "passes", "poor_attenders"),
        percentage=pl.col("passes") / pl.col("poor_attenders") * 100,
    )
    .with_columns(pl.col("percentage").replace(float("NaN"), 0))
    .sort("age")
)
""":
  nbCode:
    nbShow mathStudents.groupBy("age")
      .agg(
        col.G3
          .filter(col.absences > col.absences.mean and col.G3 >= 13)
          .count.alias("passes"),
        col.G3
          .filter(col.absences > col.absences.mean)
          .count.alias("poor_attenders"))
      .select(
        col("age", "passes", "poor_attenders"),
        (col.passes / col.poor_attenders * 100).alias("percentage"))
      .withColumns(col.percentage.replace(NaN, 0.0))
      .sort("age")

nbText: """
## Grouping by several columns

By course and by the reason the student gave for choosing the school, sorted in three ways:
"""

tabs """
(
    all_students.group_by(["subject", "reason"])
    .agg(
        min=pl.col("absences").min(),
        max=pl.col("absences").max(),
        mean=pl.col("absences").mean(),
    )
    .sort("subject", "reason")
)
""":
  nbCode:
    let byReason = allStudents.groupBy("subject", "reason")
      .agg(
        col.absences.min.alias("min"),
        col.absences.max.alias("max"),
        col.absences.mean.alias("mean"))
    nbShow byReason.sort(["subject", "reason"])

tabs """
(
    all_students.group_by(["subject", "reason"])
    .agg(
        min=pl.col("absences").min(),
        max=pl.col("absences").max(),
        mean=pl.col("absences").mean(),
    )
    .sort("reason", descending=True)
    .sort("subject")
)
""":
  nbCode:
    nbShow byReason.sort("reason", descending = true).sort("subject", maintainOrder = true)

nanuq """
The tutorial also sorts by `subject` alone first, which leaves the order of the reasons to
chance; the port starts from the two-key sort. In the last cell, a second sort only keeps the
first one's order within each subject if it is stable: Python's `sort` does not promise that
unless asked (`maintain_order=True`), so the Nim tab asks with `maintainOrder = true`.
"""

nbText: """
## Grouping by time

`math_classes.parquet` has the absences at each class:
"""

tabs """
math_attendance = pl.read_parquet("data/real-python/math_classes.parquet")
math_attendance.head()
""":
  nbCode:
    let mathAttendance = readParquet("data/real-python/math_classes.parquet")
    nbShow mathAttendance.head

nbText: """
Totals and means per week, and per quarter and subject:
"""

tabs """
(
    math_attendance.group_by_dynamic(
        index_column="class_start", every="1w", closed="both"
    ).agg(
        total_absences=pl.col("absences").sum(),
        mean_absences=pl.col("absences").mean(),
    )
)
""":
  nbCode:
    nbShow mathAttendance.groupByDynamic(
        indexColumn = "class_start", every = "1w", closed = ClosedWindow.Both
      ).agg(
        col.absences.sum.alias("total_absences"),
        col.absences.mean.alias("mean_absences"))

tabs """
(
    math_attendance.group_by_dynamic(
        index_column="class_start",
        every="1q",
        closed="both",
        group_by="class_subject",
    ).agg(pl.col("absences").sum())
)
""":
  nbCode:
    nbShow mathAttendance.groupByDynamic(
        indexColumn = "class_start",
        every = "1q",
        closed = ClosedWindow.Both,
        groupBy = "class_subject"
      ).agg(col.absences.sum)

nbText: """
## Window functions

The mean absences of each student's group, next to their own, and then only the students above
it:
"""

tabs """
all_students.select(
    pl.col("subject", "school", "student_id", "reason", "absences"),
    mean_absences=(
        pl.col("absences").mean().over("subject", "school", "reason")
    ),
).filter(pl.col("absences") > pl.col("mean_absences"))
""":
  nbCode:
    nbShow allStudents.select(
      col("subject", "school", "student_id", "reason", "absences"),
      col.absences.mean.over("subject", "school", "reason").alias("mean_absences")
    ).filter(col.absences > col.mean_absences)

nbText: """
## Pivot tables

Means by course and school, first as a group-by, then as a pivot with one column per school:
"""

tabs """
(
    all_students.group_by(["subject", "school"]).agg(
        mean_absence=pl.col("absences").mean(),
        mean_failure=pl.col("failures").mean(),
    )
)
""":
  nbCode:
    nbShow allStudents.groupBy("subject", "school").agg(
      col.absences.mean.alias("mean_absence"),
      col.failures.mean.alias("mean_failure"))

tabs """
(
    all_students.pivot(
        on="school",
        index=["subject", "reason"],
        values=["absences", "failures"],
        aggregate_function="mean",
    ).select(
        pl.col(
            "subject",
            "reason",
            "absences_GP",
            "failures_GP",
            "absences_MS",
            "failures_MS",
        ),
    )
)
""":
  nbCode:
    nbShow allStudents.pivot(
        on = "school",
        index = ["subject", "reason"],
        values = ["absences", "failures"],
        aggregateFunction = PivotAgg.Mean
      ).select(
        col(["subject", "reason",
             "absences_GP", "failures_GP", "absences_MS", "failures_MS"]))

bookSave()
