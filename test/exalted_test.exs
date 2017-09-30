defmodule ExaltedTest do
  use ExUnit.Case
  doctest Exalted

  test "greets the world" do
    assert Exalted.hello() == :world
  end
end
