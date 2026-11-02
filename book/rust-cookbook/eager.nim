import nanuqbook
bookInit()

nbText: "# Eager cookbook"

attribution rustCookbook("Polars Eager cookbook", "eager.rs",
  "The Rust code is shown as it is, in a third tab, and is not run: the book never " &
  "builds Rust. The Nim port and a Python version (the Nanuq book's own) run and are " &
  "compared, so where the Rust only computes values the ports end by showing some of them. " &
  "The IO examples write to a temporary directory, and the filter example reads " &
  "`data/polars/iris.csv`.")

nbText: """
This page should serve as a cookbook to quickly get you started with most fundamental
operations executed on a `ChunkedArray`, `Series` or `DataFrame`.
"""

nanuq """
A `ChunkedArray<T>` is the typed column inside a Rust `Series`: Rust code downcasts a
`Series` to it (`s.i32()?`) to get at values of a known type. Nanuq, like Python, has no
such layer. A Nanuq `Series` keeps its data type at run time, and typed access is a call
away: `s.toList(int)`, `s[2, float]`, `s.view(float)`. So the ChunkedArray recipes below are
ported with plain `Series`.
"""

nbText: """
## Creation of data structures

### ChunkedArray
"""

rustTabs """
use polars::prelude::*;

// use iterators
let ca: UInt32Chunked = (0..10).map(Some).collect();

// from slices
let ca = UInt32Chunked::new("foo".into(), &[1, 2, 3]);

// use builders
let mut builder = PrimitiveChunkedBuilder::<UInt32Type>::new("foo".into(), 10);
for value in 0..10 {
    builder.append_value(value);
}
let ca = builder.finish();
""", """
import polars as pl

# use iterators
ca = pl.Series(range(10), dtype=pl.UInt32)

# from slices
ca = pl.Series("foo", [1, 2, 3], dtype=pl.UInt32)

# use builders
values = []
for value in range(10):
    values.append(value)
ca = pl.Series("foo", values, dtype=pl.UInt32)
ca.to_frame().head(3)
""":
  nbCode:
    import std/[sequtils, os]
    import nanuq

    # use iterators
    var ca = series("", toSeq(0'u32 ..< 10'u32))

    # from slices
    ca = series("foo", [1'u32, 2, 3])

    # use builders
    var values: seq[uint32]
    for value in 0'u32 ..< 10'u32:
      values.add value
    ca = series("foo", values)
    nbShow ca.toFrame.head(3)

nbText: "### Series"

rustTabs """
use polars::prelude::*;

// use iterators
let s: Series = (0..10).map(Some).collect();

// from slices
let s = Series::new("foo".into(), &[1, 2, 3]);

// from a chunked-array
let ca = UInt32Chunked::new("foo".into(), &[Some(1), None, Some(3)]);
let s = ca.into_series();

// into a Column
let s = s.into_column();
""", """
# use iterators
s = pl.Series(range(10), dtype=pl.Int32)

# from slices
s = pl.Series("foo", [1, 2, 3])

# with a missing value
s = pl.Series("foo", [1, None, 3], dtype=pl.UInt32)
s.to_frame()
""":
  nbCode:
    # use iterators
    var s = series("", toSeq(0'i32 ..< 10'i32))

    # from slices
    s = series("foo", [1, 2, 3])

    # with a missing value
    s = series("foo", [some(1'u32), none(uint32), some(3'u32)])
    nbShow s.toFrame

nanuq """
Rust's `Column` is a column of a `DataFrame`, which may hold a `Series` or a single repeated
value. Nanuq frames are built from `Series` directly.
"""

nbText: "### DataFrame"

rustTabs """
use polars::prelude::*;
use polars::df;

// use macro
let df = df! [
    "names" => ["a", "b", "c"],
    "values" => [1, 2, 3],
    "values_nulls" => [Some(1), None, Some(3)]
]?;

// from a Vec<Column>
let c1 = Column::new("names".into(), &["a", "b", "c"]);
let c2 = Column::new("values".into(), &[Some(1), None, Some(3)]);
let df = DataFrame::new_infer_height(vec![c1, c2])?;
""", """
# from a dict
df = pl.DataFrame(
    {"names": ["a", "b", "c"], "values": [1, 2, 3], "values_nulls": [1, None, 3]}
)

# from a list of Series
c1 = pl.Series("names", ["a", "b", "c"])
c2 = pl.Series("values", [1, None, 3])
df2 = pl.DataFrame([c1, c2])
df
""":
  nbCode:
    # use macro
    let df = newDataFrame:
      names: ["a", "b", "c"]
      values: [1, 2, 3]
      values_nulls: [some(1), none(int), some(3)]

    # from Series
    let c1 = series("names", ["a", "b", "c"])
    let c2 = series("values", [some(1), none(int), some(3)])
    let df2 = newDataFrame(c1, c2)
    nbShow df

nbText: """
## Arithmetic

Arithmetic can be done on both `Series` and `ChunkedArray`. The most notable difference is
that a `Series` coerces the data to match the underlying data types.
"""

rustTabs """
use polars::prelude::*;

let s_int = Series::new("a".into(), &[1, 2, 3]);
let s_flt = Series::new("b".into(), &[1.0, 2.0, 3.0]);

let added = &s_int + &s_flt;
let subtracted = &s_int - &s_flt;
let multiplied = &s_int * &s_flt;
let divided = &s_int / &s_flt;
let moduloed = &s_int % &s_flt;


// on chunked-arrays we first need to cast to same types
let ca_int = s_int.i32()?;
let ca_flt = s_flt.f32()?;

ca_int.cast(&DataType::Float32)?.f32()? * ca_flt;
ca_flt.cast(&DataType::Int32)?.i32()? * ca_int;

// we can also do arithmetic with numeric values
let multiplied = ca_int * 2.0;
let multiplied = s_flt * 2.0;

// or broadcast Series to match the operands type
let added = &s_int * &Series::new("broadcast_me".into(), &[10]);
""", """
s_int = pl.Series("a", [1, 2, 3], dtype=pl.Int32)
s_flt = pl.Series("b", [1.0, 2.0, 3.0])

added = s_int + s_flt
subtracted = s_int - s_flt
multiplied = s_int * s_flt
divided = s_int / s_flt
moduloed = s_int % s_flt

# we can also do arithmetic with numeric values
multiplied = s_flt * 2.0

# or broadcast Series to match the operands type
broadcast = s_int * pl.Series("broadcast_me", [10], dtype=pl.Int32)

pl.DataFrame(
    [
        added.alias("added"),
        subtracted.alias("subtracted"),
        divided.alias("divided"),
        moduloed.alias("moduloed"),
        multiplied.alias("multiplied"),
        broadcast.alias("broadcast"),
    ]
)
""":
  nbCode:
    let sInt = series("a", [1'i32, 2, 3])
    let sFlt = series("b", [1.0, 2.0, 3.0])

    let added = sInt + sFlt
    let subtracted = sInt - sFlt
    var multiplied = sInt * sFlt
    let divided = sInt / sFlt
    let moduloed = sInt mod sFlt

    # we can also do arithmetic with numeric values
    multiplied = sFlt * 2.0

    # or broadcast Series to match the operands type
    let broadcast = sInt * series("broadcast_me", [10'i32])

    nbShow newDataFrame(added.alias("added"), subtracted.alias("subtracted"),
                        divided.alias("divided"), moduloed.alias("moduloed"),
                        multiplied.alias("multiplied"), broadcast.alias("broadcast"))

nbText: """
Because Rust's Orphan Rule doesn't allow us to implement left side operations, we need to
call such operations directly.
"""

rustTabs """
let series = Series::new("foo".into(), [1, 2, 3]);

// 1 / s
let divide_one_by_s = 1.div(&series);

// 1 - s
let subtract_one_by_s = 1.sub(&series);
""", """
series = pl.Series("foo", [1, 2, 3])

# 1 / s
divide_one_by_s = 1 / series

# 1 - s
subtract_one_by_s = 1 - series

pl.DataFrame([divide_one_by_s.alias("1 / s"), subtract_one_by_s.alias("1 - s")])
""":
  nbCode:
    let series = series("foo", [1, 2, 3])

    # 1 / s
    let divideOneByS = 1 / series

    # 1 - s
    let subtractOneByS = 1 - series

    nbShow newDataFrame(divideOneByS.alias("1 / s"), subtractOneByS.alias("1 - s"))

nanuq """
Nim has no orphan rule for operators: Nanuq defines `1 / s` and `s / 1` alike, as Python
does. `/` is true division for integers too, `div` is integer division and `mod` is `%`.
"""

nbText: """
## Comparisons

`Series` and `ChunkedArray` can be used in comparison operations to create _boolean_
masks/predicates.
"""

rustTabs """
use polars::prelude::*;

let s = Series::new("a".into(), &[1, 2, 3]);
let ca = UInt32Chunked::new("b".into(), &[Some(3), None, Some(1)]);

// compare Series with numeric values
// ==
s.equal(2);
// !=
s.not_equal(2);
// >
s.gt(2);
// >=
s.gt_eq(2);
// <
s.lt(2);
// <=
s.lt_eq(2);


// compare Series with Series
// ==
s.equal(&s);
// !=
s.not_equal(&s);
// >
s.gt(&s);
// >=
s.gt_eq(&s);
// <
s.lt(&s);
// <=
s.lt_eq(&s);

// (the same for chunked-arrays)

// use iterators
let a: BooleanChunked = ca.iter()
    .map(|opt_value| {
         match opt_value {
         Some(value) => value < 10,
         None => false
}}).collect();
""", """
s = pl.Series("a", [1, 2, 3])
ca = pl.Series("b", [3, None, 1], dtype=pl.UInt32)

# compare Series with numeric values
masks = [
    (s == 2).alias("=="),
    (s != 2).alias("!="),
    (s > 2).alias(">"),
    (s >= 2).alias(">="),
    (s < 2).alias("<"),
    (s <= 2).alias("<="),
]

# compare Series with Series
same = (s == s).alias("s == s")

# use iterators
a = pl.Series("a", [value < 10 if value is not None else False for value in ca])

pl.DataFrame([*masks, same, a.alias("ca < 10")])
""":
  nbCode:
    let s2 = series("a", [1, 2, 3])
    let ca2 = series("b", [some(3'u32), none(uint32), some(1'u32)])

    # compare Series with numeric values
    let masks = [(s2 == 2).alias("=="), (s2 != 2).alias("!="),
                 (s2 > 2).alias(">"), (s2 >= 2).alias(">="),
                 (s2 < 2).alias("<"), (s2 <= 2).alias("<=")]

    # compare Series with Series
    let same = (s2 == s2).alias("s == s")

    # use iterators
    let a = series("a", ca2.toList(Option[uint32]).mapIt(
      if it.isSome: it.get < 10 else: false))

    nbShow newDataFrame(@masks & @[same, a.alias("ca < 10")])

nbText: """
## Apply functions/ closures

### Series / ChunkedArrays
"""

rustTabs """
use polars::prelude::*;
use polars::prelude::arity::unary_elementwise_values;

// apply a closure over all values
let s = Series::new("foo".into(), &[Some(1), Some(2), None]);
s.i32()?.apply_values(|value| value * 20);

// count string lengths
let s = Series::new("foo".into(), &["foo", "bar", "foobar"]);
unary_elementwise_values::<StringType, UInt64Type, _>(s.str()?, |str_val| str_val.len() as u64);
""", """
# apply a closure over all values
s = pl.Series("foo", [1, 2, None], dtype=pl.Int32)
times20 = s.map_elements(lambda value: value * 20, return_dtype=pl.Int32)

# count string lengths
s = pl.Series("foo", ["foo", "bar", "foobar"])
lengths = s.map_elements(lambda str_val: len(str_val), return_dtype=pl.UInt64)

pl.DataFrame([times20, lengths.alias("lengths"), s.str.len_bytes().alias("len_bytes")])
""":
  nbCode:
    # apply a closure over all values
    let s3 = series("foo", [some(1'i32), some(2'i32), none(int32)])
    let times20 = s3.eval(col.foo.mapElements(proc (value: int32): int32 = value * 20))

    # count string lengths
    let s4 = series("foo", ["foo", "bar", "foobar"])
    let lengths = s4.eval(col.foo.mapElements(proc (strVal: string): uint64 = strVal.len.uint64))

    nbShow newDataFrame(times20, lengths.alias("lengths"), s4.str.lenBytes.alias("len_bytes"))

nanuq """
A Nim closure runs on each value through `mapElements`, an expression, which
`s.eval(...)` evaluates on a `Series`. The result type comes from the proc, and nulls stay
null without a call (as with Rust's `apply_values`). For string lengths the native
`str.lenBytes` (the last column) is the fast way, in all three languages.
"""

nbText: "### Multiple columns"

rustTabs """
use polars::prelude::*;

fn my_black_box_function(a: f32, b: f32) -> f32 {
    // do something
    a
}

fn apply_multiples(col_a: &Series, col_b: &Series) -> Float32Chunked {
    match (col_a.dtype(), col_b.dtype()) {
        (DataType::Float32, DataType::Float32) => {
            // downcast to `ChunkedArray`
            let a = col_a.f32().unwrap();
            let b = col_b.f32().unwrap();

            a.into_iter()
                .zip(b.into_iter())
                .map(|(opt_a, opt_b)| match (opt_a, opt_b) {
                    (Some(a), Some(b)) => Some(my_black_box_function(a, b)),
                    // if either value is `None` we propagate that null
                    _ => None,
                })
                .collect()
        }
        _ => panic!("unexpected dtypes"),
    }
}
""", """
def my_black_box_function(a: float, b: float) -> float:
    # do something
    return a


def apply_multiples(col_a: pl.Series, col_b: pl.Series) -> pl.Series:
    if col_a.dtype == pl.Float32 and col_b.dtype == pl.Float32:
        return pl.Series(
            col_a.name,
            [
                my_black_box_function(a, b) if a is not None and b is not None
                # if either value is `None` we propagate that null
                else None
                for a, b in zip(col_a, col_b)
            ],
            dtype=pl.Float32,
        )
    raise TypeError("unexpected dtypes")


apply_multiples(
    pl.Series("a", [1.0, None, 3.0], dtype=pl.Float32),
    pl.Series("b", [3.0, 5.1, None], dtype=pl.Float32),
).to_frame()
""":
  nbCode:
    proc myBlackBoxFunction(a, b: float32): float32 =
      # do something
      a

    proc applyMultiples(colA, colB: Series): Series =
      if colA.dtype == Float32 and colB.dtype == Float32:
        let a = colA.toList(Option[float32])
        let b = colB.toList(Option[float32])
        var res: seq[Option[float32]]
        for (optA, optB) in zip(a, b):
          if optA.isSome and optB.isSome:
            res.add some(myBlackBoxFunction(optA.get, optB.get))
          else:
            # if either value is `none` we propagate that null
            res.add none(float32)
        series(colA.name, res)
      else:
        raise newException(ValueError, "unexpected dtypes")

    nbShow applyMultiples(series("a", [some(1.0'f32), none(float32), some(3.0'f32)]),
                          series("b", [some(3.0'f32), some(5.1'f32), none(float32)])).toFrame

nanuq """
The lazy cookbook does the same with a struct column and `mapElements`, which zips the
columns and skips nulls for you.
"""

nbText: "### DataFrame"

rustTabs """
use polars::prelude::*;
use polars::df;

let mut df = df![
    "letters" => ["a", "b", "c", "d"],
    "numbers" => [1, 2, 3, 4]
]?;


// coerce numbers to floats
df.try_apply("number", |s: &Series| s.cast(&DataType::Float64))?;

// transform letters to uppercase letters
df.try_apply("letters", |s: &Series| {
    Ok(s.str()?.to_uppercase())
});
""", """
df = pl.DataFrame({"letters": ["a", "b", "c", "d"], "numbers": [1, 2, 3, 4]})

# coerce numbers to floats
df = df.with_columns(pl.col("numbers").cast(pl.Float64))

# transform letters to uppercase letters
df = df.with_columns(pl.col("letters").str.to_uppercase())
df
""":
  nbCode:
    var df3 = newDataFrame:
      letters: ["a", "b", "c", "d"]
      numbers: [1, 2, 3, 4]

    # coerce numbers to floats
    df3 = df3.withColumns(col.numbers.cast(float))

    # transform letters to uppercase letters
    df3 = df3.withColumns(col.letters.str.toUppercase)
    nbShow df3

nanuq """
The Rust snippet casts a column `"number"`, which the frame doesn't have (it is
`"numbers"`), so that line returns an error. In Nanuq and Python a column changes through an
expression in `withColumns`, which returns a new frame.
"""

nbText: "## Filter"

rustTabs """
use polars::prelude::*;

// create a mask to filter out null values
let mask = df.column("sepal_width")?.is_not_null();

// select column
let s = df.column("sepal_length")?;

// apply filter on a Series
let filtered_series = s.filter(&mask);

// apply the filter on a DataFrame
let filtered_df = df.filter(&mask)?;
""", """
df = pl.read_csv("data/polars/iris.csv")

# create a mask to filter out null values
mask = df.get_column("sepal_width").is_not_null()

# select column
s = df.get_column("sepal_length")

# apply filter on a Series
filtered_series = s.filter(mask)

# apply the filter on a DataFrame
filtered_df = df.filter(mask)
filtered_df.head()
""":
  nbCode:
    let iris = readCsv("data/polars/iris.csv")

    # create a mask to filter out null values
    let mask = iris.getColumn("sepal_width").isNotNull

    # select column
    let s5 = iris.getColumn("sepal_length")

    # apply filter on a Series
    let filteredSeries = s5.filter(mask)

    # apply the filter on a DataFrame
    let filteredDf = iris.filter(lit(mask))
    nbShow filteredDf.head

nanuq """
`DataFrame.filter` takes an expression in Nanuq; `lit(mask)` turns the boolean `Series`
into one. `iris.filter(col.sepal_width.isNotNull)` says the same without a mask.
"""

nbText: "## Sort"

rustTabs """
use polars::prelude::*;
use polars::df;

let df = df![
    "a" => [1, 2, 3],
    "b" => ["a", "a", "b"]
]?;
// sort this DataFrame by multiple columns

// ordering of the columns
let descending = vec![true, false];
// columns to sort by
let by = [PlSmallStr::from_static("b"), PlSmallStr::from_static("a")];
// do the sort operation
let sorted = df.sort(
    by,
    SortMultipleOptions::default()
        .with_order_descending_multi(descending)
        .with_maintain_order(true)
)?;

// sorted:

// ╭─────┬─────╮
// │ a   ┆ b   │
// │ --- ┆ --- │
// │ i64 ┆ str │
// ╞═════╪═════╡
// │ 1   ┆ "a" │
// │ 2   ┆ "a" │
// │ 3   ┆ "b" │
// ╰─────┴─────╯
""", """
df = pl.DataFrame({"a": [1, 2, 3], "b": ["a", "a", "b"]})
# sort this DataFrame by multiple columns

# ordering of the columns
descending = [True, False]
# columns to sort by
by = ["b", "a"]
# do the sort operation
sorted = df.sort(by, descending=descending, maintain_order=True)
sorted
""":
  nbCode:
    let df4 = newDataFrame:
      a: [1, 2, 3]
      b: ["a", "a", "b"]
    # sort this DataFrame by multiple columns

    # ordering of the columns
    let descending = [true, false]
    # columns to sort by
    let by = ["b", "a"]
    # do the sort operation
    let sorted = df4.sort(by, descending = descending, maintainOrder = true)
    nbShow sorted

nanuq """
The comment shows the frame sorted ascending, but `b` is sorted descending: `3, "b"` comes
first.
"""

nbText: "## Joins"

rustTabs """
use polars::prelude::*;
use polars::df;

// Create first df.
let temp = df!("days" => &[0, 1, 2, 3, 4],
               "temp" => &[22.1, 19.9, 7., 2., 3.],
               "other" => &[1, 2, 3, 4, 5]
)?;

// Create second df.
let rain = df!("days" => &[1, 2],
               "rain" => &[0.1, 0.2],
               "other" => &[1, 2, 3, 4, 5]
)?;

// join on a single column
temp.left_join(&rain, ["days"], ["days"]);
temp.inner_join(&rain, ["days"], ["days"]);
temp.full_join(&rain, ["days"], ["days"]);

// join on multiple columns
temp.join(&rain, vec!["days", "other"], vec!["days", "other"], JoinArgs::new(JoinType::Left), None);
""", """
# Create first df.
temp = pl.DataFrame(
    {"days": [0, 1, 2, 3, 4], "temp": [22.1, 19.9, 7.0, 2.0, 3.0], "other": [1, 2, 3, 4, 5]}
)

# Create second df.
rain = pl.DataFrame({"days": [1, 2], "rain": [0.1, 0.2], "other": [1, 3]})

# join on a single column
temp.join(rain, on="days", how="left")
temp.join(rain, on="days", how="inner")
temp.join(rain, on="days", how="full")

# join on multiple columns
temp.join(rain, on=["days", "other"], how="left")
""":
  nbCode:
    # Create first df.
    let temp = newDataFrame:
      days: [0, 1, 2, 3, 4]
      temp: [22.1, 19.9, 7.0, 2.0, 3.0]
      other: [1, 2, 3, 4, 5]

    # Create second df.
    let rain = newDataFrame:
      days: [1, 2]
      rain: [0.1, 0.2]
      other: [1, 3]

    # join on a single column
    discard temp.join(rain, on = ["days"], how = JoinType.Left)
    discard temp.join(rain, on = ["days"], how = JoinType.Inner)
    discard temp.join(rain, on = ["days"], how = JoinType.Full)

    # join on multiple columns
    nbShow temp.join(rain, on = ["days", "other"], how = JoinType.Left)

nanuq """
As written, `rain` fails: two `days` but five values of `other`. The port gives `rain` two
values of `other`, `1` and `3`, so that the join on both columns matches day 1 (other 2)
nowhere and day 2 (other 3) once.
"""

nbText: """
## Groupby

Note that Polars lazy is a lot more powerful in and more performant in group_by operations.
In lazy a myriad of aggregations can be combined from expressions.

### GroupBy
"""

rustTabs """
use polars::prelude::*;

 // group_by "groups" | sum "foo"
 let out = df.group_by(["groups"])?
    .select(["foo"])
    .sum();
""", """
df = pl.DataFrame({"groups": ["x", "y", "x", "y", "x"], "foo": [1, 2, 3, 4, 5]})

# group_by "groups" | sum "foo"
out = df.group_by("groups").agg(pl.col("foo").sum())
out
""":
  nbCode:
    let df5 = newDataFrame:
      groups: ["x", "y", "x", "y", "x"]
      foo: [1, 2, 3, 4, 5]

    # group_by "groups" | sum "foo"
    let outGroups = df5.groupBy("groups").agg(col.foo.sum)
    nbShow outGroups

nanuq """
Eager Rust has a `GroupBy` object with one method per aggregation (`sum`, `mean`, ...).
Nanuq and Python have only `agg`, with expressions, which is the lazy API this note
recommends. The Rust snippet starts from a `df` it doesn't define, so the ports make one.
"""

nbText: "### Pivot"

rustTabs """
use polars::prelude::*;
use polars::df;

 let df = df!("foo" => ["A", "A", "B", "B", "C"],
     "N" => [1, 2, 2, 4, 2],
     "bar" => ["k", "l", "m", "n", "0"]
     )?;

// group_by "foo" | pivot "bar" column | aggregate "N"
 let pivoted = pivot::pivot(
    &df,
    [PlSmallStr::from_static("foo")],
    Some([PlSmallStr::from_static("bar")]),
    Some([PlSmallStr::from_static("N")]),
    false, Some(first()),
    None
);

// pivoted:
// +-----+------+------+------+------+------+
// | foo | o    | n    | m    | l    | k    |
// | --- | ---  | ---  | ---  | ---  | ---  |
// | str | i32  | i32  | i32  | i32  | i32  |
// +=====+======+======+======+======+======+
// | "A" | null | null | null | 2    | 1    |
// +-----+------+------+------+------+------+
// | "B" | null | 4    | 2    | null | null |
// +-----+------+------+------+------+------+
// | "C" | 2    | null | null | null | null |
// +-----+------+------+------+------+------+!
""", """
df = pl.DataFrame(
    {"foo": ["A", "A", "B", "B", "C"], "N": [1, 2, 2, 4, 2], "bar": ["k", "l", "m", "n", "0"]}
)

# group_by "foo" | pivot "bar" column | aggregate "N"
pivoted = df.pivot(on="bar", index="foo", values="N", aggregate_function="first")
pivoted
""":
  nbCode:
    let df6 = newDataFrame:
      foo: ["A", "A", "B", "B", "C"]
      N: [1, 2, 2, 4, 2]
      bar: ["k", "l", "m", "n", "0"]

    # group_by "foo" | pivot "bar" column | aggregate "N"
    let pivoted = df6.pivot(on = "bar", index = "foo", values = "N",
                            aggregateFunction = PivotAgg.First)
    nbShow pivoted

nanuq """
The new columns now come in the order their values first appear (`k`, `l`, `m`, `n`, `0`),
and the Rust table's `o` is the string `"0"`.
"""

nbText: "## Unpivot"

rustTabs """
use polars::prelude::*;
use polars::df;

let df = df!["A" => &["a", "b", "a"],
             "B" => &[1, 3, 5],
             "C" => &[10, 11, 12],
             "D" => &[2, 4, 6]
    ]?;

let unpivoted = df.unpivot(
    [PlSmallStr::from_static("A"), PlSmallStr::from_static("B")],
    [PlSmallStr::from_static("C"), PlSmallStr::from_static("D")],
).unwrap();
// unpivoted:

// +-----+-----+----------+-------+
// | A   | B   | variable | value |
// | --- | --- | ---      | ---   |
// | str | i32 | str      | i32   |
// +=====+=====+==========+=======+
// | "a" | 1   | "C"      | 10    |
// +-----+-----+----------+-------+
// | "b" | 3   | "C"      | 11    |
// +-----+-----+----------+-------+
// | "a" | 5   | "C"      | 12    |
// +-----+-----+----------+-------+
// | "a" | 1   | "D"      | 2     |
// +-----+-----+----------+-------+
// | "b" | 3   | "D"      | 4     |
// +-----+-----+----------+-------+
// | "a" | 5   | "D"      | 6     |
// +-----+-----+----------+-------+
""", """
df = pl.DataFrame({"A": ["a", "b", "a"], "B": [1, 3, 5], "C": [10, 11, 12], "D": [2, 4, 6]})

unpivoted = df.unpivot(index=["A", "B"], on=["C", "D"])
unpivoted
""":
  nbCode:
    let df7 = newDataFrame:
      A: ["a", "b", "a"]
      B: [1, 3, 5]
      C: [10, 11, 12]
      D: [2, 4, 6]

    let unpivoted = df7.unpivot(index = ["A", "B"], on = ["C", "D"])
    nbShow unpivoted

nbText: "## Explode"

rustTabs """
use polars::prelude::*;
use polars::df;

let s0 = Series::new("a".into(), &[1i64, 2, 3]);
let s1 = Series::new("b".into(), &[1i64, 1, 1]);
let s2 = Series::new("c".into(), &[2i64, 2, 2]);
// construct a new ListChunked for a slice of Series.
let list = Column::new("foo".into(), &[s0, s1, s2]);

// construct a few more Series.
let s0 = Column::new("B".into(), [1, 2, 3]);
let s1 = Column::new("C".into(), [1, 1, 1]);
let df = DataFrame::new_infer_height(vec![list, s0, s1])?;

let exploded = df.explode([PlSmallStr::from("foo")])?;
// exploded:

// +-----+-----+-----+
// | foo | B   | C   |
// | --- | --- | --- |
// | i64 | i32 | i32 |
// +=====+=====+=====+
// | 1   | 1   | 1   |
// +-----+-----+-----+
// | 2   | 1   | 1   |
// +-----+-----+-----+
// | 3   | 1   | 1   |
// +-----+-----+-----+
// | 1   | 2   | 1   |
// +-----+-----+-----+
// | 1   | 2   | 1   |
// +-----+-----+-----+
// | 1   | 2   | 1   |
// +-----+-----+-----+
// | 2   | 3   | 1   |
// +-----+-----+-----+
// | 2   | 3   | 1   |
// +-----+-----+-----+
// | 2   | 3   | 1   |
// +-----+-----+-----+
""", """
# a list column, one list per row
lists = pl.Series("foo", [[1, 2, 3], [1, 1, 1], [2, 2, 2]])

# a few more Series.
s0 = pl.Series("B", [1, 2, 3], dtype=pl.Int32)
s1 = pl.Series("C", [1, 1, 1], dtype=pl.Int32)
df = pl.DataFrame([lists, s0, s1])

exploded = df.explode("foo")
exploded
""":
  nbCode:
    # a list column, one list per row
    let lists = series("foo", [@[1, 2, 3], @[1, 1, 1], @[2, 2, 2]])

    # a few more Series.
    let b0 = series("B", [1'i32, 2, 3])
    let b1 = series("C", [1'i32, 1, 1])
    let df8 = newDataFrame(lists, b0, b1)

    let exploded = df8.explode("foo")
    nbShow exploded

nbText: """
## IO

### Read CSV, Write CSV, Read IPC, Write IPC, Read Parquet, Write Parquet
"""

rustTabs """
use polars::prelude::*;
use std::fs::File;

// read from path
let mut file = std::fs::File::open("iris.csv")?;
let df = CsvReader::new(file).finish()?;

// create a file
let mut file = File::create("example.csv").expect("could not create file");

// write DataFrame to file
CsvWriter::new(&mut file)
    .include_header(true)
    .with_separator(b',')
    .finish(df);

// open file
let file = File::open("file.ipc").expect("file not found");

// read to DataFrame
let df = IpcReader::new(file)
   .finish()?;

// create a file
let mut file = File::create("file.ipc").expect("could not create file");

// write DataFrame to file
IpcWriter::new(&mut file)
    .finish(df)

// open file
let file = File::open("some_file.parquet").unwrap();

// read to DataFrame
let df = ParquetReader::new(file).finish()?;

// create a file
let file = File::create("example.parquet").expect("could not create file");

ParquetWriter::new(file)
    .finish(df)
""", """
import tempfile, os

tmp = tempfile.mkdtemp()

# read from path
df = pl.read_csv("data/polars/iris.csv")

# write DataFrame to file
df.write_csv(os.path.join(tmp, "example.csv"), include_header=True, separator=",")

# write DataFrame to file
df.write_ipc(os.path.join(tmp, "file.ipc"))

# read to DataFrame
df = pl.read_ipc(os.path.join(tmp, "file.ipc"))

df.write_parquet(os.path.join(tmp, "example.parquet"))

# read to DataFrame
df = pl.read_parquet(os.path.join(tmp, "example.parquet"))
df.tail(3)
""":
  nbCode:
    let tmp = getTempDir() / "nanuq-book-rust-cookbook"
    createDir tmp

    # read from path
    var df9 = readCsv("data/polars/iris.csv")

    # write DataFrame to file
    df9.writeCsv(tmp / "example.csv", includeHeader = true, separator = ',')

    # write DataFrame to file
    df9.writeIpc(tmp / "file.ipc")

    # read to DataFrame
    df9 = readIpc(tmp / "file.ipc")

    df9.writeParquet(tmp / "example.parquet")

    # read to DataFrame
    df9 = readParquet(tmp / "example.parquet")
    nbShow df9.tail(3)

nanuq """
The six Rust snippets are in one tab here. Rust opens the files itself and hands readers and
writers a `File`; Nanuq and Python take paths (Nanuq's readers also take a `Stream`). The
ports write to a temporary directory and read back what they wrote.
"""

nbText: """
## Various

### Replace NaN with Missing.

The floating point [Not a Number: NaN](https://en.wikipedia.org/wiki/NaN) is conceptually
different than missing data in Polars. In the snippet below we show how we can replace `NaN`
values with missing values, by setting them to `None`.
"""

rustTabs """
use polars::prelude::*;
use polars::df;

/// Replaces NaN with missing values.
fn fill_nan_with_nulls() -> PolarsResult<DataFrame> {
    let nan = f64::NAN;

    let mut df = df! {
       "a" => [nan, 1.0, 2.0],
       "b" => [nan, 1.0, 2.0]
    }
    .unwrap();

    for idx in 0..df.width() {
        df.try_apply_at_idx(idx, |series| {
            let mask = series.is_nan()?;
            let ca = series.f64()?;
            ca.set(&mask, None)
        })?;
    }
    Ok(df)
}
""", """
def fill_nan_with_nulls() -> pl.DataFrame:
    nan = float("nan")

    df = pl.DataFrame({"a": [nan, 1.0, 2.0], "b": [nan, 1.0, 2.0]})

    return df.with_columns(pl.all().fill_nan(None))


fill_nan_with_nulls()
""":
  nbCode:
    import std/math

    proc fillNanWithNulls(): DataFrame =
      ## Replaces NaN with missing values.
      let df = newDataFrame:
        a: [NaN, 1.0, 2.0]
        b: [NaN, 1.0, 2.0]

      df.withColumns(col("*").fillNan(nil))

    nbShow fillNanWithNulls()

nanuq """
The Rust function loops over the columns and sets the masked values to `None`; with
expressions one `fillNan(nil)` on all columns does it.
"""

nbText: """
### Extracting data

To iterate over the values of a `Series`, or to convert the `Series` into another structure
such as a `Vec<T>`, we must first downcast to a data type aware `ChunkedArray<T>`.
"""

rustTabs """
use polars::prelude::*;
use polars::df;

fn extract_data() -> PolarsResult<()> {
    let df = df! [
       "a" => [None, Some(1.0f32), Some(2.0)],
       "str" => ["foo", "bar", "ham"]
    ]?;

    // first extract ChunkedArray to get the inner type.
    let ca = df.column("a")?.f32()?;
    // Then convert to vec
    let to_vec: Vec<Option<f32>> = Vec::from(ca);

    // We can also do this with iterators
    let ca = df.column("str")?.str()?;
    let to_vec: Vec<Option<&str>> = ca.into_iter().collect();
    let to_vec_no_options: Vec<&str> = ca.into_no_null_iter().collect();

    Ok(())
}
""", """
def extract_data():
    df = pl.DataFrame(
        {"a": [None, 1.0, 2.0], "str": ["foo", "bar", "ham"]}, schema={"a": pl.Float32, "str": pl.String}
    )

    to_vec = df.get_column("a").to_list()
    print(to_vec)

    to_vec = df.get_column("str").to_list()
    print(to_vec)


extract_data()
""":
  nbCode:
    proc extractData() =
      let df = newDataFrame:
        a: [none(float32), some(1.0'f32), some(2.0'f32)]
        str: ["foo", "bar", "ham"]

      # read the values with the type you expect
      let toVec: seq[Option[float32]] = df["a"].toList(Option[float32])
      echo toVec

      let toVecNoOptions: seq[string] = df["str"].toList(string)
      echo toVecNoOptions

    extractData()

nanuq """
No downcast in Nanuq: `toList` takes the Nim type to read the values as, `Option[T]` when
the column may hold nulls (a null read as a plain `T` is an error). For numbers without nulls,
`s.view(float32)` reads the Arrow buffer in place, without a copy.
"""

bookSave()
