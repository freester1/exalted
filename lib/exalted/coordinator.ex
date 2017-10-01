defmodule Exalted.Coordinator do
    use GenServer

    ## entrypoint for the map-reduce operations

    def start_link({map_fun, reduce_fun}) do
        GenServer.start_link(__MODULE__, {[], map_fun, reduce_fun, %{}, %{}, :working}, [name: :"Coordinator"])        
    end

    def init({current_batch, map_fun, reduce_fun, reducers, results, :working}) do
        {:ok, {current_batch, map_fun, reduce_fun, reducers, results, :working}}
    end

    def handle_info({:process_batch, batch}, {current_batch, map_fun, reduce_fun, reducers, results, :working}) do
        ## create new mapper for this batch
        {:ok, mapper_pid} = Exalted.Mapper.start_link({self(), batch, map_fun})
        send(mapper_pid, :apply_map)

        {:noreply, {current_batch, map_fun, reduce_fun, reducers, results, :working}}
    end

    def handle_info({:mapper_result, res, mapper_pid}, {current_batch, map_fun, reduce_fun, reducers, results, :working}) do
        ## create reducer for this key if it doesn't exist
        res
        |> Enum.reduce(reducers, fn(record_res, acc) ->
            if Map.has_key?(acc, elem(record_res, 0)) do
                ## add this record to reducer
                send(Map.get(acc, elem(record_res, 0)), {:add_record, elem(record_res, 1)})
                reducers
            else 
                ## make a new reducer for this key
                {:ok, reducer_pid} = Exalted.Reducer.start_link({self(), record_res, reduce_fun})
                Map.put(acc, elem(record_res, 0), reducer_pid)
            end
        end)

        ## kill mapper
        GenServer.stop(mapper_pid)
    end

    def handle_info({:reducer_result, {key, reduced_results}}, {current_batch, map_fun, reduce_fun, reducers, results, state}) do
        # add result to our map
        {:noreply, {current_batch, map_fun, reduce_fun, reducers, Map.put(results, key, reduced_results), state}}
    end

    def handle_call(:get_results, {current_batch, map_fun, reduce_fun, reducers, results, state}) do
        ## poll until all reducers are done
        Enum.each(reducers, fn(reducer) -> 
            pid = elem(reducer, 1)
            send(pid, :reduce)
        end)
        poll_until_done(reducers)
    end

    defp poll_until_done(reducers) do
        if length(reducers) == 0 do
            true
        else
            not_done = reducers
                   |> Enum.filter(fn(reducer) ->
                    reducer_pid = elem(reducer, 1)
                    if GenServer.call(reducer_pid, :is_done) do
                        GenServer.stop(reducer_pid)
                        true
                    else
                        false
                    end
                   end)
        poll_until_done(not_done)
        end
    end
end
