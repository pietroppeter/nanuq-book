import nimibook

var book = initBookWithToc:
  entry("Introduction", "index", numbered = false)
  section("Polars user guide", "user-guide/index.md"):
    entry("Joins", "joins")
    entry("Concatenation", "concatenation")
    entry("Expression expansion", "expression_expansion")
  entry("Sources and licences", "licences.md", numbered = false)

nimibookCli(book)
