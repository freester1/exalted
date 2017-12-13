defmodule Exalted do
  @moduledoc """
  Documentation for Exalted.
  """

  @spec map_reduce_query(table :: atom, map_fun :: (any -> {any, any}), reduce_fun :: ({any, any} -> any), batch_size :: pos_integer) :: map
  def map_reduce_query(table, map_fun, reduce_fun, batch_size \\ 1) do
    {:atomic, res} = init_map_reduce_jobs(table, map_fun, reduce_fun, batch_size)
    res
  end

  defp init_map_reduce_jobs(table, map_fun, reduce_fun, batch_size) do
    {:ok, coordinator_pid} = Exalted.Coordinator.start_link({map_fun, reduce_fun})
    :mnesia.transaction(fn ->
      :mnesia.lock({:table, table}, :read)
      :mnesia.foldl(fn (rec, current_batch) ->
        record = [rec]
        if length(current_batch) == batch_size do
          process_batch(current_batch, coordinator_pid)
          [record]
        else
          [ record | current_batch ]
        end
      end, [], table)
    ## wait for result
    res = poll_until_res(coordinator_pid)
    ## kill coordinator
    GenServer.stop(coordinator_pid)
    res
    end)
  end

  defp do_traversal(table, :"$end_of_table", current_batch, batch_size, map_fun, reduce_fun, coordinator_pid) do
    if length(current_batch) > 0 do
      process_batch(current_batch, coordinator_pid)
    end
  end

  defp do_traversal(table, key, current_batch, batch_size, map_fun, reduce_fun, coordinator_pid) do
    record = :mnesia.read(table, key)
    if length(current_batch) == batch_size do
      process_batch(current_batch, coordinator_pid)
      do_traversal(table, :mnesia.next(table, key), [record], batch_size, map_fun, reduce_fun, coordinator_pid)
    else
      do_traversal(table, :mnesia.next(table, key), [ record | current_batch ], batch_size, map_fun, reduce_fun, coordinator_pid)
    end
  end

  defp process_batch(batch, coordinator) do
   send(coordinator, {:process_batch, batch})
  end

  defp poll_until_res(coordinator_pid) do
    res = GenServer.call(coordinator_pid, :compute_results, :infinity)
    if res == nil do
      poll_until_res(coordinator_pid)
    else
      is_done = GenServer.call(coordinator_pid, :is_done, :infinity)
      if is_done do
        GenServer.call(coordinator_pid, :get_results, :infinity)
      else
        poll_until_res(coordinator_pid)
      end
    end
  end
end
