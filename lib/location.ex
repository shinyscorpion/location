### Loading Location Data ###

location_dir = "./priv/countries"
country_base = location_dir <> "/base.json"
country_info = location_dir <> "/info.json"

:inets.start()
:ssl.start()
File.mkdir_p!(location_dir)

country_data =
  if File.exists?(country_base) do
    Jason.decode!(File.read!(country_base))
  else
    {:ok, {_status, _headers, content}} =
      "https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.json"
      |> String.to_charlist()
      |> :httpc.request()

    File.write!(country_base, content)
    Jason.decode!(content)
  end

country_info =
  if File.exists?(country_info) do
    Jason.decode!(File.read!(country_info))
  else
    {:ok, {_status, _headers, content}} =
      "https://raw.githubusercontent.com/annexare/Countries/master/dist/countries.min.json"
      |> String.to_charlist()
      |> :httpc.request()

    File.write!(country_info, content)
    Jason.decode!(content)
  end

countries =
  Enum.map(
    country_data,
    fn data ->
      alpha2 = data["alpha-2"]
      info = country_info[String.upcase(alpha2)] || %{}

      %{
        __struct__: Location.Country,
        name: data["name"],
        name_native: info["native"] || data["name"],
        languages: info["languages"] || [],
        code: String.to_integer(data["country-code"]),
        alpha2: data["alpha-2"],
        alpha3: data["alpha-3"],
        regions:
          ["", "sub-", "intermediate-"]
          |> Enum.map(&data["#{&1}region-code"])
          |> Enum.reject(&(&1 == ""))
          |> Enum.map(&String.to_integer/1)
      }
    end
  )

defmodule Location.Country do
  @moduledoc ~S"""
  A country based on ISO 3166.

  ## Sources

    - [Luke's ISO 3166](https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.json)
    - [Annexare Countries](https://raw.githubusercontent.com/annexare/Countries/master/dist/countries.min.json)
  """
  alias Location.Region

  @typedoc @moduledoc
  @type t :: %__MODULE__{
          name: String.t(),
          name_native: String.t(),
          code: pos_integer,
          alpha2: String.t(),
          alpha3: String.t(),
          regions: [pos_integer]
        }

  defstruct [
    :name,
    :name_native,
    :languages,
    :code,
    :alpha2,
    :alpha3,
    :regions
  ]

  @doc ~S"""
  Get the countries regions.
  """
  @spec regions(t | String.t() | nil) :: [Region.t()]
  def regions(%__MODULE__{regions: regions}), do: Enum.map(regions, &Region.find/1)
  def regions(id), do: if(c = find(id), do: regions(c), else: [])

  @doc ~S"""
  List all known countries.
  """
  @spec list :: [t]
  def list, do: unquote(Macro.escape(countries))

  @two_letter_countries ["中国", "香港", "भारत", "日本", "북한", "澳門", "नपल", "قطر", "臺灣"]

  @doc ~S"""
  Find a region based on UN M.49 number or name.
  """
  @spec find(String.t() | pos_integer) :: t | nil
  def find(code) when is_integer(code), do: lookup_code(code)

  def find(name_or_alpha_code) when is_binary(name_or_alpha_code) do
    length = String.length(name_or_alpha_code)

    cond do
      length > 3 or name_or_alpha_code in @two_letter_countries ->
        name = String.downcase(name_or_alpha_code)
        lookup_name(name) || lookup_native_name(name)

      length == 3 ->
        lookup_alpha3(String.upcase(name_or_alpha_code))

      length == 2 ->
        lookup_alpha2(String.upcase(name_or_alpha_code))

      :miss ->
        nil
    end
  end

  @doc ~S"""
  Find a region based on a given field.
  """
  @spec find_by(String.t() | pos_integer, :name | :name_native | :code | :alpha2 | :alpha3) ::
          t | nil
  def find_by(name, :name), do: lookup_name(String.downcase(name))
  def find_by(name, :name_native), do: lookup_native_name(String.downcase(name))
  def find_by(code, :code), do: lookup_code(code)
  def find_by(alpha2, :alpha2), do: lookup_alpha2(String.upcase(alpha2))
  def find_by(alpha3, :alpha3), do: lookup_alpha3(String.upcase(alpha3))

  @spec lookup_name(String.t()) :: t | nil
  Enum.each(countries, fn c ->
    defp lookup_name(unquote(String.downcase(c.name))), do: unquote(Macro.escape(c))
  end)

  defp lookup_name(_), do: nil

  @spec lookup_native_name(String.t()) :: t | nil
  Enum.each(countries, fn c ->
    defp lookup_native_name(unquote(String.downcase(c.name_native))), do: unquote(Macro.escape(c))
  end)

  defp lookup_native_name(_), do: nil

  @spec lookup_alpha2(String.t()) :: t | nil
  Enum.each(countries, fn c ->
    defp lookup_alpha2(unquote(String.upcase(c.alpha2))), do: unquote(Macro.escape(c))
  end)

  defp lookup_alpha2(_), do: nil

  @spec lookup_alpha3(String.t()) :: t | nil
  Enum.each(countries, fn c ->
    defp lookup_alpha3(unquote(String.upcase(c.alpha3))), do: unquote(Macro.escape(c))
  end)

  defp lookup_alpha3(_), do: nil

  @spec lookup_code(pos_integer) :: t | nil
  Enum.each(countries, fn c ->
    defp lookup_code(unquote(c.code)), do: unquote(Macro.escape(c))
  end)

  defp lookup_code(_), do: nil
