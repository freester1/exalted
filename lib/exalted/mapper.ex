defmodule Exalted.Mapper do
    use GenServer

    def start_link({coordinator_pid, batch, map_fun}) do
        GenServer.start_link(__MODULE__, {coordinator_pid, batch, map_fun})        
    end

    def init({coordinator_pid, batch, map_fun}) do
        {:ok, {coordinator_pid, batch, map_fun}}
    end

    def handle_info(:apply_map, {coordinator_pid, batch, map_fun}) do
        res = batch
              |> Enum.reduce([], fn(record, acc) ->
                    [{map_fun.(record), record} | acc]
                end)
        ## send result back
        #require IEx; IEx.pry        
        send(coordinator_pid, {:mapper_result, res, self()})
        {:noreply, {coordinator_pid, batch, map_fun}}
    end
end
