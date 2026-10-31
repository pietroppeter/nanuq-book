import nimibook

var book = initBookWithToc:
  entry("Introduction", "index", numbered = false)
  section("Polars user guide", "user-guide/index.md"):
    entry("Basic operations", "basic_operations")
    entry("Expression expansion", "expression_expansion")
    entry("Casting", "casting")
    entry("Missing data", "missing_data")
    entry("Joins", "joins")
    entry("Concatenation", "concatenation")
  entry("Sources and licences", "licences.md", numbered = false)

nimibookCli(book)
