"""The db-benchmark (H2O.ai, now DuckDB Labs) group-by and join questions in Python Polars.

The queries are those of db-benchmark's polars/groupby-polars.py and polars/join-polars.py
(MPL-2.0), as functions of the lazy tables.
"""
import os

import polars as pl
from polars import col


def scan_groupby(path):
    # The group-by table, with its string ids as Categorical.
    return pl.scan_csv(
        path,
        schema_overrides={"id4": pl.Int32, "id5": pl.Int32, "id6": pl.Int32,
                          "v1": pl.Int32, "v2": pl.Int32, "v3": pl.Float64},
    ).with_columns(pl.col(["id1", "id2", "id3"]).cast(pl.Categorical))


def scan_join(dir):
    # The four join tables, with their string ids as Categorical.
    def scan(name, overrides, cats):
        return pl.scan_csv(os.path.join(dir, name + ".csv"), schema_overrides=overrides) \
            .with_columns(pl.col(cats).cast(pl.Categorical))
    return {
        "x": scan("x", {"id1": pl.Int32, "id2": pl.Int32, "id3": pl.Int32, "v1": pl.Float32},
                  ["id4", "id5", "id6"]),
        "small": scan("small", {"id1": pl.Int32, "v2": pl.Float32}, ["id4"]),
        "medium": scan("medium", {"id1": pl.Int32, "id2": pl.Int32, "v2": pl.Float32},
                       ["id4", "id5"]),
        "big": scan("big", {"id1": pl.Int32, "id2": pl.Int32, "id3": pl.Int32,
                            "v2": pl.Float32}, ["id4", "id5", "id6"]),
    }


def g1(x):
    # sum v1 by id1
    return x.group_by("id1").agg(pl.sum("v1").alias("v1_sum"))


def g2(x):
    # sum v1 by id1:id2
    return x.group_by(["id1", "id2"]).agg(pl.sum("v1").alias("v1_sum"))


def g3(x):
    # sum v1 mean v3 by id3
    return x.group_by("id3").agg([pl.sum("v1").alias("v1_sum"), pl.mean("v3").alias("v3_mean")])


def g4(x):
    # mean v1:v3 by id4
    return x.group_by("id4").agg([pl.mean("v1").alias("v1_mean"), pl.mean("v2").alias("v2_mean"),
                                  pl.mean("v3").alias("v3_mean")])


def g5(x):
    # sum v1:v3 by id6
    return x.group_by("id6").agg([pl.sum("v1").alias("v1_sum"), pl.sum("v2").alias("v2_sum"),
                                  pl.sum("v3").alias("v3_sum")])


def g6(x):
    # median v3 sd v3 by id4 id5
    return x.group_by(["id4", "id5"]).agg([pl.median("v3").alias("v3_median"),
                                           pl.std("v3").alias("v3_std")])


def g7(x):
    # max v1 - min v2 by id3
    return x.group_by("id3").agg([(pl.max("v1") - pl.min("v2")).alias("range_v1_v2")])


def g8(x):
    # largest two v3 by id6
    return x.drop_nulls("v3").group_by("id6").agg(col("v3").top_k(2).alias("largest2_v3")) \
        .explode("largest2_v3")


def g9(x):
    # regression v1 v2 by id2 id4
    return x.group_by(["id2", "id4"]).agg((pl.corr("v1", "v2", method="pearson") ** 2).alias("r2"))


def g10(x):
    # sum v3 count by id1:id6
    return x.group_by(["id1", "id2", "id3", "id4", "id5", "id6"]) \
        .agg([pl.sum("v3").alias("v3"), pl.len().alias("count")])


def j1(t):
    # small inner on int
    return t["x"].join(t["small"], on="id1")


def j2(t):
    # medium inner on int
    return t["x"].join(t["medium"], on="id2")


def j3(t):
    # medium outer on int (a left join, as in db-benchmark)
    return t["x"].join(t["medium"], how="left", on="id2")


def j4(t):
    # medium inner on factor
    return t["x"].join(t["medium"], on="id5")


def j5(t):
    # big inner on int
    return t["x"].join(t["big"], on="id3")
