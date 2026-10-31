"""PDS-H (derived from TPC-H) queries in Python Polars: the ones Nanuq 0.2 can run.

From the Polars queries of polars-benchmark (Apache-2.0), with dates as ISO strings,
`pl.lit("1995-03-15")`, instead of date values, as on the Nim side (a plain string in
`is_between` would be a column name).
"""
from pathlib import Path

import polars as pl

TABLES = ["customer", "lineitem", "nation", "orders", "part", "partsupp", "region", "supplier"]


def scan_tables(folder):
    # The eight tables, as CSV files with a header (`tpchgen-cli csv`).
    return {name: pl.scan_csv(Path(folder) / f"{name}.csv") for name in TABLES}


def q1(lineitem, **kwargs):
    var1 = pl.lit("1998-09-02")

    return (
        lineitem.filter(pl.col("l_shipdate") <= var1)
        .group_by("l_returnflag", "l_linestatus")
        .agg(
            pl.sum("l_quantity").alias("sum_qty"),
            pl.sum("l_extendedprice").alias("sum_base_price"),
            (pl.col("l_extendedprice") * (1.0 - pl.col("l_discount")))
            .sum()
            .alias("sum_disc_price"),
            (
                pl.col("l_extendedprice")
                * (1.0 - pl.col("l_discount"))
                * (1.0 + pl.col("l_tax"))
            )
            .sum()
            .alias("sum_charge"),
            pl.mean("l_quantity").alias("avg_qty"),
            pl.mean("l_extendedprice").alias("avg_price"),
            pl.mean("l_discount").alias("avg_disc"),
            pl.len().alias("count_order"),
        )
        .sort("l_returnflag", "l_linestatus")
    )


def q3(customer, lineitem, orders, **kwargs):
    var1 = "BUILDING"
    var2 = pl.lit("1995-03-15")

    return (
        customer.filter(pl.col("c_mktsegment") == var1)
        .join(orders, left_on="c_custkey", right_on="o_custkey")
        .join(lineitem, left_on="o_orderkey", right_on="l_orderkey")
        .filter(pl.col("o_orderdate") < var2)
        .filter(pl.col("l_shipdate") > var2)
        .with_columns(
            (pl.col("l_extendedprice") * (1 - pl.col("l_discount"))).alias("revenue")
        )
        .group_by("o_orderkey", "o_orderdate", "o_shippriority")
        .agg(pl.sum("revenue"))
        .select(
            pl.col("o_orderkey").alias("l_orderkey"),
            "revenue",
            "o_orderdate",
            "o_shippriority",
        )
        .sort(by=["revenue", "o_orderdate"], descending=[True, False])
        .head(10)
    )


def q4(lineitem, orders, **kwargs):
    var1 = pl.lit("1993-07-01")
    var2 = pl.lit("1993-10-01")

    return (
        # SQL exists translates to semi join in Polars API
        orders.join(
            (lineitem.filter(pl.col("l_commitdate") < pl.col("l_receiptdate"))),
            left_on="o_orderkey",
            right_on="l_orderkey",
            how="semi",
        )
        .filter(pl.col("o_orderdate").is_between(var1, var2, closed="left"))
        .group_by("o_orderpriority")
        .agg(pl.len().alias("order_count"))
        .sort("o_orderpriority")
    )


def q5(customer, lineitem, nation, orders, partsupp, supplier, region, part, **kwargs):
    var1 = "ASIA"
    var2 = pl.lit("1994-01-01")
    var3 = pl.lit("1995-01-01")

    return (
        region.join(nation, left_on="r_regionkey", right_on="n_regionkey")
        .join(customer, left_on="n_nationkey", right_on="c_nationkey")
        .join(orders, left_on="c_custkey", right_on="o_custkey")
        .join(lineitem, left_on="o_orderkey", right_on="l_orderkey")
        .join(
            supplier,
            left_on=["l_suppkey", "n_nationkey"],
            right_on=["s_suppkey", "s_nationkey"],
        )
        .filter(pl.col("r_name") == var1)
        .filter(pl.col("o_orderdate").is_between(var2, var3, closed="left"))
        .with_columns(
            (pl.col("l_extendedprice") * (1 - pl.col("l_discount"))).alias("revenue")
        )
        .group_by("n_name")
        .agg(pl.sum("revenue"))
        .sort(by="revenue", descending=True)
    )


