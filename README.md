# Exalted

A map-reduce implementation for mnesia tables. Tries to be as efficient as possibly by utilizing `:mnesia.first` and `:mnesia.next` to do everything in one pass. Benchmarks soon.

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

