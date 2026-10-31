import nimibook

var book = initBookWithToc:
  entry("Introduction", "index", numbered = false)
  section("Polars user guide", "user-guide/index.md"):
    entry("Expressions and contexts", "expressions_and_contexts")
    entry("Lazy API", "lazy_api")
    entry("Basic operations", "basic_operations")
    entry("Expression expansion", "expression_expansion")
    entry("Casting", "casting")
    entry("Missing data", "missing_data")
    entry("Joins", "joins")
    entry("Concatenation", "concatenation")
    entry("CSV", "csv")
  section("Benchmarks", "benchmarks/index.md"):
    entry("One Billion Row Challenge", "one_billion_rows")
    entry("PDS-H queries", "pds_h")
  entry("Sources and licences", "licences.md", numbered = false)

nimibookCli(book)
