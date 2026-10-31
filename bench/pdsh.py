"""PDS-H (derived from TPC-H) queries in Python Polars.

The Polars queries of polars-benchmark (Apache-2.0), as they are there: only the
dataset loading is left out (the tables are passed in) and q11 takes the scale factor
as an argument.
"""
from datetime import date
from pathlib import Path

import polars as pl

TABLES = ["customer", "lineitem", "nation", "orders", "part", "partsupp", "region", "supplier"]


def scan_tables(folder):
    # The eight tables, as CSV files with a header (`tpchgen-cli csv`), dates parsed.
    return {
        name: pl.scan_csv(Path(folder) / f"{name}.csv", try_parse_dates=True)
        for name in TABLES
    }


def q1(lineitem, **kwargs):
    var1 = date(1998, 9, 2)

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


def q2(nation, partsupp, supplier, region, part, **kwargs):
    var1 = 15
    var2 = "BRASS"
    var3 = "EUROPE"

    q1 = (
        part.join(partsupp, left_on="p_partkey", right_on="ps_partkey")
        .join(supplier, left_on="ps_suppkey", right_on="s_suppkey")
        .join(nation, left_on="s_nationkey", right_on="n_nationkey")
        .join(region, left_on="n_regionkey", right_on="r_regionkey")
        .filter(pl.col("p_size") == var1)
        .filter(pl.col("p_type").str.ends_with(var2))
        .filter(pl.col("r_name") == var3)
    )

    return (
        q1.group_by("p_partkey")
        .agg(pl.min("ps_supplycost"))
        .join(q1, on=["p_partkey", "ps_supplycost"])
        .select(
            "s_acctbal",
            "s_name",
            "n_name",
            "p_partkey",
            "p_mfgr",
            "s_address",
            "s_phone",
            "s_comment",
        )
        .sort(
            by=["s_acctbal", "n_name", "s_name", "p_partkey"],
            descending=[True, False, False, False],
        )
        .head(100)
    )


def q3(customer, lineitem, orders, **kwargs):
    var1 = "BUILDING"
    var2 = date(1995, 3, 15)

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
    var1 = date(1993, 7, 1)
    var2 = date(1993, 10, 1)

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


def q5(customer, lineitem, nation, orders, supplier, region, **kwargs):
    var1 = "ASIA"
    var2 = date(1994, 1, 1)
    var3 = date(1995, 1, 1)

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
    var1 = date(1994, 1, 1)
    var2 = date(1995, 1, 1)
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


def q7(customer, lineitem, nation, orders, supplier, **kwargs):
    var1 = "FRANCE"
    var2 = "GERMANY"
    var3 = date(1995, 1, 1)
    var4 = date(1996, 12, 31)

    nations = nation.filter(pl.col("n_name").is_in([var1, var2]))

    return (
        customer.join(nations, left_on="c_nationkey", right_on="n_nationkey")
        .rename({"n_name": "cust_nation"})
        .join(orders, left_on="c_custkey", right_on="o_custkey")
        .join(lineitem, left_on="o_orderkey", right_on="l_orderkey")
        .join(supplier, left_on="l_suppkey", right_on="s_suppkey")
        .join(nations, left_on="s_nationkey", right_on="n_nationkey")
        .rename({"n_name": "supp_nation"})
        .filter(
            ((pl.col("cust_nation") == var1) & (pl.col("supp_nation") == var2))
            | ((pl.col("cust_nation") == var2) & (pl.col("supp_nation") == var1))
        )
        .filter(pl.col("l_shipdate").is_between(var3, var4))
        .with_columns(
            (pl.col("l_extendedprice") * (1 - pl.col("l_discount"))).alias("volume"),
            pl.col("l_shipdate").dt.year().alias("l_year"),
        )
        .group_by("supp_nation", "cust_nation", "l_year")
        .agg(pl.sum("volume").alias("revenue"))
        .sort(by=["supp_nation", "cust_nation", "l_year"])
    )


