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
(or on demand) against Nanuq's main branch, to catch API changes early.

The book never builds Nanuq's Rust half: `config.nims` compiles with
`-d:nanuqLib=prebuilt`, so the Polars wrapper library is downloaded from Nanuq's
`lib-v<version>` release, and the build fails if that version is not released. Pin the
submodule to a commit whose lib version is released (usually a Nanuq release tag). The
weekly build against main fails while main has a `-dev` lib version. To move the pin:

```sh
git -C nanuq fetch origin tag v0.2.0 && git -C nanuq checkout v0.2.0
git add nanuq && git commit -m "Pin Nanuq to v0.2.0"
```

To try an unreleased Nanuq locally, build its library first
(`nimble buildRust` in `nanuq/`): a library in `nanuq/src/rust/target/release` is used
instead of the download.

## Building

Needs Nim 2.x, [uv](https://docs.astral.sh/uv/), `curl` and `tar` (to download Nanuq's
prebuilt library) and libpcre (for nimib's markdown). No Rust needed.

```sh
git clone --recurse-submodules https://github.com/pietroppeter/nanuq-book
cd nanuq-book
nimble install -y --depsOnly
uv sync                    # Python Polars, for the Python side of each example
uv run nimble genbook      # writes the site to docs/
```

Each example is shown in two tabs, Nim first and then the original Python, and both run
when the book is built: the Python code runs through [nimpy](https://github.com/yglukhov/nimpy)
with the Python Polars version pinned in `pyproject.toml`. A Python cell that ends with an
expression shows its value, as in a notebook.

## Adding a chapter

1. Check the source's licence (see above).
2. Write `book/<source>/<page>.nim` (Nim module names can't contain `-`): start with
   `attribution` (see `book/nanuqbook.nim`), and give each example as
   `tabs "<python code>": <nbCode and nbShow blocks>`. Python with no Nim version yet goes
   in `python "<code>"`. Say which sections were left out and why.
3. Add the chapter to `nbook.nim`, and the source to `book/licences.nim` and `licenses/`.
