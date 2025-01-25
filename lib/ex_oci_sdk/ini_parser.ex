defmodule ExOciSdk.INIParser do
  @moduledoc """
  A parser for INI configuration files.
  Supports:
  - Sections with properties
  - Comments (starting with ; or #)
  - Basic data types (strings, numbers, booleans)
  - Nested sections
  """

  @type ini_value :: String.t() | boolean() | integer() | float()
  @type ini_section :: %{String.t() => ini_value()}
  @type ini_data :: %{String.t() => ini_section() | ini_value()}
  @type parse_result :: {:ok, ini_data()} | {:error, String.t()}

  @doc """
  Parses an INI file from the given path.

  """
  @spec parse_file(String.t()) :: parse_result()
  def parse_file(path) when is_binary(path) do
    case File.read(path) do
      {:ok, content} -> parse(content)
      {:error, reason} -> {:error, "Failed to read file: #{reason}"}
    end
  end

  @doc """
  Parses an INI file string into a map structure.

  ## Examples
      iex> content = \"\"\"
      ...> [section1]
      ...> key1 = value1
      ...> key2 = 0
      ...>
      ...> [section2]
      ...> enabled = true
      ...> \"\"\"
      iex> ExOciSdk.INIParser.parse(content)
      {:ok, %{
        "section1" => %{
          "key1" => "value1",
          "key2" => 0
        },
        "section2" => %{
          "enabled" => true
        }
      }}
  """
  @spec parse(String.t()) :: parse_result()
  def parse(content) when is_binary(content) do
    try do
      result =
        content
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&ignore_line?/1)
        |> parse_lines(%{}, nil)

      {:ok, result}
    rescue
      e in ArgumentError -> {:error, "Failed to parse INI content: #{Exception.message(e)}"}
    end
  end

  @spec ignore_line?(String.t()) :: boolean()
  defp ignore_line?(""), do: true
  defp ignore_line?("#" <> _), do: true
  defp ignore_line?(";" <> _), do: true
  defp ignore_line?(line), do: String.trim(line) == ""

  @spec parse_lines([String.t()], ini_data(), String.t() | nil) :: ini_data()
  defp parse_lines([], acc, _current_section), do: acc

  defp parse_lines([line | rest], acc, current_section) do
    cond do
      String.starts_with?(line, "[") && String.ends_with?(line, "]") ->
        case validate_section(line) do
          {:ok, section} ->
            parse_lines(rest, Map.put_new(acc, section, %{}), section)

          {:error, reason} ->
            raise ArgumentError, "Invalid section format: #{reason}"
        end

      String.contains?(line, "=") ->
        case validate_key_value(line) do
          {:ok, key, value} ->
            parsed_value = parse_value(value)

            if current_section do
              section_content = Map.get(acc, current_section, %{})
              updated_section = Map.put(section_content, key, parsed_value)
              parse_lines(rest, Map.put(acc, current_section, updated_section), current_section)
            else
              parse_lines(rest, Map.put(acc, key, parsed_value), current_section)
            end

          {:error, reason} ->
            raise ArgumentError, "Invalid key-value format: #{reason}"
        end

      true ->
        raise ArgumentError, "Invalid line format: #{line}"
    end
  end

  @spec validate_section(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp validate_section(line) do
    section = line |> String.slice(1..-2//1) |> String.trim()

    if String.length(section) > 0 do
      {:ok, section}
    else
      {:error, "Empty section name"}
    end
  end

  @spec validate_key_value(String.t()) :: {:ok, String.t(), String.t()} | {:error, String.t()}
  defp validate_key_value(line) do
    parts = String.split(line, "=", parts: 2)

    case parts do
      [key, value] ->
        key = String.trim(key)
        value = String.trim(value)

        if String.length(key) > 0 do
          {:ok, key, value}
        else
          {:error, "Empty key"}
        end

    end
  end

  @spec parse_value(String.t()) :: ini_value()
  defp parse_value(value) do
    cond do
      value == "true" -> true
      value == "false" -> false
      String.match?(value, ~r/^\d+$/) -> String.to_integer(value)
      String.match?(value, ~r/^\d+\.\d+$/) -> String.to_float(value)
      true -> value
    end
  end
end
