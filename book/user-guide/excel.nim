import nanuqbook
bookInit()

nbText: "# Excel"

attribution userGuide("Excel", "io/excel",
  "The file is `data/polars/path.xlsx` instead of `docs/assets/data/path.xlsx`. It is written " &
  "first and then read back (the user guide reads a file it ships), and each example shows " &
  "the dataframe it makes. The pip install lines are left out.")

nbText: """
Polars can read and write to Excel files from Python. From a performance perspective, we
recommend using other formats if possible, such as Parquet or CSV files.
"""

nanuq """
Nanuq reads and writes Excel files too, inside the compiled library: it reads with
[calamine](https://github.com/tafia/calamine), the Rust crate behind Python's default
`fastexcel` engine, and writes with [rust_xlsxwriter](https://github.com/jmcnamara/rust_xlsxwriter),
the Rust port of the `xlsxwriter` library Python uses. Nothing else needs installing. The
engines below are the Python ones.
"""

nbText: """
## Write

We need the xlswriter library installed as an additional dependency to write to Excel
files.

Writing a `DataFrame` to an Excel file is done with the `write_excel` method:
"""

tabs """
import polars as pl

df = pl.DataFrame({"foo": [1, 2, 3], "bar": [None, "bak", "baz"]})
df.write_excel("data/polars/path.xlsx")
""":
  nbCode:
    import nanuq

    let written = newDataFrame(
      series("foo", [1, 2, 3]),
      series("bar", [none(string), some("bak"), some("baz")]))
    written.writeExcel("data/polars/path.xlsx")

nbText: """
The name of the worksheet can be specified with the `worksheet` argument.
"""

tabs """
df.write_excel("data/polars/path_sales.xlsx", worksheet="Sales")
""":
  nbCode:
    written.writeExcel("data/polars/path_sales.xlsx", worksheet = "Sales")

nbText: """
Polars can create rich Excel files with multiple sheets and formatting. For more details,
see the API docs for `write_excel`.

## Read

Polars does not have a native Excel reader. Instead, it uses an external library called an
"engine" to parse Excel files into a form that Polars can parse. The available engines are:

- fastexcel: This engine is based on the Rust [calamine](https://github.com/tafia/calamine)
  crate and is (by far) the fastest reader.
- xlsx2csv: This reader parses the .xlsx file to an in-memory CSV that Polars then reads
  with its own CSV reader.
- openpyxl: Typically slower than xls2csv, but can provide more flexibility for files that
  are difficult to parse.

We recommend working with the default fastexcel engine. The xlsx2csv and openpyxl engines
are slower but may have more features for parsing tricky data. These engines may be helpful
if the fastexcel reader does not work for a specific Excel file.

The default engine for reading .xlsx files is fastexcel. This engine uses the Rust calamine
crate to read .xlsx files into an Apache Arrow in-memory representation that Polars can
read without needing to copy the data.
"""

tabs """
df = pl.read_excel("data/polars/path.xlsx")
df
""":
  nbCode:
    var df = readExcel("data/polars/path.xlsx")
    nbShow df

nbText: """
We can specify the sheet name to read with the `sheet_name` argument. If we do not specify
a sheet name, the first sheet will be read.
"""

tabs """
df = pl.read_excel("data/polars/path_sales.xlsx", sheet_name="Sales")
df
""":
  nbCode:
    df = readExcel("data/polars/path_sales.xlsx", sheetName = "Sales")
    nbShow df

bookSave()
