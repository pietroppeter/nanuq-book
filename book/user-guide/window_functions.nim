import nanuqbook
bookInit()

nbText: "# Window functions"

attribution userGuide("Window functions", "expressions/window-functions",
  "The data is read from `data/polars/pokemon.csv`. The examples with `sort_by`, `head`, " &
  "`explode` and the `mapping_strategy` parameter run in Python only, since Nanuq does not " &
  "have them yet. The diagrams are left out.")

nbText: """
Window functions are expressions with superpowers. They allow you to perform aggregations
on groups within the context `select`. Let's get a feel for what that means.

First, we load a Pokémon dataset:
"""

tabs """
import polars as pl

types = (
    "Grass Water Fire Normal Ground Electric Psychic Fighting Bug Steel "
    "Flying Dragon Dark Ghost Poison Rock Ice Fairy".split()
)
type_enum = pl.Enum(types)
# then let's load some csv data with information about pokemon
pokemon = pl.read_csv(
    "data/polars/pokemon.csv",
).cast({"Type 1": type_enum, "Type 2": type_enum})
pokemon.head()
""":
  nbCode:
    import nanuq

    type
      PokemonType = enum
        Grass, Water, Fire, Normal, Ground, Electric, Psychic, Fighting, Bug, Steel,
        Flying, Dragon, Dark, Ghost, Poison, Rock, Ice, Fairy

    # then let's load some csv data with information about pokemon
    let pokemon = readCsv("data/polars/pokemon.csv")
      .withColumns(col("Type 1").cast(PokemonType), col("Type 2").cast(PokemonType))
    nbShow pokemon.head()

nanuq """
The Polars `Enum` is a Nim enum here, `PokemonType`, and the two columns are cast with
`withColumns`: Nanuq's frame `cast` does not take a mapping of column names to types yet.
"""

nbText: """
## Operations per group

Window functions are ideal when we want to perform an operation within a group. For
instance, suppose we want to rank our Pokémon by the column “Speed”. However, instead of a
global ranking, we want to rank the speed within each group defined by the column “Type 1”.
We write the expression to rank the data by the column “Speed” and then we add the function
`over` to specify that this should happen over the unique values of the column “Type 1”:
"""

tabs """
result = pokemon.select(
    pl.col("Name", "Type 1"),
    pl.col("Speed").rank("dense", descending=True).over("Type 1").alias("Speed rank"),
)

result
""":
  nbCode:
    var result = pokemon.select(
      col("Name", "Type 1"),
      col.Speed.rank(Dense, descending = true).over("Type 1").alias("Speed rank"))

    nbShow result

nbText: """
To help visualise this operation, you may imagine that Polars selects the subsets of the
data that share the same value for the column “Type 1” and then computes the ranking
expression only for those values. Then, the results for that specific group are projected
back to the original rows and Polars does this for all of the existing groups. In the
Polars user guide, a diagram highlights the ranking computation for the Pokémon with “Type
1” equal to “Grass”.

Note how the row for the Pokémon “Golbat” has a “Speed” value of `90`, which is greater
than the value `80` of the Pokémon “Venusaur”, and yet the latter was ranked 1 because
“Golbat” and “Venusar” do not share the same value for the column “Type 1”.

The function `over` accepts an arbitrary number of expressions to specify the groups over
which to perform the computations. We can repeat the ranking above, but over the
combination of the columns “Type 1” and “Type 2” for a more fine-grained ranking:
"""

tabs """
result = pokemon.select(
    pl.col("Name", "Type 1", "Type 2"),
    pl.col("Speed")
    .rank("dense", descending=True)
    .over("Type 1", "Type 2")
    .alias("Speed rank"),
)

result
""":
  nbCode:
    result = pokemon.select(
      col("Name", "Type 1", "Type 2"),
      col.Speed
        .rank(Dense, descending = true)
        .over(["Type 1", "Type 2"])
        .alias("Speed rank"))

    nbShow result

nanuq """
Nim's `over` takes several columns in an array, `over(["Type 1", "Type 2"])`, or
expressions, `over([col("Type 1"), col("Type 2")])`.
"""

nbText: """
In general, the results you get with the function `over` can also be achieved with
[an aggregation](https://docs.pola.rs/user-guide/expressions/aggregation/) followed by a
call to the function `explode`, although the rows would be in a different order:
"""

python """
result = (
    pokemon.group_by("Type 1")
    .agg(
        pl.col("Name"),
        pl.col("Speed").rank("dense", descending=True).alias("Speed rank"),
    )
    .select(pl.col("Name"), pl.col("Type 1"), pl.col("Speed rank"))
    .explode("Name", "Speed rank")
)

result
"""

nanuq """
This one runs in Python only: Nanuq has no list columns yet, so no `explode`.
"""

