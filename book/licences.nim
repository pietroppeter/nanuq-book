import nanuqbook
nbInit(theme = useNimibook)

nbText: """
# Sources and licences

The book's own text and code are licensed under the [MIT licence](https://github.com/pietroppeter/nanuq-book/blob/main/LICENSE).

Ported chapters keep the licence of their source. Each one says so in the box at its top,
together with its authors and what the port changed. A source is only ported when its
licence allows it; sources without a licence are used as a list of topics at most.

| Source | Licence | Chapters | Data |
| ------ | ------- | -------- | ---- |
| [Polars user guide](https://docs.pola.rs/user-guide/), by the Polars contributors | [MIT](https://github.com/pola-rs/polars/blob/main/LICENSE) ([copy](https://github.com/pietroppeter/nanuq-book/blob/main/licenses/polars-MIT.txt)) | Joins, Concatenation | `data/polars/` (Monopoly properties, from the Polars repository, MIT) |

The datasets used by the chapters are in the [data](https://github.com/pietroppeter/nanuq-book/tree/main/data)
folder, one subfolder per source, under the licence of that source.

The book is built with [nimibook](https://github.com/pietroppeter/nimibook), whose theme
and assets have their own licences (MPL-2.0 theme, fonts under Apache 2.0 and SIL OFL 1.1,
highlight.js under BSD-3-Clause, clipboard.js and KaTeX under MIT).
"""

nbSave
