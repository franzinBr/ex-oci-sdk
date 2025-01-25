defmodule ExOciSdk.KeyConverter do
  @moduledoc """
  Internal module for handling key format conversions between Elixir and OCI API conventions.

  This module is responsible for automatically converting map keys between Elixir's snake_case convention
  and OCI API's camelCase requirement.

  ## Key Features

    * Automatic conversion of map keys for API requests (snake_case -> camelCase)
    * Automatic conversion of API responses (camelCase -> snake_case)
    * Automatic conversion key from atom to string
    * Proper handling of common OCI API patterns including acronyms (e.g., OCID, VCN, NAT)
    * No modification of map values, only keys are transformed


  ## Examples

      iex> map = %{user_name: "Maria", address_info: %{street_name: "Lagoa 51"}}
      iex> ExOciSdk.KeyConverter.snake_to_camel(map)
      %{"userName" => "Maria", "addressInfo" => %{"streetName" => "Lagoa 51"}}

      iex> map = %{userName: "Maria", addressInfo: %{streetName: "Lagoa 51"}}
      iex> ExOciSdk.KeyConverter.camel_to_snake(map)
      %{"user_name" => "Maria", "address_info" => %{"street_name" => "Lagoa 51"}}
  """

  @type direction :: :snake_to_camel | :camel_to_snake
  @type convertible :: String.t() | atom()

  @doc """
  Converts all keys in a map from snake_case to camelCase format.
  Works recursively on nested maps and lists.
  """
  @spec snake_to_camel(map() | term()) :: map() | term()
  def snake_to_camel(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {to_camel_case(key), convert_value(value, :snake_to_camel)}
    end)
  end

  def snake_to_camel(value), do: value

  @doc """
  Converts all keys in a map from camelCase to snake_case format.
  Works recursively on nested maps and lists.
  """
  @spec camel_to_snake(map() | term()) :: map() | term()
  def camel_to_snake(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {to_snake_case(key), convert_value(value, :camel_to_snake)}
    end)
  end

  def camel_to_snake(value), do: value

  @doc false
  @spec convert_value(map() | list() | term(), direction()) :: map() | list() | term()
  defp convert_value(value, direction) when is_map(value) do
    case direction do
      :snake_to_camel -> snake_to_camel(value)
      :camel_to_snake -> camel_to_snake(value)
    end
  end

  defp convert_value(value, direction) when is_list(value) do
    case direction do
      :snake_to_camel -> Enum.map(value, &convert_value(&1, :snake_to_camel))
      :camel_to_snake -> Enum.map(value, &convert_value(&1, :camel_to_snake))
    end
  end

  defp convert_value(value, _direction), do: value

  @spec to_camel_case(convertible()) :: String.t()
  defp to_camel_case(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> do_to_camel_case()
  end

  defp to_camel_case(key) when is_binary(key), do: do_to_camel_case(key)

  @spec do_to_camel_case(String.t()) :: String.t()
  defp do_to_camel_case(""), do: ""
  defp do_to_camel_case("_" <> rest), do: do_to_camel_case(rest)

  defp do_to_camel_case(string) do
    case String.split(string, "_", trim: true) do
      [] -> ""
      [first | rest] -> first <> camelize(rest)
    end
  end

  @spec camelize([String.t()]) :: String.t()
  defp camelize([]), do: ""
  defp camelize([h | t]) when h != "", do: String.capitalize(h) <> camelize(t)
  defp camelize([_ | t]), do: camelize(t)

  @spec to_snake_case(convertible()) :: String.t()
  defp to_snake_case(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> do_to_snake_case()
  end

  defp to_snake_case(key) when is_binary(key), do: do_to_snake_case(key)

  @spec do_to_snake_case(String.t()) :: String.t()
  defp do_to_snake_case(""), do: ""

  defp do_to_snake_case(string) do
    string
    |> String.replace(~r/([a-z\d])([A-Z])/, "\\1_\\2")
    |> String.replace(~r/([A-Z]+)([A-Z][a-z])/, "\\1_\\2")
    |> String.downcase()
  end
end
