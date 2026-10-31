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
expression shows its value, as in a notebook. When it shows a DataFrame, the build
checks that the Nim tab shows the same table (its last one, compared as HTML, rows in
any order) and fails if they differ.

## Benchmarks

Benchmark chapters (in `book/benchmarks/`) build in two ways. The normal build, and CI,
run their queries on a small sample only (to check Nim against Python) and show every
result file in `results/<benchmark>/`. A full run happens only on your machine:

```sh
scripts/bench 1brc                                              # one billion rows
scripts/bench 1brc -d:benchRows=100000000 -d:benchLabel=my-mac  # fewer rows, named machine
scripts/bench pdsh -d:benchScale=10                             # PDS-H at scale factor 10
```

It builds the chapter with `-d:bench`, which generates the data in `bench-data/` (ignored
by git), times the Nim and Python queries, writes a timestamped JSON file with the
timings, the machine's specs and the versions to `results/<benchmark>/`, and commits it.
The queries themselves live in `bench/`, one Nim module and one Python module each.

The look follows the Nanuq dev log (its palette, fonts and code cells) on top of
nimibook's layout; the styles and script are in `theme/`, and every Nim page ends with a
"Show source" button.

## Adding a chapter

1. Check the source's licence (see above).
2. Write `book/<source>/<page>.nim` (Nim module names can't contain `-`): start with
   `import nanuqbook`, `bookInit()` and `attribution` (see `book/nanuqbook.nim`), end with
   `bookSave()` (it adds the "Show source" button), and give each example as
   `tabs "<python code>": <nbCode blocks>`, with `nbShow` inside the `nbCode` so readers
   see it. Python with no Nim version yet goes in `python "<code>"`. Keep the text of the
   original as it is; every remark of the book (how Nanuq differs, what it lacks, which
   sections were left out and why) goes in `nanuq "<markdown>"`, which renders as a
   separate "🐻‍❄️ Nanuq" box.
3. Add the chapter to `nbook.nim`, and the source to `book/licences.md` and `licenses/`.

Pages that run no code (section intros, the licences page) are plain Markdown (`.md`),
which nimibook renders as they are. The look and the tabs/theme script live in `theme/`
and are added to nimibook's assets by `nimble genbook`, so they apply to every page.
