# Exalted

A map-reduce implementation for mnesia tables using GenServers. Tries to be as efficient as possibly by utilizing `:mnesia.first` and `:mnesia.next` to do everything in one pass. Benchmarks / docs soon.


Usage and Benchmarks:

```
:mnesia.create_schema([node()])
:mnesia.start()
  
:mnesia.create_table(:Product, [
  attributes: [:id, :name, :price],
  type: :ordered_set,
  disc_copies: [node()]])

Populate with 1000 random entries ...
  

iex(3)>     map_fun = fn (record) -> 
...(3)>       tup = hd(record)
...(3)>       elem(tup, 3)
...(3)>     end
#Function<6.99386804/1 in :erl_eval.expr/5>
iex(4)>     reduce_fun = fn (list_of_list_of_records) ->
...(4)>       list_of_list_of_records
...(4)>       |> Enum.reduce(0, fn (r, acc) ->
...(4)>         tup = hd(r)
...(4)>         price = elem(tup, 3)
...(4)>         acc = acc + price
...(4)>       end)
...(4)>     end

... time to do a hand-rolled map reduce:

iex(15)> Benchwarmer.benchmark(fn -> :mnesia.transaction( fn -> :mnesia.all_keys(:Product) |> Enum.map(fn (key) -> map_fun.(:mnesia.read(:Product, key)) end) |> Enum.reduce(fn(x, acc) -> x+acc end) end)  end)
*** #Function<20.99386804/0 in :erl_eval.expr/5> ***
1.6 sec    255 iterations   6411.87 μs/op

[%Benchwarmer.Results{args: [], duration: 1635025,
  function: #Function<20.99386804/0 in :erl_eval.expr/5>, n: 255, prev_n: 128}]

  
... time to run entire map-reduce job with batch size of 100:

iex(19)> Benchwarmer.benchmark(fn -> Exalted.map_reduce_query(:Product, map_fun, reduce_fun, 100) end)
*** #Function<20.99386804/0 in :erl_eval.expr/5> ***
1.2 sec     63 iterations   19854.86 μs/op

[%Benchwarmer.Results{args: [], duration: 1250856,
  function: #Function<20.99386804/0 in :erl_eval.expr/5>, n: 63, prev_n: 32}]
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

