defmodule Location.RegionTest do
  use ExUnit.Case, async: true
  alias Location.Region
  @europe %Location.Region{code: 150, name: "Europe", parent: nil}
  @european_regions [
    %Location.Region{code: 151, name: "Eastern Europe", parent: 150},
    %Location.Region{code: 155, name: "Western Europe", parent: 150},
    %Location.Region{code: 39, name: "Southern Europe", parent: 150},
    %Location.Region{code: 154, name: "Northern Europe", parent: 150}
  ]

  describe "find/1" do
    test "by name", do: assert(Region.find("Europe") == @europe)
    test "by name (case insensitive)", do: assert(Region.find("europe") == @europe)
    test "by code", do: assert(Region.find(150) == @europe)
  end

  describe "parent/1" do
    test "by name", do: assert(Region.parent("Western Europe") == @europe)
    test "by code", do: assert(Region.parent(155) == @europe)
    test "by region", do: assert(Region.parent(Region.find("Western Europe")) == @europe)
  end

  describe "children/1" do
    test "by name", do: assert(Region.children("Europe") == @european_regions)
    test "by code", do: assert(Region.children(150) == @european_regions)
    test "by region", do: assert(Region.children(@europe) == @european_regions)
  end

  describe "countries/1" do
    test "by name", do: assert(Enum.count(Region.countries("Europe")) == 51)
    test "by code", do: assert(Enum.count(Region.countries(150)) == 51)
    test "by region", do: assert(Enum.count(Region.countries(@europe)) == 51)
  end

  describe "list/0" do
    test "all regions", do: assert(Enum.count(Region.list()) == 30)
    test "regions", do: assert(Enum.all?(Region.list(), &(&1.__struct__ == Region)))
  end
end
