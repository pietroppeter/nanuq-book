import nanuqbook
bookInit()

nbText: "# Data types and structures"

attribution userGuide("Data types and structures", "concepts/data-types-and-structures",
  "Frames are shown as tables instead of printed, except for `sample`. The full data " &
  "types table of the appendix is left out; the Nanuq names are in the box below it.")

nbText: """
## Data types

Polars supports a variety of data types that fall broadly under the following categories:

- Numeric data types: signed integers, unsigned integers, floating point numbers, and
  decimals.
- Nested data types: lists, structs, arrays, and maps.
- Temporal: dates, datetimes, times, and time deltas.
- Miscellaneous: strings, binary data, Booleans, categoricals, enums, and objects.

All types support missing values represented by the special value `null`. This is not to be
conflated with the special value `NaN` in floating number data types; see the section about
floating point numbers below for more information.
"""

nanuq """
Nanuq 0.5 has the numeric types without `Decimal`, `Int128`, `UInt128` and `Float16`, the
nested types without `Map`, the temporal types, strings, Booleans, categoricals and enums.
Binary and decimals are planned for 0.6; `Object` (arbitrary Python objects) has no Nim
counterpart.
"""

nbText: """
## Series

The core base data structures provided by Polars are series and dataframes. A series is a
1-dimensional homogeneous data structure. By “homogeneous” we mean that all elements inside
a series have the same data type. The snippet below shows how to create a named series:
"""

tabs """
import polars as pl

s = pl.Series("ints", [1, 2, 3, 4, 5])
print(s)
""":
  nbCode:
    import nanuq

    let s = series("ints", [1, 2, 3, 4, 5])
    echo s

nbText: """
When creating a series, Polars will infer the data type from the values you provide. You
can specify a concrete data type to override the inference mechanism:
"""