def q8(customer, lineitem, nation, orders, supplier, region, part, **kwargs):
    var1 = "BRAZIL"
    var2 = "AMERICA"
    var3 = "ECONOMY ANODIZED STEEL"
    var4 = date(1995, 1, 1)
    var5 = date(1996, 12, 31)

    n1 = nation.select("n_nationkey", "n_regionkey")
    n2 = nation.select("n_nationkey", "n_name")

    return (
        part.join(lineitem, left_on="p_partkey", right_on="l_partkey")
        .join(supplier, left_on="l_suppkey", right_on="s_suppkey")
        .join(orders, left_on="l_orderkey", right_on="o_orderkey")
        .join(customer, left_on="o_custkey", right_on="c_custkey")
        .join(n1, left_on="c_nationkey", right_on="n_nationkey")
        .join(region, left_on="n_regionkey", right_on="r_regionkey")
        .filter(pl.col("r_name") == var2)
        .join(n2, left_on="s_nationkey", right_on="n_nationkey")
        .filter(pl.col("o_orderdate").is_between(var4, var5))
        .filter(pl.col("p_type") == var3)
        .select(
            pl.col("o_orderdate").dt.year().alias("o_year"),
            (pl.col("l_extendedprice") * (1 - pl.col("l_discount"))).alias("volume"),
            pl.col("n_name").alias("nation"),
        )
        .with_columns(
            pl.when(pl.col("nation") == var1)
            .then(pl.col("volume"))
            .otherwise(0)
            .alias("_tmp")
        )
        .group_by("o_year")
        .agg((pl.sum("_tmp") / pl.sum("volume")).round(2).alias("mkt_share"))
        .sort("o_year")
    )


def q9(lineitem, nation, orders, partsupp, supplier, part, **kwargs):
    return (
        part.join(partsupp, left_on="p_partkey", right_on="ps_partkey")
        .join(supplier, left_on="ps_suppkey", right_on="s_suppkey")
        .join(
            lineitem,
            left_on=["p_partkey", "ps_suppkey"],
            right_on=["l_partkey", "l_suppkey"],
        )
        .join(orders, left_on="l_orderkey", right_on="o_orderkey")
        .join(nation, left_on="s_nationkey", right_on="n_nationkey")
        .filter(pl.col("p_name").str.contains("green"))
        .select(
            pl.col("n_name").alias("nation"),
            pl.col("o_orderdate").dt.year().alias("o_year"),
            (
                pl.col("l_extendedprice") * (1 - pl.col("l_discount"))
                - pl.col("ps_supplycost") * pl.col("l_quantity")
            ).alias("amount"),
        )
        .group_by("nation", "o_year")
        .agg(pl.sum("amount").round(2).alias("sum_profit"))
        .sort(by=["nation", "o_year"], descending=[False, True])
    )


def q10(customer, lineitem, nation, orders, **kwargs):
    var1 = date(1993, 10, 1)
    var2 = date(1994, 1, 1)

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
    var3 = date(1994, 1, 1)
    var4 = date(1995, 1, 1)

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


def q13(customer, orders, **kwargs):
    var1 = "special"
    var2 = "requests"

    orders = orders.filter(pl.col("o_comment").str.contains(f"{var1}.*{var2}").not_())
    return (
        customer.join(orders, left_on="c_custkey", right_on="o_custkey", how="left")
        .group_by("c_custkey")
        .agg(pl.col("o_orderkey").count().alias("c_count"))
        .group_by("c_count")
        .len()
        .select(pl.col("c_count"), pl.col("len").alias("custdist"))
        .sort(by=["custdist", "c_count"], descending=[True, True])
    )


