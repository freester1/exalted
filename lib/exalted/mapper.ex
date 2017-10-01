defmodule Exalted.Mapper do
    use GenServer

    def start_link({coordinator_pid, batch, map_fun}) do
        GenServer.start_link(__MODULE__, {coordinator_pid, batch, map_fun})        
    end

    def init({coordinator_pid, batch, map_fun}) do
        {:producer, {coordinator_pid, batch, %{}, map_fun}}
    end

    def handle_info(:apply_map, {coordinator_pid, batch, map_fun}) do
        res = batch
              |> Enum.reduce(%{}, fn(record, acc) ->
                    Map.put(acc, map_fun.(record), record)
                end)
        ## send result back
        send(coordinator_pid, {:mapper_result, res, self()})
        {:noreply, res, {coordinator_pid, batch, map_fun}}
    end
end
