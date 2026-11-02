import nanuqbook
bookInit()

nbText: "# Arrow producer/consumer"

attribution userGuide("Arrow producer/consumer", "misc/arrow",
  "The pyarrow sections are kept for the Python tabs. The Nim tabs show the same exchange " &
  "through the Arrow C Data Interface, which Nanuq implements directly: a Nanuq frame is " &
  "handed to pyarrow and to Python Polars in this very page, without copying. Values are " &
  "shown instead of printed.")

# start the book's embedded Python (the uv environment) before the Nim tabs use it
discard runPython("import pyarrow")

nbText: """
## Using pyarrow

Polars can move data in and out of arrow zero copy. This can be done either via pyarrow or
natively. Let's first start by showing the pyarrow solution:
"""

tabs """
import polars as pl

df = pl.DataFrame({"foo": [1, 2, 3], "bar": ["ham", "spam", "jam"]})

arrow_table = df.to_arrow()
print(arrow_table)
""":
  nbCode:
    import nanuq, nimpy

    let df = newDataFrame:
      foo: [1, 2, 3]
      bar: ["ham", "spam", "jam"]

    let pa = pyImport("pyarrow")
    var stream = df.toArrow   # an ArrowArrayStream: the C struct Arrow tools exchange
    let arrowTable = pa.RecordBatchReader.callMethod("_import_from_c",
      cast[int](addr stream)).read_all()
    echo arrowTable

nanuq """
Nanuq's `toArrow` gives the frame as an Arrow C stream (`ArrowArrayStream`), the struct behind
Python's `__arrow_c_stream__`. The Nim tab gives its address to pyarrow, which takes the stream
over: the pyarrow table above was made by Nim code and holds Nanuq's buffers, not a copy.
Strings come out as `string_view`, the zero-copy layout of the next example.
"""

nbText: """
Or if you want to ensure the output is zero-copy:
"""

tabs """
arrow_table_zero_copy = df.to_arrow(compat_level=pl.CompatLevel.newest())
print(arrow_table_zero_copy)
""":
  nbCode:
    var stream2 = df.toArrow
    let arrowTableZeroCopy = pa.RecordBatchReader.callMethod("_import_from_c",
      cast[int](addr stream2)).read_all()
    echo arrowTableZeroCopy

nbText: """
Importing from pyarrow can be achieved with `pl.from_arrow`.
"""

tabs """
pl.from_arrow(arrow_table)
""":
  nbCode:
    var back: ArrowArrayStream
    discard arrowTable.to_reader().callMethod("_export_to_c", cast[int](addr back))
    nbShow fromArrow(back)

nanuq """
Nanuq's `fromArrow` reads an Arrow C stream (or, for a Series, an `ArrowSchema` and
`ArrowArray` pair) from any producer; here pyarrow exports the table it got above.
"""

nbText: """
## Using the Arrow PyCapsule Interface

As of Polars v1.3 and higher, Polars implements the
[Arrow PyCapsule Interface](https://arrow.apache.org/docs/format/CDataInterface/PyCapsuleInterface.html),
a protocol for sharing Arrow data across Python libraries.

### Exporting data from Polars to pyarrow

To convert a Polars `DataFrame` to a `pyarrow.Table`, use the `pyarrow.table` constructor
(this requires pyarrow v15 or higher).
"""

tabs """
import pyarrow as pa

arrow_table = pa.table(df)
print(arrow_table)
""":
  nbCode:
    var stream3 = df.toArrow
    let viaStream = pa.RecordBatchReader.callMethod("_import_from_c",
      cast[int](addr stream3)).read_all()
    echo viaStream

nbText: """
To convert a Polars `Series` to a `pyarrow.ChunkedArray`, use the `pyarrow.chunked_array`
constructor.
"""

tabs """
arrow_chunked_array = pa.chunked_array(df["foo"])
print(arrow_chunked_array)
""":
  nbCode:
    var foo = df["foo"].toArrow   # an ArrowExport: an ArrowSchema and an ArrowArray
    let arrowArray = pa.Array.callMethod("_import_from_c",
      cast[int](addr foo.array), cast[int](addr foo.schema))
    echo pa.chunked_array([arrowArray])

nbText: """
You can also pass a `Series` to the `pyarrow.array` constructor to create a contiguous array.
Note that this will not be zero-copy if the underlying `Series` had multiple chunks.
"""

tabs """
arrow_array = pa.array(df["foo"])
print(arrow_array)
""":
  nbCode:
    echo arrowArray

nanuq """
Nanuq's `Series.toArrow` joins the chunks first too, so the array is contiguous.
"""

nbText: """
### Importing data from pyarrow to Polars

We can pass the pyarrow `Table` back to Polars by using the `polars.DataFrame` constructor:
"""

tabs """
polars_df = pl.DataFrame(arrow_table)
print(polars_df)
""":
  nbCode:
    let pl = pyImport("polars")
    var stream4 = df.toArrow
    let reader = pa.RecordBatchReader.callMethod("_import_from_c", cast[int](addr stream4))
    let polarsDf = pl.DataFrame(reader.read_all())
    echo polarsDf

nanuq """
This is a Nanuq frame becoming a Python Polars frame. Both sides speak Arrow, so no table is
converted on the way, only pointers change hands.
"""

nbText: """
Similarly, we can pass the pyarrow `ChunkedArray` or `Array` back to Polars by using the
`polars.Series` constructor:
"""

tabs """
polars_series = pl.Series(arrow_chunked_array)
polars_series.to_frame()
""":
  nbCode:
    var exported: ArrowExport
    discard arrowArray.callMethod("_export_to_c",
      cast[int](addr exported.array), cast[int](addr exported.schema))
    let polarsSeries = fromArrow(exported, name = "")
    nbShow polarsSeries.toFrame

nbText: """
### Usage with other arrow libraries

There's a [growing list](https://github.com/apache/arrow/issues/39195#issuecomment-2245718008)
of libraries that support the PyCapsule Interface directly. Polars `Series` and `DataFrame`
objects work automatically with every such library.

### For library maintainers

If you're developing a library that you wish to integrate with Polars, it's suggested to
implement the
[Arrow PyCapsule Interface](https://arrow.apache.org/docs/format/CDataInterface/PyCapsuleInterface.html)
yourself. This comes with a number of benefits:

- Zero-copy exchange for both Polars Series and DataFrame
- No required dependency on pyarrow.
- No direct dependency on Polars.
- Harder to cause memory leaks than handling pointers as raw integers.
- Automatic zero-copy integration other PyCapsule Interface-supported libraries.

## Using Polars directly

Polars can also consume and export to and import from the
[Arrow C Data Interface](https://arrow.apache.org/docs/format/CDataInterface.html) directly.
This is recommended for libraries that don't support the Arrow PyCapsule Interface and want to
interop with Polars without requiring a pyarrow installation.

- To export `ArrowArray` C structs, Polars exposes: `Series._export_arrow_to_c`.
- To import an `ArrowArray` C struct, Polars exposes `Series._import_arrow_from_c`.
"""

nanuq """
This is the interface Nanuq uses: `toArrow` and `fromArrow` for Series (`ArrowSchema` +
`ArrowArray`) and for frames (`ArrowArrayStream`), plus zero-copy `view`s of numeric columns.
The Nim tabs above hand those structs to pyarrow by address, the way a C library would.
"""

bookSave()
