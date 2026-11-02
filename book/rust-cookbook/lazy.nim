import nanuqbook
bookInit()

nbText: "# Lazy cookbook"

attribution rustCookbook("Polars Lazy cookbook", "lazy.rs",
  "The Rust code is shown as it is, in a third tab, and is not run: the book never " &
  "builds Rust. The Nim port and a Python version (the Nanuq book's own) run and are " &
  "compared. The Reddit CSV is `data/polars/reddit.csv`, the 100-row sample in the Polars " &
  "repository.")

nbText: """
This page should serve as a cookbook to quickly get you started with Polars' query engine.
The lazy API allows you to create complex well performing queries on top of Polars eager.
"""

nanuq """
This cookbook is part of the documentation of the Rust `polars` crate, the one Nanuq
binds. It is the closest the book gets to Nanuq's own engine room: each Nim line here
becomes, through Nanuq's Rust shim, the Rust call in the middle tab.
"""

nbText: "## Start a lazy computation"

rustTabs """
use polars::prelude::*;
use polars::df;

let df = df![
    "a" => [1, 2, 3],
    "b" => [None, Some("a"), Some("b")]
]?;
// from an eager DataFrame
let lf: LazyFrame = df.lazy();

// scan a csv file lazily
let lf: LazyFrame = LazyCsvReader::new("some_path")
    .with_has_header(true)
    .finish()?;

// scan a parquet file lazily
let lf: LazyFrame = LazyFrame::scan_parquet("some_path", Default::default())?;
""", """
import polars as pl

df = pl.DataFrame({"a": [1, 2, 3], "b": [None, "a", "b"]})
# from an eager DataFrame
lf = df.lazy()

# scan a csv file lazily
lf = pl.scan_csv("data/polars/reddit.csv", has_header=True)

# scan a parquet file lazily
lf = pl.scan_parquet("data/polars/alltypes_plain.parquet")

lf.select("id", "bool_col", "string_col").head(3).collect()
""":
  nbCode:
    import nanuq

    let df = newDataFrame(series("a", [1, 2, 3]),
                          series("b", [none(string), some("a"), some("b")]))
    # from an eager DataFrame
    var lf = df.lazy

    # scan a csv file lazily
    lf = scanCsv("data/polars/reddit.csv", hasHeader = true)

    # scan a parquet file lazily
    lf = scanParquet("data/polars/alltypes_plain.parquet")

    nbShow lf.select(col("id", "bool_col", "string_col")).head(3).collect

nanuq """
The Rust snippet reads from `"some_path"`; the Nim and Python versions read real files, and
show the first rows of the Parquet one.
"""

nbText: "## Filter"

rustTabs """
use polars::prelude::*;
use polars::df;

let df = df![
    "a" => [1, 2, 3],
    "b" => [None, Some("a"), Some("b")]
]?;

let filtered = df.lazy()
    .filter(col("a").gt(lit(2)))
    .collect()?;

// filtered:

// ╭─────┬─────╮
// │ a   ┆ b   │
// │ --- ┆ --- │
// │ i64 ┆ str │
// ╞═════╪═════╡
// │ 3   ┆ "c" │
// ╰─────┴─────╯
""", """
filtered = df.lazy().filter(pl.col("a") > 2).collect()
filtered
""":
  nbCode:
    let filtered = df.lazy
      .filter(col.a > 2)
      .collect
    nbShow filtered

nanuq """
The comment in the Rust snippet shows `"c"` in column `b`, a value the frame doesn't have:
the result is `3`, `"b"`.
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
let sorted = df.lazy()
    .sort_by_exprs(vec![col("b"), col("a")], SortMultipleOptions::default())
    .collect()?;

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
sorted = df.lazy().sort(pl.col("b"), pl.col("a")).collect()
sorted
""":
  nbCode:
    let df2 = newDataFrame(series("a", [1, 2, 3]), series("b", ["a", "a", "b"]))
    # sort this DataFrame by multiple columns
    let sorted = df2.lazy
      .sort([col.b, col.a])
      .collect
    nbShow sorted

nbText: """
## Groupby

This example is from the polars [user guide](https://docs.pola.rs/user-guide/concepts/expressions-and-contexts/#group_by-and-aggregations).
"""

