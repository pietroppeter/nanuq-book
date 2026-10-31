## PDS-H (derived from TPC-H) queries in Nanuq: the ones Nanuq 0.2 can run.
##
## Ported from the Polars queries of polars-benchmark (Apache-2.0). Dates are read as
## ISO strings ("1995-03-15"), which compare in the same order as the dates.
import std/os
import nanuq

type Tables* = object
  customer*, lineitem*, nation*, orders*, part*, partsupp*, region*, supplier*: LazyFrame

proc scanTables*(dir: string): Tables =
  ## The eight tables, as CSV files with a header (`tpchgen-cli csv`).
  template scan(name: string): LazyFrame = scanCsv(dir / name & ".csv")
  Tables(customer: scan("customer"), lineitem: scan("lineitem"), nation: scan("nation"),
         orders: scan("orders"), part: scan("part"), partsupp: scan("partsupp"),
         region: scan("region"), supplier: scan("supplier"))

proc q1*(t: Tables): LazyFrame =
  let var1 = "1998-09-02"
  t.lineitem.filter(col("l_shipdate") <= var1)
    .groupBy(col("l_returnflag"), col("l_linestatus"))
    .agg(
      col("l_quantity").sum.alias("sum_qty"),
      col("l_extendedprice").sum.alias("sum_base_price"),
      (col("l_extendedprice") * (1.0 - col("l_discount"))).sum.alias("sum_disc_price"),
      (col("l_extendedprice") * (1.0 - col("l_discount")) * (1.0 + col("l_tax")))
        .sum.alias("sum_charge"),
      col("l_quantity").mean.alias("avg_qty"),
      col("l_extendedprice").mean.alias("avg_price"),
      col("l_discount").mean.alias("avg_disc"),
      col("l_orderkey").len.alias("count_order"))
    .sort(["l_returnflag", "l_linestatus"])

proc q3*(t: Tables): LazyFrame =
  let var1 = "BUILDING"
  let var2 = "1995-03-15"
  t.customer.filter(col("c_mktsegment") == var1)
    .join(t.orders, leftOn = ["c_custkey"], rightOn = ["o_custkey"])
    .join(t.lineitem, leftOn = ["o_orderkey"], rightOn = ["l_orderkey"])
    .filter(col("o_orderdate") < var2)
    .filter(col("l_shipdate") > var2)
    .withColumns((col("l_extendedprice") * (1 - col("l_discount"))).alias("revenue"))
    .groupBy(col("o_orderkey"), col("o_orderdate"), col("o_shippriority"))
    .agg(col("revenue").sum)
    .select(col("o_orderkey").alias("l_orderkey"), col("revenue"), col("o_orderdate"),
            col("o_shippriority"))
    .sort(["revenue", "o_orderdate"], descending = [true, false])
    .head(10)

proc q4*(t: Tables): LazyFrame =
  let var1 = "1993-07-01"
  let var2 = "1993-10-01"
  # SQL exists translates to semi join in Polars API
  t.orders.join(t.lineitem.filter(col("l_commitdate") < col("l_receiptdate")),
                leftOn = ["o_orderkey"], rightOn = ["l_orderkey"], how = Semi)
    .filter(col("o_orderdate").isBetween(var1, var2, closed = Left))
    .groupBy(col("o_orderpriority"))
    .agg(col("o_orderkey").len.alias("order_count"))
    .sort("o_orderpriority")

proc q5*(t: Tables): LazyFrame =
  let var1 = "ASIA"
  let var2 = "1994-01-01"
  let var3 = "1995-01-01"
  t.region.join(t.nation, leftOn = ["r_regionkey"], rightOn = ["n_regionkey"])
    .join(t.customer, leftOn = ["n_nationkey"], rightOn = ["c_nationkey"])
    .join(t.orders, leftOn = ["c_custkey"], rightOn = ["o_custkey"])
    .join(t.lineitem, leftOn = ["o_orderkey"], rightOn = ["l_orderkey"])
    .join(t.supplier, leftOn = ["l_suppkey", "n_nationkey"],
          rightOn = ["s_suppkey", "s_nationkey"])
    .filter(col("r_name") == var1)
    .filter(col("o_orderdate").isBetween(var2, var3, closed = Left))
    .withColumns((col("l_extendedprice") * (1 - col("l_discount"))).alias("revenue"))
    .groupBy(col("n_name"))
    .agg(col("revenue").sum)
    .sort("revenue", descending = true)

