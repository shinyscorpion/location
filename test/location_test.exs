defmodule LocationTest do
  use ExUnit.Case
  doctest Location

  test "greets the world" do
    assert Location.hello() == :world
  end
end
