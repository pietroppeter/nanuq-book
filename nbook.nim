import nimibook

var book = initBookWithToc:
  entry("Introduction", "index", numbered = false)
  section("Polars user guide", "user-guide/index.md"):
    entry("Getting started", "getting_started")
    entry("Expressions and contexts", "expressions_and_contexts")
    entry("Lazy API", "lazy_api")
    entry("Basic operations", "basic_operations")
    entry("Expression expansion", "expression_expansion")
    entry("Casting", "casting")
    entry("Missing data", "missing_data")
    entry("Strings", "strings")
    entry("Time series: parsing", "time_series_parsing")
    entry("Time series: filtering", "time_series_filtering")
    entry("Time zones", "time_zones")
    entry("Joins", "joins")
    entry("Concatenation", "concatenation")
    entry("CSV", "csv")
  section("Python Polars: The Definitive Guide", "definitive-guide/index.md"):
    entry("Beginning expressions", "beginning_expressions")
    entry("Filtering and sorting rows", "filtering_and_sorting")
    entry("Joining and concatenating", "joining_and_concatenating")
  section("Polars Cookbook", "polars-cookbook/index.md"):
    entry("Getting started", "getting_started")
    entry("String manipulations", "string_manipulations")
    entry("Debugging chained operations", "debugging_chains")
  section("Benchmarks", "benchmarks/index.md"):
    entry("One Billion Row Challenge", "one_billion_rows")
    entry("PDS-H queries", "pds_h")
  entry("Sources and licences", "licences.md", numbered = false)

nimibookCli(book)
