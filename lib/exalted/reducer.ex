defmodule Exalted.Reducer do
    use GenServer

    def start_link({coordinator_pid, {key, results}, reduce_fun}) do
        GenServer.start_link(__MODULE__, {coordinator_pid, {key, results}, reduce_fun, :working})        
    end

    def handle_info({:add_record, record}, {coordinator_pid, {key, results}, reduce_fun, state}) do
        {:noreply, {coordinator_pid, {key, results ++ [record]}, reduce_fun, :working}}
    end

    def handle_info(:reduce, {coordinator_pid, {key, results}, reduce_fun, state}) do
        ## reduce stuff in map(key, processed_records)
        ## send results back to coordinator
        reduced_results = reduce_fun.(results)
        send(coordinator_pid, {:reducer_results, {key, reduced_results}})
        {:noreply, {coordinator_pid, {key, results}, reduce_fun, :done}}
    end

    def handle_info(:isDone, {coordinator_pid, {key, results}, reduce_fun, state}) do
        {:noreply, state == :done}
    end 
end