proc q6*(t: Tables): LazyFrame =
  let var1 = "1994-01-01"
  let var2 = "1995-01-01"
  let var3 = 0.05
  let var4 = 0.07
  let var5 = 24
  t.lineitem.filter(col("l_shipdate").isBetween(var1, var2, closed = Left))
    .filter(col("l_discount").isBetween(var3, var4))
    .filter(col("l_quantity") < var5)
    .withColumns((col("l_extendedprice") * col("l_discount")).alias("revenue"))
    .select(col("revenue").sum)

proc q10*(t: Tables): LazyFrame =
  let var1 = "1993-10-01"
  let var2 = "1994-01-01"
  t.customer.join(t.orders, leftOn = ["c_custkey"], rightOn = ["o_custkey"])
    .join(t.lineitem, leftOn = ["o_orderkey"], rightOn = ["l_orderkey"])
    .join(t.nation, leftOn = ["c_nationkey"], rightOn = ["n_nationkey"])
    .filter(col("o_orderdate").isBetween(var1, var2, closed = Left))
    .filter(col("l_returnflag") == "R")
    .groupBy(col("c_custkey"), col("c_name"), col("c_acctbal"), col("c_phone"),
             col("n_name"), col("c_address"), col("c_comment"))
    .agg((col("l_extendedprice") * (1 - col("l_discount"))).sum.round(2).alias("revenue"))
    .select(col("c_custkey"), col("c_name"), col("revenue"), col("c_acctbal"),
            col("n_name"), col("c_address"), col("c_phone"), col("c_comment"))
    .sort("revenue", descending = true)
    .head(20)

proc q11*(t: Tables, scaleFactor: float): LazyFrame =
  let var1 = "GERMANY"
  let var2 = 0.0001 / scaleFactor
  let q1 = t.partsupp.join(t.supplier, leftOn = ["ps_suppkey"], rightOn = ["s_suppkey"])
    .join(t.nation, leftOn = ["s_nationkey"], rightOn = ["n_nationkey"])
    .filter(col("n_name") == var1)
  let q2 = q1.select(
    (col("ps_supplycost") * col("ps_availqty")).sum.round(2).alias("tmp") * var2)
  q1.groupBy(col("ps_partkey"))
    .agg((col("ps_supplycost") * col("ps_availqty")).sum.round(2).alias("value"))
    .join(q2, on = newSeq[string](), how = Cross)
    .filter(col("value") > col("tmp"))
    .select(col("ps_partkey"), col("value"))
    .sort("value", descending = true)

proc q12*(t: Tables): LazyFrame =
  let var1 = "MAIL"
  let var2 = "SHIP"
  let var3 = "1994-01-01"
  let var4 = "1995-01-01"
  t.orders.join(t.lineitem, leftOn = ["o_orderkey"], rightOn = ["l_orderkey"])
    .filter(col("l_shipmode").isIn([var1, var2]))
    .filter(col("l_commitdate") < col("l_receiptdate"))
    .filter(col("l_shipdate") < col("l_commitdate"))
    .filter(col("l_receiptdate").isBetween(var3, var4, closed = Left))
    .withColumns(col("o_orderpriority").isIn(["1-URGENT", "2-HIGH"]).alias("line_count"))
    .groupBy(col("l_shipmode"))
    .agg(
      col("line_count").sum.alias("high_line_count"),
      (not col("line_count")).sum.alias("low_line_count"))
    .sort("l_shipmode")

proc q15*(t: Tables): LazyFrame =
  let var1 = "1996-01-01"
  let var2 = "1996-04-01"
  let revenue = t.lineitem.filter(col("l_shipdate").isBetween(var1, var2, closed = Left))
    .groupBy(col("l_suppkey"))
    .agg((col("l_extendedprice") * (1 - col("l_discount"))).sum.alias("total_revenue"))
    .select(col("l_suppkey").alias("supplier_no"), col("total_revenue"))
  t.supplier.join(revenue, leftOn = ["s_suppkey"], rightOn = ["supplier_no"])
    .filter(col("total_revenue") == col("total_revenue").max)
    .withColumns(col("total_revenue").round(2))
    .select(col("s_suppkey"), col("s_name"), col("s_address"), col("s_phone"),
            col("total_revenue"))
    .sort("s_suppkey")

