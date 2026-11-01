import nanuqbook
bookInit()

nbText: "# Categorical data and enums"

attribution userGuide("Categorical data and enums", "expressions/categorical-data-and-enums",
  "The Series of the original become one-column frames (both sides), the error examples " &
  "print the error type only, and the comparison of an Enum column with a string Series " &
  "uses two columns of one frame. Left out: `pl.Categories` objects and `Series.extend`, " &
  "which Nanuq does not have.")

nbText: """
String values that can only take on a limited number of possible values are known as
[categorical data](https://en.wikipedia.org/wiki/Categorical_variable). Usually, the number
of possible values is much smaller than the number of rows. Some typical examples include
your nationality, the operating system of your computer, or the license that your favorite
open source project uses.

When working with categorical data you can use Polars' dedicated types, `Categorical` and
`Enum`, to make your queries more performant. On this page, we will show what the
differences are between the two data types `Categorical` and `Enum` and when to use one or
the other. We also include some notes on
[why the data types `Categorical` and `Enum` are more efficient than using the plain string values](#performance-considerations-on-categorical-data-types)
at the end of this user guide section.

In short, from a performance perspective, prefer `Enum` over `Categorical` whenever
possible. In case your requirements change along the way, you can always cast from one to
the other.

## `Enum` vs `Categorical`

`Enum` and `Categorical` have a few key differences. The categories of an `Enum` are fixed,
defined up front, and can be ordered. When categories are not yet known up front or grow
dynamically, you can use `Categorical`, but then they cannot be ordered.

## Data type `Enum`

### Creating an `Enum`

The data type `Enum` is an ordered categorical data type. To use the data type `Enum` you
must specify the categories in advance to create it. Then, when creating a new series, a new
dataframe, or when casting a string column, you can use that `Enum` variant.
"""

nanuq """
A Polars Enum is a Nim enum: its categories are the enum's values, in order (their string
values, if they have them). Nim knows the categories at compile time, so a column of
`Bear` values can only hold bears.
"""

tabs """
import polars as pl

bears_enum = pl.Enum(["Polar", "Panda", "Brown"])
bears = pl.Series("bears", ["Polar", "Panda", "Brown", "Brown", "Polar"], dtype=bears_enum)
bears.to_frame()
""":
  nbCode:
    import nanuq

    type Bear = enum Polar, Panda, Brown

    let bears = newDataFrame:
      bears: [Polar, Panda, Brown, Brown, Polar]
    nbShow bears

nbText: """
### Invalid values

Polars will raise an error if you try to specify a data type `Enum` whose categories do not
include all the values present:
"""

tabs """
from polars.exceptions import InvalidOperationError

try:
    bears_kind_of = pl.Series(
        ["Polar", "Panda", "Brown", "Polar", "Shark"],
        dtype=bears_enum,
    )
except InvalidOperationError as exc:
    print("InvalidOperationError")
""":
  nbCode:
    let kindOf = newDataFrame:
      bears: ["Polar", "Panda", "Brown", "Polar", "Shark"]
    try:
      discard kindOf.select(col.bears.cast(Bear))
    except InvalidOperationError:
      echo "InvalidOperationError"

nanuq """
With Nim enum values a shark does not even compile, so the Nim side casts strings to `Bear`,
which fails in the same way when the query runs.
"""

nbText: """
If you can't know all of the possible values in advance and erroring on unknown values is
semantically wrong, you may need to [use the data type `Categorical`](#data-type-categorical).

### Category ordering and comparison

The data type `Enum` is ordered and the order is determined by the order in which you
specify the categories. The snippet below uses log levels to demonstrate where an ordered
`Enum` is useful:
"""