def q6(lineitem, **kwargs):
    var1 = pl.lit("1994-01-01")
    var2 = pl.lit("1995-01-01")
    var3 = 0.05
    var4 = 0.07
    var5 = 24

    return (
        lineitem.filter(pl.col("l_shipdate").is_between(var1, var2, closed="left"))
        .filter(pl.col("l_discount").is_between(var3, var4))
        .filter(pl.col("l_quantity") < var5)
        .with_columns(
            (pl.col("l_extendedprice") * pl.col("l_discount")).alias("revenue")
        )
        .select(pl.sum("revenue"))
    )


def q10(customer, lineitem, nation, orders, **kwargs):
    var1 = pl.lit("1993-10-01")
    var2 = pl.lit("1994-01-01")

    return (
        customer.join(orders, left_on="c_custkey", right_on="o_custkey")
        .join(lineitem, left_on="o_orderkey", right_on="l_orderkey")
        .join(nation, left_on="c_nationkey", right_on="n_nationkey")
        .filter(pl.col("o_orderdate").is_between(var1, var2, closed="left"))
        .filter(pl.col("l_returnflag") == "R")
        .group_by(
            "c_custkey",
            "c_name",
            "c_acctbal",
            "c_phone",
            "n_name",
            "c_address",
            "c_comment",
        )
        .agg(
            (pl.col("l_extendedprice") * (1 - pl.col("l_discount")))
            .sum()
            .round(2)
            .alias("revenue")
        )
        .select(
            "c_custkey",
            "c_name",
            "revenue",
            "c_acctbal",
            "n_name",
            "c_address",
            "c_phone",
            "c_comment",
        )
        .sort(by="revenue", descending=True)
        .head(20)
    )


def q11(nation, partsupp, supplier, scale_factor=1.0, **kwargs):
    var1 = "GERMANY"
    var2 = 0.0001 / scale_factor

    q1 = (
        partsupp.join(supplier, left_on="ps_suppkey", right_on="s_suppkey")
        .join(nation, left_on="s_nationkey", right_on="n_nationkey")
        .filter(pl.col("n_name") == var1)
    )
    q2 = q1.select(
        (pl.col("ps_supplycost") * pl.col("ps_availqty")).sum().round(2).alias("tmp")
        * var2
    )

    return (
        q1.group_by("ps_partkey")
        .agg(
            (pl.col("ps_supplycost") * pl.col("ps_availqty"))
            .sum()
            .round(2)
            .alias("value")
        )
        .join(q2, how="cross")
        .filter(pl.col("value") > pl.col("tmp"))
        .select("ps_partkey", "value")
        .sort("value", descending=True)
    )


def q12(lineitem, orders, **kwargs):
    var1 = "MAIL"
    var2 = "SHIP"
    var3 = pl.lit("1994-01-01")
    var4 = pl.lit("1995-01-01")

    return (
        orders.join(lineitem, left_on="o_orderkey", right_on="l_orderkey")
        .filter(pl.col("l_shipmode").is_in([var1, var2]))
        .filter(pl.col("l_commitdate") < pl.col("l_receiptdate"))
        .filter(pl.col("l_shipdate") < pl.col("l_commitdate"))
        .filter(pl.col("l_receiptdate").is_between(var3, var4, closed="left"))
        .with_columns(
            line_count=pl.col("o_orderpriority").is_in(["1-URGENT", "2-HIGH"])
        )
        .group_by("l_shipmode")
        .agg(
            high_line_count=pl.col.line_count.sum(),
            low_line_count=pl.col.line_count.not_().sum(),
        )
        .sort("l_shipmode")
    )


def q15(lineitem, supplier, **kwargs):
    var1 = pl.lit("1996-01-01")
    var2 = pl.lit("1996-04-01")

    revenue = (
        lineitem.filter(pl.col("l_shipdate").is_between(var1, var2, closed="left"))
        .group_by("l_suppkey")
        .agg(
            (pl.col("l_extendedprice") * (1 - pl.col("l_discount")))
            .sum()
            .alias("total_revenue")
        )
        .select(pl.col("l_suppkey").alias("supplier_no"), pl.col("total_revenue"))
    )

    return (
        supplier.join(revenue, left_on="s_suppkey", right_on="supplier_no")
        .filter(pl.col("total_revenue") == pl.col("total_revenue").max())
        .with_columns(pl.col("total_revenue").round(2))
        .select("s_suppkey", "s_name", "s_address", "s_phone", "total_revenue")
        .sort("s_suppkey")
    )


