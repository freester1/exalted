defmodule ExaltedTest do
  use ExUnit.Case
  doctest Exalted

  test "test that the map reducer does something" do
    ## Records made with :mnesia.write({Product, i, "", price})
    map_fun = fn (record) -> 
      tup = hd(record)
      elem(tup, 3)
    end

    reduce_fun = fn (list_of_list_of_records) ->
      list_of_list_of_records
      |> Enum.reduce(0, fn (r, acc) ->
        tup = hd(r)
        price = elem(tup, 3)
        acc = acc + price
      end)
    end
    assert Exalted.map_reduce_query(:Product, map_fun, reduce_fun, 10) |> Map.keys |> length > 0
  end
end