def q14(lineitem, part, **kwargs):
    var1 = date(1995, 9, 1)
    var2 = date(1995, 10, 1)

    return (
        lineitem.join(part, left_on="l_partkey", right_on="p_partkey")
        .filter(pl.col("l_shipdate").is_between(var1, var2, closed="left"))
        .select(
            (
                100.00
                * pl.when(pl.col("p_type").str.starts_with("PROMO"))
                .then(pl.col("l_extendedprice") * (1 - pl.col("l_discount")))
                .otherwise(0)
                .sum()
                / (pl.col("l_extendedprice") * (1 - pl.col("l_discount"))).sum()
            )
            .round(2)
            .alias("promo_revenue")
        )
    )


def q15(lineitem, supplier, **kwargs):
    var1 = date(1996, 1, 1)
    var2 = date(1996, 4, 1)

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


def q16(partsupp, supplier, part, **kwargs):
    var1 = "Brand#45"

    supplier = supplier.filter(
        pl.col("s_comment").str.contains(".*Customer.*Complaints.*")
    ).select(pl.col("s_suppkey"), pl.col("s_suppkey").alias("ps_suppkey"))

    return (
        part.join(partsupp, left_on="p_partkey", right_on="ps_partkey")
        .filter(pl.col("p_brand") != var1)
        .filter(pl.col("p_type").str.contains("MEDIUM POLISHED*").not_())
        .filter(pl.col("p_size").is_in([49, 14, 23, 45, 19, 3, 36, 9]))
        .join(supplier, left_on="ps_suppkey", right_on="s_suppkey", how="anti")
        .group_by("p_brand", "p_type", "p_size")
        .agg(pl.col("ps_suppkey").n_unique().alias("supplier_cnt"))
        .sort(
            by=["supplier_cnt", "p_brand", "p_type", "p_size"],
            descending=[True, False, False, False],
        )
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


def q20(lineitem, nation, partsupp, supplier, part, **kwargs):
    var1 = date(1994, 1, 1)
    var2 = date(1995, 1, 1)
    var3 = "CANADA"
    var4 = "forest"

    q1 = (
        lineitem.filter(pl.col("l_shipdate").is_between(var1, var2, closed="left"))
        .group_by("l_partkey", "l_suppkey")
        .agg((pl.col("l_quantity").sum() * 0.5).alias("sum_quantity"))
    )
    q2 = nation.filter(pl.col("n_name") == var3)
    q3 = supplier.join(q2, left_on="s_nationkey", right_on="n_nationkey")

    return (
        part.filter(pl.col("p_name").str.starts_with(var4))
        .select(pl.col("p_partkey").unique())
        .join(partsupp, left_on="p_partkey", right_on="ps_partkey")
        .join(
            q1,
            left_on=["ps_suppkey", "p_partkey"],
            right_on=["l_suppkey", "l_partkey"],
        )
        .filter(pl.col("ps_availqty") > pl.col("sum_quantity"))
        .select(pl.col("ps_suppkey").unique())
        .join(q3, left_on="ps_suppkey", right_on="s_suppkey")
        .select("s_name", "s_address")
        .sort("s_name")
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


def q22(customer, orders, **kwargs):
    q1 = (
        customer.with_columns(pl.col("c_phone").str.slice(0, 2).alias("cntrycode"))
        .filter(pl.col("cntrycode").str.contains("13|31|23|29|30|18|17"))
        .select("c_acctbal", "c_custkey", "cntrycode")
    )

    q2 = q1.filter(pl.col("c_acctbal") > 0.0).select(
        pl.col("c_acctbal").mean().alias("avg_acctbal")
    )

    return (
        q1.join(orders, left_on="c_custkey", right_on="o_custkey", how="anti")
        .join(q2, how="cross")
        .filter(pl.col("c_acctbal") > pl.col("avg_acctbal"))
        .group_by("cntrycode")
        .agg(
            pl.col("c_acctbal").count().alias("numcust"),
            pl.col("c_acctbal").sum().round(2).alias("totacctbal"),
        )
        .sort("cntrycode")
    )
