import nimibook

var book = initBookWithToc:
  entry("Introduction", "index", numbered = false)
  section("Polars user guide", "user-guide/index"):
    entry("Joins", "joins")
    entry("Concatenation", "concatenation")
  entry("Sources and licences", "licences", numbered = false)

nimibookCli(book)
