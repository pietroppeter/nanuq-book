import nanuqbook
bookInit()

nbText: "# Data structures and data types"

attribution definitiveGuide(4, "Data Structures and Data Types",
  "Data is read from `data/definitive-guide/`. Left out: `show_graph` (it draws the plan " &
  "with Graphviz; Nanuq has `explain`).")

nbText: """
Polars has three data structures: the Series, a column of values of one type; the
DataFrame, columns of the same length; and the LazyFrame, a DataFrame still to compute.
Nanuq has the same three.

## Series, DataFrames, and LazyFrames
"""

tabs """
import polars as pl

sales_series = pl.Series("sales", [150.00, 300.00, 250.00])

sales_series
""":
  nbCode:
    import nanuq

    let salesSeries = series("sales", [150.00, 300.00, 250.00])

    nbShow salesSeries

tabs """
sales_df = pl.DataFrame(
    {
        "sales": sales_series,
        "customer_id": [24, 25, 26],
    }
)

sales_df
""":
  nbCode:
    let salesDf = newDataFrame(
      salesSeries,
      series("customer_id", [24, 25, 26]))

    nbShow salesDf

tabs """
lazy_df = pl.scan_csv("data/definitive-guide/fruit.csv").with_columns(
    is_heavy=pl.col("weight") > 200
)

print(lazy_df.explain())
""":
  nbCode:
    let lazyDf = scanCsv("data/definitive-guide/fruit.csv").withColumns(
      (col.weight > 200).alias("is_heavy"))

    echo lazyDf.explain

nanuq """
The book draws the plan with `show_graph`, which needs Graphviz; both sides print it with
`explain` instead.
"""

nbText: """
## Data Types

### Nested Data Types

Arrays hold the same number of values in every row:
"""

tabs """
coordinates = pl.DataFrame(
    [
        pl.Series("point_2d", [[1, 3], [2, 5]]),
        pl.Series("point_3d", [[1, 7, 3], [8, 1, 0]]),
    ],
    schema={
        "point_2d": pl.Array(shape=2, inner=pl.Int64),
        "point_3d": pl.Array(shape=3, inner=pl.Int64),
    },
)

coordinates
""":
  nbCode:
    let coordinates = newDataFrame(
      series("point_2d", [[1, 3], [2, 5]]),
      series("point_3d", [[1, 7, 3], [8, 1, 0]]))

    nbShow coordinates

nanuq """
No schema needed: Nim arrays (`[1, 3]`, an `array[2, int]`) give `Array` columns, seqs
(`@[1, 3]`) give `List` columns.
"""

nbText: "Lists can have a different length in every row:"

tabs """
weather_readings = pl.DataFrame(
    {
        "temperature": [[72.5, 75.0, 77.3], [68.0, 70.2]],
        "wind_speed": [[15, 20], [10, 12, 14, 16]],
    }
)

weather_readings
""":
  nbCode:
    let weatherReadings = newDataFrame:
      temperature: [@[72.5, 75.0, 77.3], @[68.0, 70.2]]
      wind_speed: [@[15, 20], @[10, 12, 14, 16]]

    nbShow weatherReadings

nbText: "Structs hold named fields, here built from Python dictionaries and Nim named tuples:"

tabs """
rating_series = pl.Series(
    "ratings",
    [
        {"Movie": "Cars", "Theatre": "NE", "Avg_Rating": 4.5},
        {"Movie": "Toy Story", "Theatre": "ME", "Avg_Rating": 4.9},
    ],
)
rating_series
""":
  nbCode:
    let ratingSeries = series("ratings", [
      (Movie: "Cars", Theatre: "NE", Avg_Rating: 4.5),
      (Movie: "Toy Story", Theatre: "ME", Avg_Rating: 4.9)])
    nbShow ratingSeries

nbText: """
### Missing Values

Any column can hold missing values, `null`:
"""

tabs """
missing_df = pl.DataFrame(
    {
        "value": [None, 2, 3, 4, None, None, 7, 8, 9, None],
    },
)
missing_df
""":
  nbCode:
    let missingDf = newDataFrame:
      value: [nil, 2, 3, 4, nil, nil, 7, 8, 9, nil]
    nbShow missingDf

