defmodule ExaltedTest do
  use ExUnit.Case
  doctest Exalted

  test "PLS WORK" do
    :mnesia.create_schema([node()])
    :mnesia.start()
    :mnesia.create_table(:Person, [attributes: [:id, :name, :job]])   
    :mnesia.dirty_write({:Person, 1, "A", "F"})
    :mnesia.dirty_write({:Person, 2, "B", "G"})
    :mnesia.dirty_write({:Person, 3, "C", "H"}) 
    map_fun = fn (record) -> 
      tup = hd(record)
      name = elem(tup, 2)
      length(name)
    end

    reduce_fun = fn (list_of_list_of_records) ->
      list_of_list_of_records
      |> Enum.reduce(0, fn (r, acc) ->
        tup = hd(r)
        name = elem(tup, 2)
        acc = acc + length(name)
      end)
    end
    Exalted.map_reduce_query(:Person, map_fun, reduce_fun)
  end
end
