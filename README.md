# Exalted

A map-reduce implementation for mnesia tables using GenServers. Tries to be as efficient as possibly by spawning workers to perform the map and reduce operations in parallel. All while iterating over the entire mnesia table while it's in memory.


Usage and Benchmarks:

Given a table:
```
:mnesia.create_schema([node()])
:mnesia.start()

:mnesia.create_table(:Product, [
  attributes: [:id, :name, :price],
  type: :ordered_set,
  disc_copies: [node()]])

Populate with 500,000 random entries ...
```
Define a map function `mnesia_record -> value`
```
iex(3)>     map_fun = fn (record) ->
...(3)>       tup = hd(record)
...(3)>       elem(tup, 3)
...(3)>     end
```
Define a reduce function `list of mnesia_records -> value`
```
iex(4)>     reduce_fun = fn (list_of_list_of_records) ->
...(4)>       list_of_list_of_records
...(4)>       |> Enum.reduce(0, fn (r, acc) ->
...(4)>         tup = hd(r)
...(4)>         price = elem(tup, 3)
...(4)>         acc = acc + price
...(4)>       end)
...(4)>     end
```

time to do a map, then a reduce on an entire table:
```
iex(12)> {time, res} = :timer.tc(fn ->  :mnesia.transaction( fn -> :mnesia.all_keys(:Product) |> Enum.map(fn (key) -> map_fun.(:mnesia.read(:Product, key)) end) |> Enum.reduce(fn(x, acc) -> x+acc end) end) end)
{855705, ...}
iex(13)> time
855705
```

time to run Exalted map-reduce job with batch size of 75:
```
iex(10)> {time, res} = :timer.tc(fn -> Exalted.map_reduce_query(:Product, map_fun, reduce_fun, 100) end)
{696800,...}
iex(11)> time
696800
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `exalted` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exalted, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/exalted](https://hexdocs.pm/exalted).