rustTabs """
use polars::prelude::*;

 let df = LazyCsvReader::new("reddit.csv")
    .with_has_header(true)
    .with_separator(b',')
    .finish()?
    .group_by([col("comment_karma")])
    .agg([col("name").n_unique().alias("unique_names"), col("link_karma").max()])
    // take only 100 rows.
    .fetch(100)?;
""", """
out = (
    pl.scan_csv("data/polars/reddit.csv", has_header=True, separator=",")
    .group_by(pl.col("comment_karma"))
    .agg(pl.col("name").n_unique().alias("unique_names"), pl.col("link_karma").max())
    .sort("comment_karma", descending=True)
    .head(100)
    .collect()
)
out
""":
  nbCode:
    let reddit = scanCsv("data/polars/reddit.csv", hasHeader = true, separator = ',')
      .groupBy(col.comment_karma)
      .agg(col.name.nUnique.alias("unique_names"), col.link_karma.max)
      .sort("comment_karma", descending = true)
      .head(100)
      .collect
    nbShow reddit

nanuq """
`fetch(100)` ran the query on the first 100 rows of each source. Polars has since removed
it, from Rust and Python: `head(100)` limits the result instead (for this 100-row file it's
the same). Group-by output comes in no particular order, so the port sorts it to show the
top karma.
"""

nbText: "## Joins"

rustTabs """
use polars::prelude::*;
use polars::df;

let df_a = df![
    "a" => [1, 2, 1, 1],
    "b" => ["a", "b", "c", "c"],
    "c" => [0, 1, 2, 3]
]?;

let df_b = df![
    "foo" => [1, 1, 1],
    "bar" => ["a", "c", "c"],
    "ham" => ["let", "var", "const"]
]?;

let lf_a = df_a.clone().lazy();
let lf_b = df_b.clone().lazy();

let joined = lf_a.join(lf_b, vec![col("a")], vec![col("foo")], JoinArgs::new(JoinType::Full)).collect()?;

// joined:

// ╭─────┬─────┬─────┬──────┬─────────╮
// │ b   ┆ c   ┆ a   ┆ bar  ┆ ham     │
// │ --- ┆ --- ┆ --- ┆ ---  ┆ ---     │
// │ str ┆ i64 ┆ i64 ┆ str  ┆ str     │
// ╞═════╪═════╪═════╪══════╪═════════╡
// │ "a" ┆ 0   ┆ 1   ┆ "a"  ┆ "let"   │
// │ "a" ┆ 0   ┆ 1   ┆ "c"  ┆ "var"   │
// │ "a" ┆ 0   ┆ 1   ┆ "c"  ┆ "const" │
// │ "b" ┆ 1   ┆ 2   ┆ null ┆ null    │
// │ "c" ┆ 2   ┆ 1   ┆ null ┆ null    │
// │ "c" ┆ 3   ┆ 1   ┆ null ┆ null    │
// ╰─────┴─────┴─────┴──────┴─────────╯
""", """
df_a = pl.DataFrame({"a": [1, 2, 1, 1], "b": ["a", "b", "c", "c"], "c": [0, 1, 2, 3]})
df_b = pl.DataFrame({"foo": [1, 1, 1], "bar": ["a", "c", "c"], "ham": ["let", "var", "const"]})

lf_a = df_a.lazy()
lf_b = df_b.lazy()

joined = lf_a.join(lf_b, left_on=pl.col("a"), right_on=pl.col("foo"), how="full").collect()
joined
""":
  nbCode:
    let dfA = newDataFrame(series("a", [1, 2, 1, 1]), series("b", ["a", "b", "c", "c"]),
                           series("c", [0, 1, 2, 3]))
    let dfB = newDataFrame(series("foo", [1, 1, 1]), series("bar", ["a", "c", "c"]),
                           series("ham", ["let", "var", "const"]))

    let lfA = dfA.lazy
    let lfB = dfB.lazy

    let joined = lfA.join(lfB, leftOn = [col.a], rightOn = [col.foo], how = JoinType.Full).collect
    nbShow joined

