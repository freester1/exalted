defmodule Exalted do
  @moduledoc """
  Documentation for Exalted.
  """

  @spec map_reduce_query(table :: atom, map_fun :: (any -> {any, any}), reduce_fun :: ({any, any} -> any), batch_size :: pos_integer) :: {:ok, any} | {:error, any}
  def map_reduce_query(table, map_fun, reduce_fun, batch_size \\ 1) do
    :mnesia.transaction(:table, fn -> init_map_reduce_jobs(table, map_fun, reduce_fun, batch_size) end)
  end

  def init_map_reduce_jobs(table, map_fun, reduce_fun, batch_size) do
    ### traverse mnesia table
    ### create batch and send them to producer-consumer
    do_traversal(table, :mnesia.first(table), [], batch_size, [], map_fun, reduce_fun)
  end

  def do_traversal(table, :"$end_of_table", current_batch, batch_size, workers, map_fun, reduce_fun) do
    ## if current_batch has stuff, create map worker and reduce worker
    if length(current_batch) == batch_size do
      setup_workers(current_batch, map_fun, reduce_fun)
    else

    end
    ## send 'end_of_table' to all running map workers and reduce workers
  end

  def do_traversal(table, record, current_batch, batch_size, workers, map_fun, reduce_fun) do
    ## if batch size is big enough
    ## create worker
    ## else add to batch and recur
  end

  defp setup_workers(current_batch, map_fun, reduce_fun) do
    {:ok, coordinator} = GenStage.start_link(Exalted.Coordinator, current_batch, map_fun, reduce_fun)            
  end

  @spec create_batches(keys :: list(any), batch_size :: pos_integer) :: list(list(any))
  def create_batches(keys, batch_size) do
    keys
    |> Enum.reduce({[[]], 0}, fn(key, acc) ->
      if elem(acc, 1) < batch_size do
        [h | t] = elem(acc, 0)
        {[h ++ [key] | t], elem(acc, 1) + 1}
      else
        {[[key] | elem(acc, 0)], 1}
      end
    end)
    |> elem(0)
  end

  @spec apply_map_to_mnesia(key_batches :: list(list(any)), map_fun :: (any -> {any, any}), table :: atom, options :: list(atom)) :: list({any, any})
  def apply_map_to_mnesia(key_batches, map_fun, table, options \\ []) do
    key_batches
    |> Enum.reduce([], &apply_map_to_batch(&1, &2, map_fun, table))
  end

  defp apply_map_to_batch(key_batch, results, map_fun, table) do
    key_batch
    |> Enum.reduce(results, fn (key) ->
      results ++ [{map_fun.(:mnesia.dirty_read({table, key})), key}]
    end)
  end
end

