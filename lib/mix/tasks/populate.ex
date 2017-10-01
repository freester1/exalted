defmodule Mix.Tasks.Populate do
    use Mix.Task
    def run(_) do
      :mnesia.create_schema([node()])
      :mnesia.start()
  
      case :mnesia.create_table(:Product, [
        attributes: [:id, :name, :price],
        type: :ordered_set,
        disc_copies: [node()]]) do
        {:atomic, :ok} ->
          rows = fn ->
            for i <- 0..10 do
              price = Enum.random(0..3)
              :mnesia.write({:Product, i, "", price})
            end
          end
          :mnesia.sync_transaction(rows)
        {:aborted, {:already_exists, :Product}} ->
          IO.puts("Table already exists")
          :ok
      end
      :mnesia.stop()
      :ok
    end
  end
  