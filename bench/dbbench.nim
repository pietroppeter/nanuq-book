## The db-benchmark (H2O.ai, now DuckDB Labs) group-by and join questions in Nanuq,
## and data generators that follow its R scripts.
##
## Ported from db-benchmark's `polars/groupby-polars.py` and `polars/join-polars.py`
## (MPL-2.0); the generators follow `_data/groupby-datagen.R` and `_data/join-datagen.R`.
import std/[os, random, strutils, sequtils]
import nanuq

# --- Data ---------------------------------------------------------------------------

proc fmtId(prefix: string, n, width: int): string = prefix & align($n, width, '0')

proc generateGroupBy*(path: string, n, k: int, seed = 108) =
  ## `n` rows of the group-by table, as `groupby-datagen.R` makes them with `k` groups
  ## (no missing values, random order): id1, id2 (k strings each), id3 (n/k strings),
  ## id4, id5 (k ints), id6 (n/k ints), v1 in 1..5, v2 in 1..15, v3 in [0, 100).
  var r = initRand(seed)
  var f = open(path, fmWrite)
  defer: f.close()
  f.writeLine "id1,id2,id3,id4,id5,id6,v1,v2,v3"
  let nk = max(n div k, 1)
  for _ in 0 ..< n:
    f.writeLine fmtId("id", r.rand(1 .. k), 3), ',', fmtId("id", r.rand(1 .. k), 3), ',',
      fmtId("id", r.rand(1 .. nk), 10), ',', r.rand(1 .. k), ',', r.rand(1 .. k), ',',
      r.rand(1 .. nk), ',', r.rand(1 .. 5), ',', r.rand(1 .. 15), ',',
      formatFloat(r.rand(100.0), ffDecimal, 6)

type JoinSizes* = tuple[small, medium, big: int]

proc joinSizes*(n: int): JoinSizes =
  ## Rows of the three right-hand tables: n/1e6, n/1e3 and n in db-benchmark (whose
  ## smallest x has 1e7 rows); at least 10 and 100 here, so small samples join too.
  (max(n div 1_000_000, 10), max(n div 1_000, 100), n)

proc generateJoin*(dir: string, n: int, seed = 108) =
  ## The join tables as `join-datagen.R` makes them: `x.csv` (`n` rows) and `small.csv`,
  ## `medium.csv`, `big.csv`. Each key column draws from its own pool of keys: 90% are
  ## shared by both sides, 10% only on the left, 10% only on the right; id4..id6 are the
  ## same keys as strings.
  var r = initRand(seed)
  let sizes = joinSizes(n)
  proc split(m: int): tuple[x, l, rr: seq[int]] =
    var key = toSeq(1 .. (m * 11) div 10)
    r.shuffle(key)
    let a = (m * 9) div 10
    (key[0 ..< a], key[a ..< m], key[m .. ^1])
  proc sampleAll(keys: seq[int], size: int): seq[int] =
    # every key at least once, then random ones, shuffled
    result = keys
    while result.len < size: result.add keys[r.rand(keys.high)]
    result.setLen size
    r.shuffle(result)
  let k1 = split(sizes.small)
  let k2 = split(sizes.medium)
  let k3 = split(sizes.big)
  createDir dir
  block:
    let id1 = sampleAll(k1.x & k1.l, n)
    let id2 = sampleAll(k2.x & k2.l, n)
    let id3 = sampleAll(k3.x & k3.l, n)
    var f = open(dir / "x.csv", fmWrite)
    f.writeLine "id1,id2,id3,id4,id5,id6,v1"
    for i in 0 ..< n:
      f.writeLine id1[i], ',', id2[i], ',', id3[i], ",id", id1[i], ",id", id2[i], ",id", id3[i],
        ',', formatFloat(r.rand(100.0), ffDecimal, 6)
    f.close()
  block:
    let id1 = sampleAll(k1.x & k1.rr, sizes.small)
    var f = open(dir / "small.csv", fmWrite)
    f.writeLine "id1,id4,v2"
    for i in 0 ..< sizes.small:
      f.writeLine id1[i], ",id", id1[i], ',', formatFloat(r.rand(100.0), ffDecimal, 6)
    f.close()
  block:
    let id1 = sampleAll(k1.x & k1.rr, sizes.medium)
    let id2 = sampleAll(k2.x & k2.rr, sizes.medium)
    var f = open(dir / "medium.csv", fmWrite)
    f.writeLine "id1,id2,id4,id5,v2"
    for i in 0 ..< sizes.medium:
      f.writeLine id1[i], ',', id2[i], ",id", id1[i], ",id", id2[i], ',',
        formatFloat(r.rand(100.0), ffDecimal, 6)
    f.close()
  block:
    let id1 = sampleAll(k1.x & k1.rr, sizes.big)
    let id2 = sampleAll(k2.x & k2.rr, sizes.big)
    let id3 = sampleAll(k3.x & k3.rr, sizes.big)
    var f = open(dir / "big.csv", fmWrite)
    f.writeLine "id1,id2,id3,id4,id5,id6,v2"
    for i in 0 ..< sizes.big:
      f.writeLine id1[i], ',', id2[i], ',', id3[i], ",id", id1[i], ",id", id2[i], ",id", id3[i],
        ',', formatFloat(r.rand(100.0), ffDecimal, 6)
    f.close()

