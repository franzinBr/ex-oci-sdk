defmodule ExOciSdk.JSON do
  @moduledoc """
  Defines the behavior for JSON encoding and decoding.
  This module provides a consistent interface for working with JSON,
  allowing different implementations (such as Jason, Poison, etc).
  """

  @type json_options :: keyword()
  @type decode_error :: Exception.t()
  @type encode_error :: Exception.t()

  @doc """
  Encodes a map into JSON as iodata.

  ## Parameters
    * `input` - Map to be encoded
    * `options` - Encoding options

  ## Raises
    * `encode_error` - If the input cannot be encoded to JSON
  """
  @callback encode_to_iodata!(
              input :: map(),
              options :: json_options()
            ) :: iodata() | no_return()

  @doc """
  Decodes JSON into an Elixir map.

  ## Parameters
    * `input` - JSON string or iodata to decode
    * `options` - Decoding options

  ## Raises
    * `decode_error` - If the input is not valid JSON
  """
  @callback decode!(
              input :: iodata(),
              options :: json_options()
            ) :: map() | no_return()
end

defmodule ExOciSdk.JSON.Jason do
  @moduledoc """
  Implementation of the JSON behavior using the Jason library.
  """
  @behaviour ExOciSdk.JSON

  @doc """
  Implementation of `encode_to_iodata!/2` using Jason.
  """
  @spec encode_to_iodata!(map(), ExOciSdk.JSON.json_options()) :: iodata() | no_return()
  defdelegate encode_to_iodata!(input, options), to: Jason

  @doc """
  Implementation of `decode!/2` using Jason.
  """
  @spec decode!(iodata(), ExOciSdk.JSON.json_options()) :: map() | no_return()
  defdelegate decode!(input, options), to: Jason
end
