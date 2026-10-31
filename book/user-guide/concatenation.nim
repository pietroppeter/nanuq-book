import nanuqbook
nbInit(theme = useNimibook)
bookStyle()

nbText: "# Concatenation"

attribution userGuide("Concatenation", "transformations/concatenation",
  "Left out: the section on rechunking, since Nanuq's `concat` has no `rechunk` option yet.")

nbText: """
There are a number of ways to concatenate data from separate DataFrames:

- two dataframes with **the same columns** can be **vertically** concatenated to make a
  **longer** dataframe
- two dataframes with **non-overlapping columns** can be **horizontally** concatenated to
  make a **wider** dataframe
- two dataframes with **different numbers of rows and columns** can be **diagonally**
  concatenated to make a dataframe which might be longer and/or wider. Where column names
  overlap values will be vertically concatenated. Where column names do not overlap new rows
  and columns will be added. Missing values will be set as `null`

In Nanuq `concat` takes the frames as an array and the method as a value of the enum
`ConcatMethod`, where Python uses strings (`how="vertical"`).

## Vertical concatenation: getting longer

In a vertical concatenation you combine all of the rows from a list of DataFrames into a
single longer DataFrame.
"""

python """
df_v1 = pl.DataFrame({"a": [1], "b": [3]})
df_v2 = pl.DataFrame({"a": [2], "b": [4]})
df_vertical_concat = pl.concat([df_v1, df_v2], how="vertical")
"""

nbCode:
  import nanuq
  let dfV1 = newDataFrame(series("a", [1]), series("b", [3]))
  let dfV2 = newDataFrame(series("a", [2]), series("b", [4]))
  let dfVerticalConcat = concat([dfV1, dfV2], how = Vertical)
nbShow dfVerticalConcat

nbText: """
Vertical concatenation fails when the dataframes do not have the same column names.

## Horizontal concatenation: getting wider

In a horizontal concatenation you combine all of the columns from a list of DataFrames into
a single wider DataFrame.
"""

python """
df_h1 = pl.DataFrame({"l1": [1, 2], "l2": [3, 4]})
df_h2 = pl.DataFrame({"r1": [5, 6], "r2": [7, 8], "r3": [9, 10]})
df_horizontal_concat = pl.concat([df_h1, df_h2], how="horizontal")
"""

nbCode:
  let dfH1 = newDataFrame(series("l1", [1, 2]), series("l2", [3, 4]))
  let dfH2 = newDataFrame(series("r1", [5, 6]), series("r2", [7, 8]), series("r3", [9, 10]))
  let dfHorizontalConcat = concat([dfH1, dfH2], how = Horizontal)
nbShow dfHorizontalConcat

nbText: """
Horizontal concatenation fails when dataframes have overlapping columns.
"""

nbText: """
## Diagonal concatenation: getting longer, wider and `null`ier

In a diagonal concatenation you combine all of the rows and columns from a list of
DataFrames into a single longer and/or wider DataFrame.
"""

python """
df_d1 = pl.DataFrame({"a": [1], "b": [3]})
df_d2 = pl.DataFrame({"a": [2], "d": [4]})
df_diagonal_concat = pl.concat([df_d1, df_d2], how="diagonal")
"""

nbCode:
  let dfD1 = newDataFrame(series("a", [1]), series("b", [3]))
  let dfD2 = newDataFrame(series("a", [2]), series("d", [4]))
  let dfDiagonalConcat = concat([dfD1, dfD2], how = Diagonal)
nbShow dfDiagonalConcat

nbText: """
Diagonal concatenation generates nulls when the column names do not overlap.

When the dataframe shapes do not match and we have an overlapping semantic key then
[we can join the dataframes](joins.html) instead of concatenating them.
"""

nbSave