end

regions =
  Enum.reduce(
    country_data,
    [],
    fn
      data, accumulator ->
        ["", "sub-", "intermediate-"]
        |> Enum.map(&{data["#{&1}region"], data["#{&1}region-code"]})
        |> Enum.reduce({[], nil}, fn
          {nil, _}, acc -> acc
          {"", _}, acc -> acc
          {r, c}, {a, p} -> {[{r, String.to_integer(c), p} | a], String.to_integer(c)}
        end)
        |> elem(0)
        |> Enum.reduce(accumulator, fn {region, code, parent}, acc ->
          if Enum.any?(accumulator, &(&1.code == code)) do
            acc
          else
            [
              %{
                __struct__: Location.Region,
                name: region,
                code: code,
                parent: parent
              }
              | acc
            ]
          end
        end)
    end
  )

defmodule Location.Region do
  @moduledoc ~S"""
  A region based on UN M.49.

  ## Sources

    - [Luke's ISO 3166](https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.json)
  """
  alias Location.Country

  @typedoc @moduledoc
  @type t :: %__MODULE__{
          name: String.t(),
          code: pos_integer,
          parent: pos_integer
        }

  @typedoc ~S"""
  A region identifier.

  It can be a UN M.49 number or name.
  """
  @type region_id :: pos_integer | String.t()

  defstruct [:name, :code, :parent]

  @doc ~S"""
  Find the parent region of a region.

  Returns `nil` if the region has no parent.
  """
  @spec parent(t) :: t | nil
  def parent(%__MODULE__{parent: nil}), do: nil
  def parent(%__MODULE__{parent: parent}), do: find(parent)
  def parent(lookup), do: if(r = find(lookup), do: parent(r), else: [])

  @doc ~S"""
  List all subregions of a given region.

  Returns `[]` if the region has no subregions.
  """
  @spec children(t | region_id) :: [t]
  def children(%__MODULE__{code: code}), do: Enum.filter(list(), &(&1.parent == code))
  def children(lookup), do: if(r = find(lookup), do: children(r), else: [])

  @doc ~S"""
  List all countries in a region.
  """
  @spec countries(t | region_id) :: [Country.t()]
  def countries(%__MODULE__{code: code}), do: Enum.filter(Country.list(), &(code in &1.regions))
  def countries(lookup), do: if(r = find(lookup), do: countries(r), else: [])

  @doc ~S"""
  List all known regions.
  """
  @spec list :: [t]
  def list, do: unquote(Macro.escape(regions))

  @doc ~S"""
  Find a region based on UN M.49 number or name.
  """
  @spec find(region_id) :: t | nil
  def find(name) when is_binary(name), do: lookup_name(String.downcase(name))
  def find(code) when is_integer(code), do: lookup_code(code)

  @spec lookup_name(String.t()) :: t | nil
  Enum.each(regions, fn r ->
    defp lookup_name(unquote(String.downcase(r.name))), do: unquote(Macro.escape(r))
  end)

  defp lookup_name(_), do: nil

  @spec lookup_code(pos_integer) :: t | nil
  Enum.each(regions, fn r ->
    defp lookup_code(unquote(r.code)), do: unquote(Macro.escape(r))
  end)

  defp lookup_code(_), do: nil
end
