# Benchmarks

Well-known Polars workloads, run with Nanuq and with Python Polars on the same data.

The book's build runs each query on a small sample, to check that the two sides give the
same table. The timings come from full-size runs made on people's machines with
`scripts/bench`: each run is a timestamped JSON file in
[`results/`](https://github.com/pietroppeter/nanuq-book/tree/main/results), with the
machine's specs and the versions used, and every chapter shows all of them.
