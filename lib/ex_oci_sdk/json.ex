defmodule ExOciSdk.JSON do
  @moduledoc """
  Defines the behavior for JSON encoding and decoding.
  This module provides a consistent interface for working with JSON,
  allowing different implementations (such as Jason, Poison, Native, etc).
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

  @doc """
  defines the dependencies necessary for the module
  """
  @callback deps() :: atom() | list(atom()) | []
end

defmodule ExOciSdk.JSON.Jason do
  @moduledoc """
  Implementation of the JSON behavior using the Jason library.
  """
  @behaviour ExOciSdk.JSON

  @doc """
  Define the Jason json parser/generator as a dependency for this module
  """
  @impl true
  @spec deps() :: atom()
  def deps() do
    Jason
  end

  @doc """
  Implementation of `c:ExOciSdk.JSON.encode_to_iodata!/2` using Jason.
  """
  @impl true
  @spec encode_to_iodata!(map(), ExOciSdk.JSON.json_options()) :: iodata() | no_return()
  defdelegate encode_to_iodata!(input, options), to: Jason

  @doc """
  Implementation of `c:ExOciSdk.JSON.decode!/2` using Jason.
  """
  @impl true
  @spec decode!(iodata(), ExOciSdk.JSON.json_options()) :: map() | no_return()
  defdelegate decode!(input, options), to: Jason
end

defmodule ExOciSdk.JSON.Native do
  @moduledoc """
  Implementation of the JSON behavior using Elixir's built-in JSON module.

  This adapter provides support for the native JSON module introduced in Elixir 1.18,
  offering improved performance over external libraries.

  ## Requirements

  - Elixir 1.18.0 or later
  - Erlang/OTP 27 or later
  """
  @moduledoc since: "0.2.0"
  @compile {:no_warn_undefined, [JSON]}

  @behaviour ExOciSdk.JSON

  @doc """
  Define the JSON native parser/generator as a dependency for this module
  """
  @impl true
  @spec deps() :: atom()
  def deps() do
    JSON
  end

  @doc """
  Implementation of `c:ExOciSdk.JSON.encode_to_iodata!/2` using native JSON.
  """
  @impl true
  @spec encode_to_iodata!(map(), ExOciSdk.JSON.json_options()) :: iodata() | no_return()
  def encode_to_iodata!(input, _options) do
    JSON.encode_to_iodata!(input)
  end

  @doc """
  Implementation of `c:ExOciSdk.JSON.decode!/2` using native JSON.
  """
  @impl true
  @spec decode!(iodata(), ExOciSdk.JSON.json_options()) :: map() | no_return()
  def decode!(input, _options) do
    JSON.decode!(input)
  end
end