proc q17*(t: Tables): LazyFrame =
  let var1 = "Brand#23"
  let var2 = "MED BOX"
  let q1 = t.part.filter(col("p_brand") == var1)
    .filter(col("p_container") == var2)
    .join(t.lineitem, leftOn = ["p_partkey"], rightOn = ["l_partkey"])
  q1.groupBy(col("p_partkey"))
    .agg((0.2 * col("l_quantity").mean).alias("avg_quantity"))
    .select(col("p_partkey").alias("key"), col("avg_quantity"))
    .join(q1, leftOn = ["key"], rightOn = ["p_partkey"])
    .filter(col("l_quantity") < col("avg_quantity"))
    .select((col("l_extendedprice").sum / 7.0).round(2).alias("avg_yearly"))

proc q18*(t: Tables): LazyFrame =
  let var1 = 300
  let q1 = t.lineitem.groupBy(col("l_orderkey"))
    .agg(col("l_quantity").sum.alias("sum_quantity"))
    .filter(col("sum_quantity") > var1)
  t.orders.join(q1, leftOn = ["o_orderkey"], rightOn = ["l_orderkey"], how = Semi)
    .join(t.lineitem, leftOn = ["o_orderkey"], rightOn = ["l_orderkey"])
    .join(t.customer, leftOn = ["o_custkey"], rightOn = ["c_custkey"])
    .groupBy(col("c_name"), col("o_custkey"), col("o_orderkey"), col("o_orderdate"),
             col("o_totalprice"))
    .agg(col("l_quantity").sum.alias("col6"))
    .select(col("c_name"), col("o_custkey").alias("c_custkey"), col("o_orderkey"),
            col("o_orderdate").alias("o_orderdat"), col("o_totalprice"), col("col6"))
    .sort(["o_totalprice", "o_orderdat"], descending = [true, false])
    .head(100)

proc q19*(t: Tables): LazyFrame =
  t.part.join(t.lineitem, leftOn = ["p_partkey"], rightOn = ["l_partkey"])
    .filter(col("l_shipmode").isIn(["AIR", "AIR REG"]))
    .filter(col("l_shipinstruct") == "DELIVER IN PERSON")
    .filter(
      (
        (col("p_brand") == "Brand#12") and
        col("p_container").isIn(["SM CASE", "SM BOX", "SM PACK", "SM PKG"]) and
        col("l_quantity").isBetween(1, 11) and
        col("p_size").isBetween(1, 5)
      ) or (
        (col("p_brand") == "Brand#23") and
        col("p_container").isIn(["MED BAG", "MED BOX", "MED PKG", "MED PACK"]) and
        col("l_quantity").isBetween(10, 20) and
        col("p_size").isBetween(1, 10)
      ) or (
        (col("p_brand") == "Brand#34") and
        col("p_container").isIn(["LG CASE", "LG BOX", "LG PACK", "LG PKG"]) and
        col("l_quantity").isBetween(20, 30) and
        col("p_size").isBetween(1, 15)
      ))
    .select((col("l_extendedprice") * (1 - col("l_discount"))).sum.round(2).alias("revenue"))

proc q21*(t: Tables): LazyFrame =
  let var1 = "SAUDI ARABIA"
  let isLate = col("l_receiptdate") > col("l_commitdate")
  let l1 = t.lineitem.filter(isLate)
    .join(t.supplier, leftOn = ["l_suppkey"], rightOn = ["s_suppkey"])
    .join(t.nation.filter(col("n_name") == var1),
          leftOn = ["s_nationkey"], rightOn = ["n_nationkey"])
    .join(t.orders.filter(col("o_orderstatus") == "F"),
          leftOn = ["l_orderkey"], rightOn = ["o_orderkey"], how = Semi)
  let lines = t.lineitem.join(l1, on = ["l_orderkey"], how = Semi)
  # Nanuq has no Expr.filter yet: the late suppliers of each order are counted apart
  let lateSupp = lines.filter(isLate)
    .groupBy(col("l_orderkey"))
    .agg(col("l_suppkey").nUnique.alias("n_late_supp"))
  let perOrder = lines.groupBy(col("l_orderkey"))
    .agg(col("l_suppkey").nUnique.alias("n_supp"))
    .join(lateSupp, on = ["l_orderkey"], how = Left)
  l1.join(perOrder, on = ["l_orderkey"])
    .filter(col("n_supp") > 1 and col("n_late_supp") == 1)
    .groupBy(col("s_name"))
    .agg(col("s_name").len.alias("numwait"))
    .sort(["numwait", "s_name"], descending = [true, false])
    .head(100)