tabs """
log_levels = pl.Enum(["debug", "info", "warning", "error"])

logs = pl.DataFrame(
    {
        "level": ["debug", "info", "debug", "error"],
        "message": [
            "process id: 525",
            "Service started correctly",
            "startup time: 67ms",
            "Cannot connect to DB!",
        ],
    },
    schema_overrides={
        "level": log_levels,
    },
)

non_debug_logs = logs.filter(
    pl.col("level") > "debug",
)
non_debug_logs
""":
  nbCode:
    let logLevels = Enum(["debug", "info", "warning", "error"])

    let logs = newDataFrame(
        series("level", ["debug", "info", "debug", "error"]),
        series("message", ["process id: 525", "Service started correctly",
                           "startup time: 67ms", "Cannot connect to DB!"]))
      .cast({"level": logLevels})

    let nonDebugLogs = logs.filter(col.level > "debug")
    nbShow nonDebugLogs

nanuq """
`Enum([...])` builds an Enum data type at run time, from strings, for categories that a Nim
enum can't hold (here `error`, which would clash with Nim's own `error`).
"""

nbText: """
This example shows that we can compare `Enum` values with a string, but this only works if
the string matches one of the `Enum` values. If we compared the column “level” with any
string other than `"debug"`, `"info"`, `"warning"`, or `"error"`, Polars would raise an
exception:
"""

tabs """
try:
    logs.select(pl.col("level") > "Pretty bad")
except InvalidOperationError as err:
    print("InvalidOperationError")
""":
  nbCode:
    try:
      discard logs.select(col.level > "Pretty bad")
    except InvalidOperationError:
      echo "InvalidOperationError"

nbText: """
Columns of the `Enum` data type can be compared with other columns of the same `Enum` type
or columns that hold strings, but only if all the strings are valid `Enum` values.
"""

tabs """
logs.with_columns(
    pl.Series("str", ["info", "debug", "debug", "error"])
).select(pl.col("level") == pl.col("str"))
""":
  nbCode:
    nbShow concat([logs, newDataFrame(series("str", ["info", "debug", "debug", "error"]))],
                  how = Horizontal)
      .select(col.level == col.str)

nbText: """
## Data type `Categorical`

The data type `Categorical` can be seen as a more flexible version of `Enum`. The
categories don't need to be defined up front, since the mapping grows dynamically as data is
processed.

### Creating a `Categorical` `Series`

To use the data type `Categorical`, you can cast a column of strings or specify
`Categorical` as the data type of a series or dataframe column:
"""

tabs """
bears_cat = pl.Series(
    "bears", ["Polar", "Panda", "Brown", "Brown", "Polar"], dtype=pl.Categorical
)
bears_cat.to_frame()
""":
  nbCode:
    let bearsCat = newDataFrame(series("bears", ["Polar", "Panda", "Brown", "Brown", "Polar"]))
      .select(col.bears.cast(Categorical))
    nbShow bearsCat

nbText: """
Having Polars infer the categories for you may seem easier than listing the categories
beforehand, but this continuous inference and bookkeeping comes at a performance cost. That
is why, whenever possible, you should use `Enum`. You can learn why by
[reading the subsection about `Categorical` encodings](#data-type-categorical-and-encodings).
"""

nanuq """
The guide's next section, on `pl.Categories` objects (named mappings with a chosen physical
type), is left out: Nanuq's `Categorical` always uses the global mapping.
"""

nbText: """
### Lexical comparison with strings

When comparing a `Categorical` column with a string, Polars will perform a lexical
comparison. In the context of strings this means which one comes first in an alphabetical
ordering.
"""

tabs """
pl.DataFrame({"categorical": bears_cat}).with_columns(
    (pl.col("categorical") < "Cat").alias('categorical < "Cat"')
)
""":
  nbCode:
    nbShow bearsCat.select(col.bears.alias("categorical"))
      .withColumns((col.categorical < "Cat").alias("categorical < \"Cat\""))

nbText: """
You can also compare a column of strings with your `Categorical` column, and the comparison
will also be lexical:
"""

