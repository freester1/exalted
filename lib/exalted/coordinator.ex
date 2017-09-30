defmodule Exalted.Coordinator do
    use GenServer

    ## entrypoint for the map-reduce operations

    ## sends necessary info to mappers, once results are received, forwards them to combiners
    ## forwards results of combiners to reducers
    ## once end-of-table is reached, a stop msg is flushed throughout mappers->reducers
    ## once all processes are done, coordinator's state is done and the results will be returned by the coordinator, fetched from ets

    ## state is {current_batch, map_fun, reduce_fun, reducers, results, status}
    ## status is either :working, :fin
    def start_link({map_fun, reduce_fun}) do
        GenServer.start_link(__MODULE__, {self(), [], map_fun, reduce_fun, %{}, %{}, :working}, [name: :"Coordinator"])        
    end

    def init({pid, current_batch, map_fun, reduce_fun, reducers, results, :working}) do
        {:ok, {pid, current_batch, map_fun, reduce_fun, reducers, results, :working}}
    end

    def handle_info({:process_batch, batch}, {pid, current_batch, map_fun, reduce_fun, reducers, results, :working}) do
        ### create new mapper for this batch
        {:ok, mapper_pid} = Exalted.Mapper.start_link(batch, map_fun)
        send(mapper_pid, :apply_map)

        {:noreply, {pid, current_batch, map_fun, reduce_fun, reducers, results, :working}}
    end

    def handle_info({:mapper_result, res, mapper_pid}, {pid, current_batch, map_fun, reduce_fun, reducers, results, :working}) do
        ## create reducer for this key if it doesn't exist
        res
        |> Enum.reduce(reducers, fn(record_res, reducers) ->
            if Map.has_key?(reducers, elem(0, record_res)) do
                reducers
            else 
                ## make a new reducer for this key
                {:ok, reducer_pid} = Exalted.Reducer.start_link({self(), record_res, reduce_fun})
                Map.put(reducer_pid, elem(0, record_res), pid)
            end
        end)

        ## kill mapper
        GenServer.stop(mapper_pid)
    end

    def handle_info({:reducer_result, {key, reduced_results}}, {pid, current_batch, map_fun, reduce_fun, reducers, results, state}) do
        # add result to our map
        {:noreply, {pid, current_batch, map_fun, reduce_fun, reducers, Map.put(results, key, reduced_results), state}}
    end
end