nanuq """
The table in the Rust comment is from an older Polars. A full join now keeps both key
columns, `a` and `foo` (null where a row has no match), and the left frame's columns come
first. The three `"a"` rows match all three rows of `df_b` with `foo` 1.
"""

nbText: "other join syntax options"

rustTabs """
let inner = lf_a.inner_join(lf_b, col("a"), col("foo")).collect()?;

let left = lf_a.left_join(lf_b, col("a"), col("foo")).collect()?;

let outer = lf_a.full_join(lf_b, col("a"), col("foo")).collect()?;

let joined_with_builder = lf_a.join_builder()
    .with(lf_b)
    .left_on(vec![col("a")])
    .right_on(vec![col("foo")])
    .how(JoinType::Inner)
    .force_parallel(true)
    .finish()
    .collect()?;
""", """
inner = lf_a.join(lf_b, left_on="a", right_on="foo", how="inner").collect()

left = lf_a.join(lf_b, left_on="a", right_on="foo", how="left").collect()

outer = lf_a.join(lf_b, left_on="a", right_on="foo", how="full").collect()

joined_with_builder = lf_a.join(
    lf_b, left_on=pl.col("a"), right_on=pl.col("foo"), how="inner", allow_parallel=True
).collect()
left
""":
  nbCode:
    let inner = lfA.join(lfB, leftOn = ["a"], rightOn = ["foo"], how = JoinType.Inner).collect

    let left = lfA.join(lfB, leftOn = ["a"], rightOn = ["foo"], how = JoinType.Left).collect

    let outer = lfA.join(lfB, leftOn = ["a"], rightOn = ["foo"], how = JoinType.Full).collect

    let joinedInner = lfA.join(lfB, leftOn = [col.a], rightOn = [col.foo]).collect
    nbShow left

nanuq """
Rust has a method per join type and a builder; Nanuq has one `join`, like Python, with the
join type as a `JoinType` value (`Inner` by default). Python's `allow_parallel` is on by
default and Nanuq doesn't expose it. The tabs show the left join.
"""

nbText: """
## Conditionally apply

If we want to create a new column based on some condition, we can use the
`when`/`then`/`otherwise` expressions.

* `when` - accepts a predicate expression
* `then` - expression to use when `predicate == true`
* `otherwise` - expression to use when `predicate == false`
"""

rustTabs """
use polars::prelude::*;
use polars::df;

let df = df![
    "range" => [1, 2, 3, 4, 5, 6, 8, 9, 10],
    "left" => (0..10).map(|_| Some("foo")).collect::<Vec<_>>(),
    "right" => (0..10).map(|_| Some("bar")).collect::<Vec<_>>()
]?;

let new = df.lazy()
    .with_column(when(col("range").gt_eq(lit(5)))
        .then(col("left"))
        .otherwise(col("right")).alias("foo_or_bar")
    ).collect()?;

// new:

// ╭───────┬───────┬───────┬────────────╮
// │ range ┆ left  ┆ right ┆ foo_or_bar │
// │ ---   ┆ ---   ┆ ---   ┆ ---        │
// │ i64   ┆ str   ┆ str   ┆ str        │
// ╞═══════╪═══════╪═══════╪════════════╡
// │ 0     ┆ "foo" ┆ "bar" ┆ "bar"      │
// │ 1     ┆ "foo" ┆ "bar" ┆ "bar"      │
// │ 2     ┆ "foo" ┆ "bar" ┆ "bar"      │
// │ 3     ┆ "foo" ┆ "bar" ┆ "bar"      │
// │ …     ┆ …     ┆ …     ┆ …          │
// │ 5     ┆ "foo" ┆ "bar" ┆ "foo"      │
// │ 6     ┆ "foo" ┆ "bar" ┆ "foo"      │
// │ 7     ┆ "foo" ┆ "bar" ┆ "foo"      │
// │ 8     ┆ "foo" ┆ "bar" ┆ "foo"      │
// │ 9     ┆ "foo" ┆ "bar" ┆ "foo"      │
// ╰───────┴───────┴───────┴────────────╯
""", """
df = pl.DataFrame({"range": range(10), "left": ["foo"] * 10, "right": ["bar"] * 10})

new = (
    df.lazy()
    .with_columns(
        pl.when(pl.col("range") >= 5)
        .then(pl.col("left"))
        .otherwise(pl.col("right"))
        .alias("foo_or_bar")
    )
    .collect()
)
new
""":
  nbCode:
    import std/sequtils
    let df3 = newDataFrame(series("range", toSeq(0 ..< 10)),
                           series("left", sequtils.repeat("foo", 10)),
                           series("right", sequtils.repeat("bar", 10)))

    let new = df3.lazy
      .withColumns(choose(if col("range") >= 5: col.left else: col.right).alias("foo_or_bar"))
      .collect
    nbShow new