tabs """
pl.DataFrame(
    {
        "categorical": bears_cat,
        "string": pl.Series(["Panda", "Brown", "Brown", "Polar", "Polar"]),
    }
).with_columns(
    (pl.col("categorical") == pl.col("string")).alias("categorical == string"),
)
""":
  nbCode:
    let both = newDataFrame(
        series("categorical", ["Polar", "Panda", "Brown", "Brown", "Polar"]),
        series("string", ["Panda", "Brown", "Brown", "Polar", "Polar"]))
      .withColumns(col.categorical.cast(Categorical))
    nbShow both.withColumns((col.categorical == col("string")).alias("categorical == string"))

nbText: """
Although it is possible to compare a string column with a categorical column, it is
typically more efficient to compare two categorical columns directly. Comparing two
`Categorical` columns always performs a lexical comparison.

### Combining `Categorical` columns

Because `Categorical` columns share a global mapping by default, combining them (e.g.
[concatenating two dataframes vertically](getting_started.html#concatenating-dataframes))
requires no re-encoding:
"""

tabs """
male_bears = pl.DataFrame(
    {
        "species": ["Polar", "Brown", "Panda"],
        "weight": [450, 500, 110],  # kg
    },
    schema_overrides={"species": pl.Categorical},
)
female_bears = pl.DataFrame(
    {
        "species": ["Brown", "Polar", "Panda"],
        "weight": [340, 200, 90],  # kg
    },
    schema_overrides={"species": pl.Categorical},
)
bears = pl.concat([male_bears, female_bears], how="vertical")
bears
""":
  nbCode:
    let maleBears = newDataFrame(
        series("species", ["Polar", "Brown", "Panda"]),
        series("weight", [450, 500, 110]))  # kg
      .cast({"species": Categorical})
    let femaleBears = newDataFrame(
        series("species", ["Brown", "Polar", "Panda"]),
        series("weight", [340, 200, 90]))  # kg
      .cast({"species": Categorical})
    nbShow concat([maleBears, femaleBears], how = Vertical)

nbText: """
The same holds when using explicit `pl.Categories` objects: two `Categorical` columns can be
combined without re-encoding as long as they share the same `Categories`. For a deeper look
at how encodings work, see [the performance section below](#data-type-categorical-and-encodings).
"""

nanuq """
The physical encoding of a categorical column is `toPhysical`, and its categories are
`cat.getCategories`, as in Rust Polars (Python Polars 2 removed `cat.get_categories`, so
the Python side reads the categories from the dtype). A Nim enum's categories are all of
its values, also those the column does not hold:
"""

tabs """
pl.DataFrame({"bears": bears_enum.categories})
""":
  nbCode:
    let polarOnly = newDataFrame:
      bears: [Polar, Polar]
    nbShow polarOnly.select(col.bears.cat.getCategories)

