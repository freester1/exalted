defmodule Exalted do
  @moduledoc """
  Documentation for Exalted.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Exalted.hello
      :world

  """
  @spec map_reduce_query(table :: atom, map_fun :: (any -> {any(), any()}), reduce_fun :: ({any, any} -> any)) :: {:ok, any} | {:error, any}
  def map_reduce_query(table, mapfun, reduce_fun) do

  end
end