nanuq """
As written, the Rust snippet fails: `range` has nine values (no 0, no 7) and the string
columns ten, and a frame's columns must have the same length. The port uses `0..9`, the
range in the result table. In Nanuq `when` is a Nim keyword, so the idiomatic spelling is
the `choose` macro around a Nim `if`; ``` `when`(...).then(...).otherwise(...) ``` works too.
"""

nbText: """
## Black box function

The expression API should be expressive enough for most of what you want to achieve, but it
can happen that you need to pass the values to an external function you do not control. The
snippet below shows how we use the `Struct` datatype to be able to apply a function over
multiple inputs.
"""

rustTabs """
use polars::prelude::*;
fn my_black_box_function(a: f32, b: f32) -> f32 {
    // do something
    a
}

fn apply_multiples() -> PolarsResult<DataFrame> {
    df![
        "a" => [1.0f32, 2.0, 3.0],
        "b" => [3.0f32, 5.1, 0.3]
    ]?
    .lazy()
    .select([as_struct(vec![col("a"), col("b")]).map(
        |s| {
            let ca = s.struct_()?;

            let series_a = ca.field_by_name("a")?;
            let series_b = ca.field_by_name("b")?;
            let chunked_a = series_a.f32()?;
            let chunked_b = series_b.f32()?;

            let out: Float32Chunked = chunked_a
                .into_iter()
                .zip(chunked_b.into_iter())
                .map(|(opt_a, opt_b)| match (opt_a, opt_b) {
                    (Some(a), Some(b)) => Some(my_black_box_function(a, b)),
                    _ => None,
                })
                .collect();

            Ok(Some(out.into_series()))
        },
        |_, f| Ok(Field::new(f.name().clone(), DataType::Float32))
    )])
    .collect()
}
""", """
def my_black_box_function(a: float, b: float) -> float:
    # do something
    return a


def apply_multiples() -> pl.DataFrame:
    return (
        pl.DataFrame(
            {"a": [1.0, 2.0, 3.0], "b": [3.0, 5.1, 0.3]},
            schema={"a": pl.Float32, "b": pl.Float32},
        )
        .lazy()
        .select(
            pl.struct("a", "b")
            .map_elements(
                lambda x: my_black_box_function(x["a"], x["b"]), return_dtype=pl.Float64
            )
            .cast(pl.Float32)
        )
        .collect()
    )


apply_multiples()
""":
  nbCode:
    proc myBlackBoxFunction(a, b: float32): float32 =
      # do something
      a

    proc applyMultiples(): DataFrame =
      newDataFrame(series("a", [1.0'f32, 2.0, 3.0]), series("b", [3.0'f32, 5.1, 0.3]))
        .lazy
        .select(asStruct(col.a, col.b).mapElements(
          proc (x: tuple[a, b: float32]): float32 = myBlackBoxFunction(x.a, x.b)))
        .collect

    nbShow applyMultiples()

nanuq """
The Rust closure walks both columns, zipped, and keeps nulls null. Nanuq's `mapElements`
does that loop for you: the struct's fields arrive as a named tuple, the result type comes
from the proc's return type, and nulls skip the call. For a whole-column function there is
`mapBatches`, which gets a `Series`, like Rust's `map`.

In Python Polars 2.1, `map_elements(..., return_dtype=pl.Float32)` raises a `SchemaError`
(“found value of type Float64”) as soon as the function returns a Python `float`, so the
Python version asks for `Float64` and casts.
"""

bookSave()
