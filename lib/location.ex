### Loading Location Data ###

location_dir = "./priv/countries"
country_base = location_dir <> "/base.json"
country_info = location_dir <> "/info.json"

:inets.start()
:ssl.start()
File.mkdir_p!(location_dir)

countries =
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

defmodule Location.Country do
  @moduledoc ~S"""
  A country based on ISO 3166.

  ## Sources

    - [Luke's ISO 3166](https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.json)
    - [Annexare Countries](https://raw.githubusercontent.com/annexare/Countries/master/dist/countries.min.json)
  """

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
  List all known countries.
  """
  @spec list :: [t]
  def list,
    do:
      unquote(
        countries
        |> Enum.map(fn data ->
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
        end)
        |> Macro.escape()
      )
end
