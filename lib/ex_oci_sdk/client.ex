# Copyright 2025 Alan Franzin. Licensed under Apache-2.0.

defmodule ExOciSdk.Client do
  @moduledoc """
  Main client for interacting with the OCI API.
  Manages configurations, HTTP client, and JSON serialization.
  """

  alias ExOciSdk.Config

  defstruct [
    :config,
    http_client: {ExOciSdk.HTTPClient.Hackney, []},
    json: {ExOciSdk.JSON.Jason, []}
  ]

  @type client_option :: {module(), keyword()}
  @type create_opts :: [
          http_client: client_option(),
          json: client_option()
        ]

  @type t :: %__MODULE__{
          config: Config.t(),
          http_client: client_option(),
          json: client_option()
        }

  @doc """
  Creates a new instance of the OCI client.

  ## Parameters

    * `config` - Required configuration for the client
    * `opts` - Optional parameters to customize the client
      * `:http_client` - Tuple with {module, options} for the HTTP client. Module must implements `ExOciSdk.HTTPClient`
      * `:json` - Tuple with {module, options} for JSON serialization. Module must implements `ExOciSdk.JSON`

  ## Returns
    * `t:t/0` - The configuration struct

  ## Raises
    * `ArgumentError` if any of the provided options are invalid
  """
  @spec create!(Config.t(), create_opts()) :: t() | no_return()
  def create!(%Config{} = config, opts \\ []) do
    http_client =
      Keyword.get(opts, :http_client, {ExOciSdk.HTTPClient.Hackney, []})
      |> validate_module_option!(:http_client, ExOciSdk.HTTPClient)

    json =
      Keyword.get(opts, :json, {ExOciSdk.JSON.Jason, []})
      |> validate_module_option!(:json, ExOciSdk.JSON)

    %__MODULE__{
      config: config,
      http_client: http_client,
      json: json
    }
  end

  @spec validate_module_option!(client_option(), atom(), module()) ::
          client_option() | no_return()
  defp validate_module_option!({module, opts} = client, name, should_implements)
       when is_atom(module) and is_list(opts) do
    unless implements?(module, should_implements) do
      raise ArgumentError, """
      Invalid #{name} module: #{inspect(module)}
      The module must implement the #{inspect(should_implements)} behaviour
      """
    end

    # TODO: find a way to create a unit test to this raise without compiler throw warnings
    unless function_exported?(module, :deps, 0) do
      raise ArgumentError, """
      Invalid #{name} module: #{inspect(module)}
      The module must implement the deps/0 function
      """
    end

    module_deps = apply(module, :deps, [])
    module_deps = if is_list(module_deps), do: module_deps, else: [module_deps]

    non_loaded_modules_deps = Enum.filter(module_deps, &(not Code.ensure_loaded?(&1)))

    unless non_loaded_modules_deps == [] do
      raise ArgumentError, """
      The #{name} module: #{inspect(module)} depends on #{inspect(non_loaded_modules_deps)}
      Please ensure that the dependencies are correctly installed
      """
    end

    module_deps
    |> Enum.map(&Application.ensure_all_started/1)

    client
  end

  defp validate_module_option!(value, name, _should_implements) do
    raise ArgumentError, """
    Invalid #{name} option: #{inspect(value)}
    Expected a tuple of {module, keyword_list}
    """
  end

  @spec implements?(module(), module()) :: boolean()
  defp implements?(module, should_implements) do
    try do
      should_implements in (module.module_info(:attributes)[:behaviour] || [])
    rescue
      UndefinedFunctionError -> false
    end
  end
end
