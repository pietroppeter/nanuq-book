import nimibook

var book = initBookWithToc:
  entry("Introduction", "index", numbered = false)
  section("Polars user guide", "user-guide/index"):
    entry("Joins", "joins")
    entry("Concatenation", "concatenation")
    entry("Expression expansion", "expression_expansion")
  entry("Sources and licences", "licences", numbered = false)

nimibookCli(book)
