defmodule Location.CountryTest do
  use ExUnit.Case, async: true
  alias Location.Country

  # This line is to fix Elixir coverage bug
  %Country{}

  @europe [
    %Location.Region{code: 150, name: "Europe", parent: nil},
    %Location.Region{code: 155, name: "Western Europe", parent: 150}
  ]

  describe "find/1" do
    test "by name", do: assert(Country.find("netherlands").alpha2 == "NL")
    test "by native name", do: assert(Country.find("nederland").alpha2 == "NL")
    test "by short name", do: assert(Country.find("日本").alpha2 == "JP")
    test "by alpha 2", do: assert(Country.find("nl").alpha2 == "NL")
    test "by alpha 3", do: assert(Country.find("nld").alpha2 == "NL")
    test "by code", do: assert(Country.find(528).alpha2 == "NL")
    test "nil for invalid", do: refute(Country.find("a"))
  end

  describe "find_by/2" do
    test "by name", do: assert(Country.find_by("netherlands", :name).alpha2 == "NL")
    test "by native name", do: assert(Country.find_by("nederland", :name_native).alpha2 == "NL")
    test "by alpha 2", do: assert(Country.find_by("nl", :alpha2).alpha2 == "NL")
    test "by alpha 3", do: assert(Country.find_by("nld", :alpha3).alpha2 == "NL")
    test "by code", do: assert(Country.find_by(528, :code).alpha2 == "NL")
  end

  describe "regions/1" do
    test "by country", do: assert(Country.regions(Country.find("nl")) == @europe)
    test "by lookup", do: assert(Country.regions("nl") == @europe)
  end

  describe "list/0" do
    test "all countries", do: assert(Enum.count(Country.list()) == 249)
    test "countries", do: assert(Enum.all?(Country.list(), &(&1.__struct__ == Country)))
  end
end