tabs """
missing_df.with_columns(filled_with_single=pl.col("value").fill_null(-1))
""":
  nbCode:
    nbShow missingDf.withColumns(col.value.fillNull(-1).alias("filled_with_single"))

tabs """
missing_df.with_columns(
    forward=pl.col("value").fill_null(strategy="forward"),
    backward=pl.col("value").fill_null(strategy="backward"),
    min=pl.col("value").fill_null(strategy="min"),
    max=pl.col("value").fill_null(strategy="max"),
    mean=pl.col("value").fill_null(strategy="mean"),
    zero=pl.col("value").fill_null(strategy="zero"),
    one=pl.col("value").fill_null(strategy="one"),
)
""":
  nbCode:
    nbShow missingDf.withColumns(
      col.value.fillNull(Forward).alias("forward"),
      col.value.fillNull(Backward).alias("backward"),
      col.value.fillNull(FillNullStrategy.Min).alias("min"),
      col.value.fillNull(FillNullStrategy.Max).alias("max"),
      col.value.fillNull(FillNullStrategy.Mean).alias("mean"),
      col.value.fillNull(Zero).alias("zero"),
      col.value.fillNull(One).alias("one"))

nanuq """
The strategies are an enum, `FillNullStrategy`. `Min`, `Max` and `Mean` need its name in
front, since `min`, `max` and `mean` are also procs.
"""

tabs """
missing_df.with_columns(
    expression_mean=pl.col("value").fill_null(pl.col("value").mean())
)
""":
  nbCode:
    nbShow missingDf.withColumns(
      col.value.fillNull(col.value.mean).alias("expression_mean"))

tabs """
missing_df.interpolate()
""":
  nbCode:
    nbShow missingDf.interpolate

nbText: """
## Data Type Conversion

A smaller type takes less memory: the same ids as strings and as 16-bit integers.
"""

tabs """
string_df = pl.DataFrame({"id": ["10000", "20000", "30000"]})
print(string_df)
print(f"Estimated size: {string_df.estimated_size('b')} bytes")
""":
  nbCode:
    let stringDf = newDataFrame:
      id: ["10000", "20000", "30000"]
    echo stringDf
    echo "Estimated size: ", stringDf.estimatedSize, " bytes"

tabs """
int_df = string_df.select(pl.col("id").cast(pl.UInt16))
print(int_df)
print(f"Estimated size: {int_df.estimated_size('b')} bytes")
""":
  nbCode:
    let intDf = stringDf.select(col.id.cast(UInt16))
    echo intDf
    echo "Estimated size: ", intDf.estimatedSize, " bytes"

nbText: "`cast` on a frame converts all columns, or the ones named in a mapping:"

tabs """
data_types_df = pl.DataFrame(
    {
        "id": [10000, 20000, 30000],
        "value": [1.0, 2.0, 3.0],
        "value2": ["1", "2", "3"],
    }
)

data_types_df.cast(pl.UInt16)
""":
  nbCode:
    let dataTypesDf = newDataFrame:
      id: [10000, 20000, 30000]
      value: [1.0, 2.0, 3.0]
      value2: ["1", "2", "3"]

    nbShow dataTypesDf.cast(UInt16)

tabs """
data_types_df.cast({"id": pl.UInt16, "value": pl.Float32, "value2": pl.UInt8})
""":
  nbCode:
    nbShow dataTypesDf.cast({"id": UInt16, "value": Float32, "value2": UInt8})

tabs """
data_types_df.cast({pl.Float64: pl.Float32, pl.String: pl.UInt8})
""":
  nbCode:
    nbShow dataTypesDf.cast({Float64: Float32, String: UInt8})

tabs """
import polars.selectors as cs

data_types_df.cast({cs.numeric(): pl.UInt16})
""":
  nbCode:
    nbShow dataTypesDf.cast({col(SomeNumber): UInt16})

nanuq """
The keys of one mapping are all of a kind: column names, data types, or selectors such as
`col(SomeNumber)` (Nim's type class for numbers, Python's `cs.numeric()`).
"""

bookSave()
