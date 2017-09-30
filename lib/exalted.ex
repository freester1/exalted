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
    {:ok, coordinator} = GenStage.start_link(Exalted.Coordinator, {map_fun, reduce_fun})                
    do_traversal(table, :mnesia.first(table), [], batch_size, [], map_fun, reduce_fun, coordinator)
  end

  def do_traversal(table, :"$end_of_table", current_batch, batch_size, workers, map_fun, reduce_fun, coordinator_pid) do
    ## if current_batch has stuff, create map worker and reduce worker
    if length(current_batch) > 0 do
      ## add the final batch
      process_batch(current_batch, coordinator_pid)
    end
    ## wait for result
    GenServer.call(coordinator_pid, :get_results, :infinity)
  end

  def do_traversal(table, record, current_batch, batch_size, workers, map_fun, reduce_fun) do
    ## if batch size is big enough
    ## create worker
    ## else add to batch and recur
  end

  defp process_batch(batch, coordinator) do
    send(coordinator, {:process_batch, batch})
  end
end