def q17(lineitem, part, **kwargs):
    var1 = "Brand#23"
    var2 = "MED BOX"

    q1 = (
        part.filter(pl.col("p_brand") == var1)
        .filter(pl.col("p_container") == var2)
        .join(lineitem, how="inner", left_on="p_partkey", right_on="l_partkey")
    )

    return (
        q1.group_by("p_partkey")
        .agg((0.2 * pl.col("l_quantity").mean()).alias("avg_quantity"))
        .select(pl.col("p_partkey").alias("key"), pl.col("avg_quantity"))
        .join(q1, left_on="key", right_on="p_partkey")
        .filter(pl.col("l_quantity") < pl.col("avg_quantity"))
        .select((pl.col("l_extendedprice").sum() / 7.0).round(2).alias("avg_yearly"))
    )


def q18(customer, lineitem, orders, **kwargs):
    var1 = 300

    q1 = (
        lineitem.group_by("l_orderkey")
        .agg(pl.col("l_quantity").sum().alias("sum_quantity"))
        .filter(pl.col("sum_quantity") > var1)
    )

    return (
        orders.join(q1, left_on="o_orderkey", right_on="l_orderkey", how="semi")
        .join(lineitem, left_on="o_orderkey", right_on="l_orderkey")
        .join(customer, left_on="o_custkey", right_on="c_custkey")
        .group_by("c_name", "o_custkey", "o_orderkey", "o_orderdate", "o_totalprice")
        .agg(pl.col("l_quantity").sum().alias("col6"))
        .select(
            pl.col("c_name"),
            pl.col("o_custkey").alias("c_custkey"),
            pl.col("o_orderkey"),
            pl.col("o_orderdate").alias("o_orderdat"),
            pl.col("o_totalprice"),
            pl.col("col6"),
        )
        .sort(by=["o_totalprice", "o_orderdat"], descending=[True, False])
        .head(100)
    )


def q19(lineitem, part, **kwargs):
    return (
        part.join(lineitem, left_on="p_partkey", right_on="l_partkey")
        .filter(pl.col("l_shipmode").is_in(["AIR", "AIR REG"]))
        .filter(pl.col("l_shipinstruct") == "DELIVER IN PERSON")
        .filter(
            (
                (pl.col("p_brand") == "Brand#12")
                & pl.col("p_container").is_in(
                    ["SM CASE", "SM BOX", "SM PACK", "SM PKG"]
                )
                & (pl.col("l_quantity").is_between(1, 11))
                & (pl.col("p_size").is_between(1, 5))
            )
            | (
                (pl.col("p_brand") == "Brand#23")
                & pl.col("p_container").is_in(
                    ["MED BAG", "MED BOX", "MED PKG", "MED PACK"]
                )
                & (pl.col("l_quantity").is_between(10, 20))
                & (pl.col("p_size").is_between(1, 10))
            )
            | (
                (pl.col("p_brand") == "Brand#34")
                & pl.col("p_container").is_in(
                    ["LG CASE", "LG BOX", "LG PACK", "LG PKG"]
                )
                & (pl.col("l_quantity").is_between(20, 30))
                & (pl.col("p_size").is_between(1, 15))
            )
        )
        .select(
            (pl.col("l_extendedprice") * (1 - pl.col("l_discount")))
            .sum()
            .round(2)
            .alias("revenue")
        )
    )


def q21(lineitem, nation, orders, supplier, **kwargs):
    var1 = "SAUDI ARABIA"

    is_late = pl.col("l_receiptdate") > pl.col("l_commitdate")

    l1 = (
        lineitem.filter(is_late)
        .join(supplier, left_on="l_suppkey", right_on="s_suppkey")
        .join(
            nation.filter(pl.col("n_name") == var1),
            left_on="s_nationkey",
            right_on="n_nationkey",
        )
        .join(
            orders.filter(pl.col("o_orderstatus") == "F"),
            left_on="l_orderkey",
            right_on="o_orderkey",
            how="semi",
        )
    )

    per_order = (
        lineitem.join(l1, on="l_orderkey", how="semi")
        .group_by("l_orderkey")
        .agg(
            n_supp=pl.col("l_suppkey").n_unique(),
            n_late_supp=pl.col("l_suppkey").filter(is_late).n_unique(),
        )
    )

    return (
        l1.join(per_order, on="l_orderkey")
        .filter(pl.col("n_supp") > 1, pl.col("n_late_supp") == 1)
        .group_by("s_name")
        .agg(pl.len().alias("numwait"))
        .sort(by=["numwait", "s_name"], descending=[True, False])
        .head(100)
    )