nbText: """
This shows that, usually, `group_by` and `over` produce results of different shapes:

- `group_by` usually produces a resulting dataframe with as many rows as groups used for
  aggregating; and
- `over` usually produces a dataframe with the same number of rows as the original.

The function `over` does not always produce results with the same number of rows as the
original dataframe, and that is what we explore next.

## Mapping results to dataframe rows

The function `over` accepts a parameter `mapping_strategy` that determines how the results
of the expression over the group are mapped back to the rows of the dataframe.

### `group_to_rows`

The default behaviour is `"group_to_rows"`: the result of the expression over the group
should be the same length as the group and the results are mapped back to the rows of that
group.

If the order of the rows is not relevant, the option `"explode"` is more performant.
Instead of mapping the resulting values to the original rows, Polars creates a new
dataframe where values from the same group are next to each other. To help understand the
distinction, consider the following dataframe:
"""

tabs """
athletes = pl.DataFrame(
    {
        "athlete": list("ABCDEF"),
        "country": ["PT", "NL", "NL", "PT", "PT", "NL"],
        "rank": [6, 1, 5, 4, 2, 3],
    }
)
athletes
""":
  nbCode:
    let athletes = newDataFrame:
      athlete: ["A", "B", "C", "D", "E", "F"]
      country: ["PT", "NL", "NL", "PT", "PT", "NL"]
      rank: [6, 1, 5, 4, 2, 3]
    nbShow athletes

nanuq """
Nanuq has no `sort_by` on expressions and no `mapping_strategy` yet, so the examples of
this section run in Python only. The one that Nanuq can write, the default
`group_to_rows`, needs `sort_by`.
"""

nbText: """
We can sort the athletes by rank within their own countries. If we do so, the Dutch
athletes were in the second, third, and sixth, rows, and they will remain there. What will
change is the order of the names of the athletes, which goes from “B”, “C”, and “F”, to
“B”, “F”, and “C”:
"""

python """
result = athletes.select(
    pl.col("athlete", "rank").sort_by(pl.col("rank")).over(pl.col("country")),
    pl.col("country"),
)

result
"""

nbText: """
### `explode`

If we set the parameter `mapping_strategy` to `"explode"`, then athletes of the same
country are grouped together, but the final order of the rows – with respect to the
countries – will not be the same.

Because Polars does not need to keep track of the positions of the rows of each group,
using `"explode"` is typically faster than `"group_to_rows"`. However, using `"explode"`
also requires more care because it implies reordering the other columns that we wish to
keep. The code that produces this result follows
"""

python """
result = athletes.select(
    pl.all()
    .sort_by(pl.col("rank"))
    .over(pl.col("country"), mapping_strategy="explode"),
)

result
"""

nbText: """
### `join`

Another possible value for the parameter `mapping_strategy` is `"join"`, which aggregates
the resulting values in a list and repeats the list over all rows of the same group:
"""

python """
result = athletes.with_columns(
    pl.col("rank").sort().over(pl.col("country"), mapping_strategy="join"),
)

result
"""

nbText: """
## Windowed aggregation expressions

In case the expression applied to the values of a group produces a scalar value, the
scalar is broadcast across the rows of the group:
"""

tabs """
result = pokemon.select(
    pl.col("Name", "Type 1", "Speed"),
    pl.col("Speed").mean().over(pl.col("Type 1")).alias("Mean speed in group"),
)

result
""":
  nbCode:
    result = pokemon.select(
      col("Name", "Type 1", "Speed"),
      col.Speed.mean.over([col("Type 1")]).alias("Mean speed in group"))

    nbShow result

nbText: """
## More examples

For more exercises, below are some window functions for us to compute:

- sort all Pokémon by type;
- select the first `3` Pokémon per type as `"Type 1"`;
- sort the Pokémon within a type by speed in descending order and select the first `3` as
  `"fastest/group"`;
- sort the Pokémon within a type by attack in descending order and select the first `3` as
  `"strongest/group"`; and
- sort the Pokémon within a type by name and select the first `3` as `"sorted_by_alphabet"`.
"""

python """
result = pokemon.sort("Type 1").select(
    pl.col("Type 1").head(3).over("Type 1", mapping_strategy="explode"),
    pl.col("Name")
    .sort_by(pl.col("Speed"), descending=True)
    .head(3)
    .over("Type 1", mapping_strategy="explode")
    .alias("fastest/group"),
    pl.col("Name")
    .sort_by(pl.col("Attack"), descending=True)
    .head(3)
    .over("Type 1", mapping_strategy="explode")
    .alias("strongest/group"),
    pl.col("Name")
    .sort()
    .head(3)
    .over("Type 1", mapping_strategy="explode")
    .alias("sorted_by_alphabet"),
)
result
"""

nanuq """
Python only as well: these need `sort_by`, `head` on expressions and `mapping_strategy`.
"""

bookSave()
