defmodule RoseTest do
  use ExUnit.Case
  doctest Rose

  test "greets the world" do
    assert Rose.hello() == :world
  end
end
