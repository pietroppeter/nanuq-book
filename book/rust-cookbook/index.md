# Polars Rust cookbook

Nanuq binds the Rust `polars` crate, and the crate's documentation has two short cookbooks,
[eager](https://docs.rs/polars/latest/polars/docs/eager/index.html) and
[lazy](https://docs.rs/polars/latest/polars/docs/lazy/index.html), in the Polars repository
under the MIT licence. These chapters port them from the
[py-2.1.0 sources](https://github.com/pola-rs/polars/tree/py-2.1.0/crates/polars/src/docs),
the Polars version Nanuq 0.6 pins.

Each recipe has three tabs: the Nim port, the original Rust, and a Python version. The Rust
is shown and not run, because the book never builds Rust; the Nim and Python code run when
the book is built, and their results are compared. Where the Rust only computes values, the
ports end by showing some of them.

The cookbooks are older than the Polars they ship with, and a few snippets no longer run
as written or show results the code doesn't give. The boxes marked “Nanuq” point those out,
next to how Nanuq differs.