nbText: """
## Performance considerations on categorical data types

This part of the user guide explains why categorical data types are more performant than plain
string literals.

### Encodings

Categorical data represents string data with a finite set of possible values (that is usually much
smaller than the length of the column). Storing these values as plain strings wastes memory and
costs performance as the same string will be repeated over and over again. Additionally, operations
like joins require expensive string comparisons.

Categorical data types like `Enum` and `Categorical` represent string literals as inexpensive
numeric placeholders that are mapped to the original string literal.

As an example of a sensible encoding, Polars could choose to represent the finite set of categories
as unsigned integers. With that in mind, the diagram below shows a regular string column and a
possible representation of a Polars column with the categorical data type:

<table>
<tr><th>String Column </th><th>Categorical Column</th></tr>
<tr><td>
<table>
    <thead>
        <tr>
            <th>Series</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Polar</td>
        </tr>
        <tr>
            <td>Panda</td>
        </tr>
        <tr>
            <td>Brown</td>
        </tr>
        <tr>
            <td>Panda</td>
        </tr>
        <tr>
            <td>Brown</td>
        </tr>
        <tr>
            <td>Brown</td>
        </tr>
        <tr>
            <td>Polar</td>
        </tr>
    </tbody>
</table>
</td>
<td>
<table>
<tr>
<td>

<table>
    <thead>
        <tr>
            <th>Physical</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>0</td>
        </tr>
        <tr>
            <td>1</td>
        </tr>
        <tr>
            <td>2</td>
        </tr>
        <tr>
            <td>1</td>
        </tr>
        <tr>
            <td>2</td>
        </tr>
        <tr>
            <td>2</td>
        </tr>
        <tr>
            <td>0</td>
        </tr>
    </tbody>
</table>

</td>
<td>
<table>
    <thead>
        <tr>
            <th>Categories</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Polar</td>
        </tr>
        <tr>
            <td>Panda</td>
        </tr>
        <tr>
            <td>Brown</td>
        </tr>
    </tbody>
</table>
</td>
</tr>
</table>
</td>
</tr>
</table>

The physical representation `0` in this case encodes (or maps) to the value `Polar`, the value `1`
encodes to `Panda`, and the value `2` to `Brown`. This encoding has the benefit of only storing the
string values once. Additionally, when we perform operations (e.g. sorting, counting) we can work
directly on the physical representation which is much faster than working with string data.

### Encodings for the data type `Enum` are fixed

When working with the data type `Enum` we specify the categories in advance. This way, Polars can
ensure different columns and even different datasets have the same encoding. Because of this, there
is no need for expensive re-encoding or cache lookups.

### Data type `Categorical` and encodings

The fact that the categories for the data type `Categorical` are inferred comes at a cost. The main
cost here is that we have no control over the order in which these encodings are built.

Consider appending the following two categorical series:


Polars encodes the string values in the order they appear. So, the series would look like this:

<table>
<tr><th>cat_series </th><th>cat2_series</th></tr>
<tr><td>
<table>
<tr>
<td>
<table>
    <thead>
        <tr>
            <th>Physical</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>0</td>
        </tr>
        <tr>
            <td>1</td>
        </tr>
        <tr>
            <td>2</td>
        </tr>
        <tr>
            <td>2</td>
        </tr>
        <tr>
            <td>0</td>
        </tr>
    </tbody>
</table>

</td>
<td>
<table>
    <thead>
        <tr>
            <th>Categories</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Polar</td>
        </tr>
        <tr>
            <td>Panda</td>
        </tr>
        <tr>
            <td>Brown</td>
        </tr>
    </tbody>
</table>

</td>
</tr>
</table>
</td>
<td>
<table>
<tr>
<td>
<table>
    <thead>
        <tr>
            <th>Physical</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>0</td>
        </tr>
        <tr>
            <td>1</td>
        </tr>
        <tr>
            <td>1</td>
        </tr>
        <tr>
            <td>2</td>
        </tr>
        <tr>
            <td>2</td>
        </tr>
    </tbody>
</table>

</td>
<td>

<table>
    <thead>
        <tr>
            <th>Categories</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>Panda</td>
        </tr>
        <tr>
            <td>Brown</td>
        </tr>
        <tr>
            <td>Polar</td>
        </tr>
    </tbody>
</table>

</td>
</tr>
</table>
</td>
</tr>
</table>

Polars avoids this problem by using a shared global mapping for all `Categorical` columns by
default: the same string always gets the same physical value across columns, making combination
operations cheap. When you need multiple independent category spaces, use
[explicit `pl.Categories` objects](#using-categories-objects) scoped by name and namespace; columns
sharing the same `Categories` are always compatible with each other. This comes at the cost of
lookups and edits to the global mapping, which can cause locking. This does not occur for the `Enum`
because the mapping is immutable and can be shared freely.
"""

nanuq """
The guide shows the encoding problem by appending two categorical Series; Nanuq has no
`Series.extend`, so that code is left out.
"""

bookSave()
