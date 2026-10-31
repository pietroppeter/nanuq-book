import nanuqbook
nbInit(theme = useNimibook)

nbText: """
# The Nanuq Book

[Nanuq](https://github.com/pietroppeter/nanuq) brings [Polars](https://pola.rs) DataFrames
to Nim. This book takes public Polars tutorials and examples and ports them to Nanuq, one
chapter at a time.

Every chapter runs. Each example comes in two tabs: **Nim**, computed by Nanuq, and
**Python**, the original code run with Python Polars when the book is built. Pick a tab
once and every example follows. Nanuq wraps Rust Polars 0.55, while the Python side runs
Python Polars 2.1, so small differences between the two outputs can happen.

## Sources and licences

Each ported chapter starts with a box that names its source, its authors and its licence,
and says what the port changed. The sources and their licences are listed in
[Sources and licences](licences.html). The book's own text and code are MIT licensed.

## Which version of Nanuq

Nanuq is young and its API still changes. The book is built against a pinned commit of
Nanuq, and is checked every week against Nanuq's main branch, so that changes that break a
chapter show up early.
"""

nbSave