tabs """
s1 = pl.Series("ints", [1, 2, 3, 4, 5])
s2 = pl.Series("uints", [1, 2, 3, 4, 5], dtype=pl.UInt64)
print(s1.dtype, s2.dtype)
""":
  nbCode:
    let s1 = series("ints", [1, 2, 3, 4, 5])
    let s2 = series("uints", [1'u64, 2, 3, 4, 5])
    echo s1.dtype, " ", s2.dtype

nanuq """
In Nim the data type follows from the type of the values: `1'u64` makes the array an
`array[5, uint64]`, and the series a `UInt64` series.
"""

nbText: """
## Dataframe

A dataframe is a 2-dimensional heterogeneous data structure that contains uniquely named
series. By holding your data in a dataframe you will be able to use the Polars API to write
queries that manipulate your data. You will be able to do this by using the
[contexts and expressions provided by Polars](expressions_and_contexts.html) that we will
talk about next.

The snippet below shows how to create a dataframe from a dictionary of lists:
"""

tabs """
from datetime import date

df = pl.DataFrame(
    {
        "name": ["Alice Archer", "Ben Brown", "Chloe Cooper", "Daniel Donovan"],
        "birthdate": [
            date(1997, 1, 10),
            date(1985, 2, 15),
            date(1983, 3, 22),
            date(1981, 4, 30),
        ],
        "weight": [57.9, 72.5, 53.6, 83.1],  # (kg)
        "height": [1.56, 1.77, 1.65, 1.75],  # (m)
    }
)

df
""":
  nbCode:
    var df = newDataFrame:
      name: ["Alice Archer", "Ben Brown", "Chloe Cooper", "Daniel Donovan"]
      birthdate: [date(1997, 1, 10), date(1985, 2, 15), date(1983, 3, 22), date(1981, 4, 30)]
      weight: [57.9, 72.5, 53.6, 83.1]  # (kg)
      height: [1.56, 1.77, 1.65, 1.75]  # (m)

    nbShow df

nbText: """
### Inspecting a dataframe

In this subsection we will show some useful methods to quickly inspect a dataframe. We will
use the dataframe we created earlier as a starting point.

#### Head

The function `head` shows the first rows of a dataframe. By default, you get the first 5
rows but you can also specify the number of rows you want:
"""

tabs """
df.head(3)
""":
  nbCode:
    nbShow df.head(3)

nbText: """
#### Glimpse

The function `glimpse` is another function that shows the values of the first few rows of a
dataframe, but formats the output differently from `head`. Here, each line of the output
corresponds to a single column, making it easier to inspect wider dataframes:
"""

tabs """
print(df.glimpse(return_type="string"))
""":
  nbCode:
    echo df.glimpse

nanuq """
The user guide says `glimpse` is only available for Python users. Nanuq has it too; it
returns the string.
"""

nbText: """
#### Tail

The function `tail` shows the last rows of a dataframe. By default, you get the last 5 rows
but you can also specify the number of rows you want, similar to how `head` works:
"""

tabs """
df.tail(3)
""":
  nbCode:
    nbShow df.tail(3)

nbText: """
#### Sample

If you think the first or last rows of your dataframe are not representative of your data,
you can use `sample` to get an arbitrary number of randomly selected rows from the
DataFrame. Note that the rows are not necessarily returned in the same order as they appear
in the dataframe:
"""

tabs """
pl.set_random_seed(42)  # For reproducibility.

df.sample(2)
""":
  nbCode:
    setRandomSeed(42)  # For reproducibility.

    nbShow df.sample(2)

nbText: """
#### Describe

You can also use `describe` to compute summary statistics for all columns of your
dataframe:
"""

tabs """
df.describe()
""":
  nbCode:
    nbShow df.describe()

nbText: """
## Schema

When talking about data (in a dataframe or otherwise) we can refer to its schema. The
schema is a mapping of column or series names to the data types of those same columns or
series.

You can check the schema of a dataframe with `schema`:
"""

tabs """
print(df.schema)
""":
  nbCode:
    echo df.schema

nbText: """
Much like with series, Polars will infer the schema of a dataframe when you create it but
you can override the inference system if needed.

In Python, you can specify an explicit schema by using a dictionary to map column names to
data types. You can use the value `None` if you do not wish to override inference for a
given column:
"""

tabs """
df = pl.DataFrame(
    {
        "name": ["Alice", "Ben", "Chloe", "Daniel"],
        "age": [27, 39, 41, 43],
    },
    schema={"name": None, "age": pl.UInt8},
)

df
""":
  nbCode:
    df = newDataFrame:
      name: ["Alice", "Ben", "Chloe", "Daniel"]
      age: [27'u8, 39, 41, 43]

    nbShow df

nbText: """
If you only need to override the inference of some columns, the parameter
`schema_overrides` tends to be more convenient because it lets you omit columns for which
you do not want to override the inference:
"""

tabs """
df = pl.DataFrame(
    {
        "name": ["Alice", "Ben", "Chloe", "Daniel"],
        "age": [27, 39, 41, 43],
    },
    schema_overrides={"age": pl.UInt8},
)

df
""":
  nbCode:
    df = newDataFrame:
      name: ["Alice", "Ben", "Chloe", "Daniel"]
      age: [27, 39, 41, 43]
    df = df.cast({"age": UInt8})

    nbShow df

nanuq """
Nanuq's frame constructors take no schema: the Nim types of the values decide (`27'u8`), or
a `cast` afterwards.
"""

nbText: """
## Data types internals

Polars utilizes the [Arrow Columnar Format](https://arrow.apache.org/docs/format/Columnar.html)
for its data orientation. Following this specification allows Polars to transfer data
to/from other tools that also use the Arrow specification with little to no overhead.

Polars gets most of its performance from its query engine, the optimizations it performs on
your query plans, and from the parallelization that it employs when running
[your expressions](expressions_and_contexts.html).

## Floating point numbers

Polars generally follows the IEEE 754 floating point standard for `Float32` and `Float64`,
with some exceptions:

- Any `NaN` compares equal to any other `NaN`, and greater than any non-`NaN` value.
- Operations do not guarantee any particular behavior on the sign of zero or `NaN`, nor on
  the payload of `NaN` values. This is not just limited to arithmetic operations, e.g. a
  sort or group by operation may canonicalize all zeroes to +0 and all `NaN`s to a positive
  `NaN` without payload for efficient equality checks.

Polars always attempts to provide reasonably accurate results for floating point
computations but does not provide guarantees on the error unless mentioned otherwise.
Generally speaking 100% accurate results are infeasibly expensive to achieve (requiring much
larger internal representations than 64-bit floats), and thus some error is always to be
expected.
"""

bookSave()
