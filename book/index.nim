import nanuqbook
nbInit(theme = useNimibook)

nbText: """
# The Nanuq Book

[Nanuq](https://github.com/pietroppeter/nanuq) brings [Polars](https://pola.rs) DataFrames
to Nim. This book takes public Polars tutorials and examples and ports them to Nanuq, one
chapter at a time.

Every chapter runs: the book is built by executing each chapter's Nim code, so every
table you see was computed by Nanuq. Where it helps, the original Python is shown before
its Nim version, so you can compare the two APIs.

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
