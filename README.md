# nanuq-book

Public Polars tutorials and examples, ported to [Nanuq](https://github.com/pietroppeter/nanuq)
(Polars DataFrames for Nim). Built with [nimibook](https://github.com/pietroppeter/nimibook)
and published at https://pietroppeter.github.io/nanuq-book/.

Every chapter runs: building the book executes each chapter's Nim code, so the book is also
a test of Nanuq on real tutorials.

## Licences

The book's own text and code are MIT licensed (see [LICENSE](LICENSE)). A ported chapter
keeps the licence of its source and says so at its top, with the authors, a link to the
original and what the port changed. Licence texts of the sources are in [licenses/](licenses),
and datasets are in [data/](data), one subfolder per source.

Only sources whose licence allows it are ported (for example MIT, Apache-2.0, CC BY). A
CC BY-SA source makes its chapter CC BY-SA. Sources without a licence are not copied.

## Which Nanuq

Nanuq is the git submodule in `nanuq/`, pinned to a commit; `config.nims` puts
`nanuq/src` on the path. CI builds the book against the pinned commit, and once a week
(or on demand) against Nanuq's main branch, to catch API changes early. To move the pin:

```sh
git -C nanuq fetch origin main && git -C nanuq checkout origin/main
git add nanuq && git commit -m "Pin Nanuq to <commit>"
```

## Building

Needs Nim 2.x, Rust (Nanuq's development versions build the Polars wrapper from source,
which takes about 10 minutes the first time) and libpcre (for nimib's markdown).

```sh
git clone --recurse-submodules https://github.com/pietroppeter/nanuq-book
cd nanuq-book
nimble install -y --depsOnly
nimble genbook        # writes the site to docs/
```

## Adding a chapter

1. Check the source's licence (see above).
2. Write `book/<source>/<page>.nim`: start with `attribution` (see `book/nanuqbook.nim`),
   show the original Python with `python` where it helps, and port the code with `nbCode`.
   Say which sections were left out and why.
3. Add the chapter to `nbook.nim`, and the source to `book/licences.nim` and `licenses/`.