# --- Reading, as the Polars scripts do ----------------------------------------------

proc scanGroupBy*(path: string): LazyFrame =
  ## The group-by table, with its string ids as Categorical.
  scanCsv(path, schemaOverrides = {"id4": Int32, "id5": Int32, "id6": Int32,
                                   "v1": Int32, "v2": Int32, "v3": Float64})
    .withColumns(col(["id1", "id2", "id3"]).cast(Categorical))

type JoinTables* = object
  x*, small*, medium*, big*: LazyFrame

proc scanJoin*(dir: string): JoinTables =
  ## The four join tables, with their string ids as Categorical.
  JoinTables(
    x: scanCsv(dir / "x.csv", schemaOverrides = {"id1": Int32, "id2": Int32, "id3": Int32,
                                                 "v1": Float32})
      .withColumns(col(["id4", "id5", "id6"]).cast(Categorical)),
    small: scanCsv(dir / "small.csv", schemaOverrides = {"id1": Int32, "v2": Float32})
      .withColumns(col.id4.cast(Categorical)),
    medium: scanCsv(dir / "medium.csv", schemaOverrides = {"id1": Int32, "id2": Int32,
                                                           "v2": Float32})
      .withColumns(col(["id4", "id5"]).cast(Categorical)),
    big: scanCsv(dir / "big.csv", schemaOverrides = {"id1": Int32, "id2": Int32, "id3": Int32,
                                                     "v2": Float32})
      .withColumns(col(["id4", "id5", "id6"]).cast(Categorical)))

# --- Group-by questions ---------------------------------------------------------------

proc g1*(x: LazyFrame): LazyFrame =
  ## sum v1 by id1
  x.groupBy("id1").agg(col.v1.sum.alias("v1_sum"))

proc g2*(x: LazyFrame): LazyFrame =
  ## sum v1 by id1:id2
  x.groupBy("id1", "id2").agg(col.v1.sum.alias("v1_sum"))

proc g3*(x: LazyFrame): LazyFrame =
  ## sum v1 mean v3 by id3
  x.groupBy("id3").agg(col.v1.sum.alias("v1_sum"), col.v3.mean.alias("v3_mean"))

proc g4*(x: LazyFrame): LazyFrame =
  ## mean v1:v3 by id4
  x.groupBy("id4").agg(col.v1.mean.alias("v1_mean"), col.v2.mean.alias("v2_mean"),
                       col.v3.mean.alias("v3_mean"))

proc g5*(x: LazyFrame): LazyFrame =
  ## sum v1:v3 by id6
  x.groupBy("id6").agg(col.v1.sum.alias("v1_sum"), col.v2.sum.alias("v2_sum"),
                       col.v3.sum.alias("v3_sum"))

proc g6*(x: LazyFrame): LazyFrame =
  ## median v3 sd v3 by id4 id5
  x.groupBy("id4", "id5").agg(col.v3.median.alias("v3_median"), col.v3.std.alias("v3_std"))

proc g7*(x: LazyFrame): LazyFrame =
  ## max v1 - min v2 by id3
  x.groupBy("id3").agg((col.v1.max - col.v2.min).alias("range_v1_v2"))

proc g8*(x: LazyFrame): LazyFrame =
  ## largest two v3 by id6
  x.dropNulls("v3").groupBy("id6").agg(col.v3.topK(2).alias("largest2_v3"))
    .explode("largest2_v3")

proc g9*(x: LazyFrame): LazyFrame =
  ## regression v1 v2 by id2 id4
  x.groupBy("id2", "id4").agg(corr("v1", "v2").pow(2).alias("r2"))

proc g10*(x: LazyFrame): LazyFrame =
  ## sum v3 count by id1:id6
  x.groupBy("id1", "id2", "id3", "id4", "id5", "id6")
    .agg(col.v3.sum.alias("v3"), len().alias("count"))

# --- Join questions -------------------------------------------------------------------

proc j1*(t: JoinTables): LazyFrame =
  ## small inner on int
  t.x.join(t.small, on = ["id1"])

proc j2*(t: JoinTables): LazyFrame =
  ## medium inner on int
  t.x.join(t.medium, on = ["id2"])

proc j3*(t: JoinTables): LazyFrame =
  ## medium outer on int (a left join, as in db-benchmark)
  t.x.join(t.medium, on = ["id2"], how = Left)

proc j4*(t: JoinTables): LazyFrame =
  ## medium inner on factor
  t.x.join(t.medium, on = ["id5"])

proc j5*(t: JoinTables): LazyFrame =
  ## big inner on int
  t.x.join(t.big, on = ["id3"])
