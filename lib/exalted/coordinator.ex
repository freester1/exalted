defmodule Exalted.Coordinator do
    use GenServer

    ## entrypoint for the map-reduce operations

    ## sends necessary info to mappers, once results are received, forwards them to combiners
    ## forwards results of combiners to reducers
    ## once end-of-table is reached, a stop msg is flushed throughout mappers->combiners->reducers
    ## once all processes are done, coordinator's state is done and the results will be returned by the coordinator, fetched from ets

    ## state is {current_batch, map_fun, reduce_fun, mappers, combiners, reducers, status}
    ## status is either :working, :fin
    def start_link({current_batch, map_fun, reduce_fun}) do
        GenServer.start_link(__MODULE__, {self(), current_batch, map_fun, reduce_fun, [], [], [], :working}, [name: :"Coordinator"])        
    end

    def init({pid, current_batch, map_fun, reduce_fun, mappers, combiners, reducers, :working}) do
        {:ok, {pid, current_batch, map_fun, reduce_fun, mappers, combiners, reducers, :working}}
    end

    def handle_info({:process_batch, batch}, {pid, current_batch, map_fun, reduce_fun, mappers, combiners, reducers, :working}) do
        ### create new mapper for this batch
        {:ok, mapper} = Exalted.Mapper.start_link(batch, map_fun)
        send(mapper, :apply_map)
        {:noreply, {pid, current_batch, map_fun, reduce_fun, mappers, combiners, reducers, :working}}
    end

    def handle_info({:mapper_result, res}, {pid, current_batch, map_fun, reduce_fun, mappers, combiners, reducers, :working}) do
        ## create GenStage for combiner and reducer
    end
end