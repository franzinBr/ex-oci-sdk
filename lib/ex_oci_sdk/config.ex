# Copyright 2025 Alan Franzin. Licensed under Apache-2.0.

defmodule ExOciSdk.Config do
  alias ExOciSdk.INIParser

  @moduledoc """
  Provides configuration structure and validation for Oracle Cloud Infrastructure (OCI) credentials.

  This module manages the configuration required for authenticating with OCI services,
  including user, tenancy information, and private key authentication.
  """

  @enforce_keys [:user, :fingerprint, :tenancy, :region, :key_content]
  defstruct [
    :user,
    :fingerprint,
    :tenancy,
    :region,
    :key_content
  ]

  @typedoc """
  Configuration structure for OCI authentication.

  ## Fields
    * `user` - The OCID of the user making the request
    * `fingerprint` - Fingerprint of the public key uploaded to OCI
    * `tenancy` - The OCID of your tenancy
    * `region` - The region of the OCI services being accessed
    * `key_content` - The private key content used for signing requests
  """
  @type t :: %__MODULE__{
          user: String.t(),
          fingerprint: String.t(),
          tenancy: String.t(),
          region: String.t(),
          key_content: String.t()
        }

  @typedoc """
  Options for creating a new configuration.

  ## Fields
    * `user` - The OCID of the user making the request
    * `fingerprint` - Fingerprint of the public key uploaded to OCI
    * `tenancy` - The OCID of your tenancy
    * `region` - The region of the OCI services being accessed
    * `key_content` - The private key content as a string (mutually exclusive with `key_content_file`)
    * `key_content_file` - Path to the private key file (mutually exclusive with `key_content`)
  """
  @type config_options :: %{
          user: String.t(),
          fingerprint: String.t(),
          tenancy: String.t(),
          region: String.t(),
          key_content: String.t() | nil,
          key_file: String.t() | nil
        }

  @doc """
  Creates a new configuration struct with the provided options.

  This function accepts either direct key content or a path to a key file, but not both.
  The private key content will be validated to ensure it's in the correct PEM format.

  ## Parameters
    * `options` - Map containing configuration values. See `t:config_options/0` for details.

  ## Returns
    * `t:t/0` - The configuration struct

  ## Raises
    * `ArgumentError` - If the key content is invalid or not in PEM format
    * `File.Error` - If the key file cannot be read (when using `key_content_file`)

  """
  @spec new!(config_options()) :: t() | no_return()
  def new!(%{
        user: user,
        fingerprint: fingerprint,
        tenancy: tenancy,
        region: region,
        key_content: key_content
      }) do
    validate_key_content!(key_content)

    %__MODULE__{
      user: user,
      fingerprint: fingerprint,
      tenancy: tenancy,
      region: region,
      key_content: key_content
    }
  end

  @spec new!(config_options()) :: t() | no_return()
  def new!(%{
        user: user,
        fingerprint: fingerprint,
        tenancy: tenancy,
        region: region,
        key_file: key_file
      }) do
    key_content = File.read!(key_file)
    validate_key_content!(key_content)

    %__MODULE__{
      user: user,
      fingerprint: fingerprint,
      tenancy: tenancy,
      region: region,
      key_content: key_content
    }
  end

  @doc """
  Creates a new configuration from an OCI config file.

  The function reads and parses an INI-formatted OCI configuration file and creates
  a new configuration struct based on the specified profile.

  ## Parameters
    * `config_file_path` - Path to the OCI config file. Defaults to "~/.oci/config"
    * `profile` - The profile name to use from the config file. Defaults to "DEFAULT"

  ## Returns
    * `t:t/0` - The configuration struct

  ## Raises
    * `ArgumentError` - If the config file cannot be parsed or if the specified profile is not found
    * All raises from new!/1

  """
  @spec from_file!(config_file_path :: String.t(), profile :: String.t()) :: t() | no_return()
  def from_file!(config_file_path \\ "~/.oci/config", profile \\ "DEFAULT") do
    config =
      case INIParser.parse_file(config_file_path) do
        {:ok, config} -> config
        {:error, reason} -> raise ArgumentError, message: reason
      end

    unless Map.has_key?(config, profile) do
      raise ArgumentError,
        message: "Profile [#{profile}] not found in #{config_file_path} INI file"
    end

    config = config[profile]

    new!(%{
      user: config["user"],
      fingerprint: config["fingerprint"],
      tenancy: config["tenancy"],
      region: config["region"],
      key_file: config["key_file"]
    })
  end

  @doc """
  Creates a new configuration from the application runtime environment.

  This function reads OCI configuration values from the application's runtime configuration and creates a new configuration struct.
  It looks for configuration under the `:ex_oci_sdk` application key.

  The function expects the following configuration keys to be present:
  - `user` - The OCID of the user making the request
  - `fingerprint` - Fingerprint of the public key uploaded to OCI
  - `tenancy` - The OCID of your tenancy
  - `region` - The region of the OCI services being accessed
  - Either `key_content` (private key as string) OR `key_file` (path to private key file)

  ## Example Configuration

  ```elixir
  # In config/runtime.exs
  config :ex_oci_sdk,
    user: System.get_env("OCI_USER_OCID"),
    fingerprint: System.get_env("OCI_KEY_FINGERPRINT"),
    tenancy: System.get_env("OCI_TENANCY_OCID"),
    region: System.get_env("OCI_REGION") || "sa-saopaulo-1",
    key_file: System.get_env("OCI_PRIVATE_KEY_PATH") || "~/.oci/oci_api_key.pem"

  # OR with key_content
  config :ex_oci_sdk,
    user: System.get_env("OCI_USER_OCID"),
    fingerprint: System.get_env("OCI_KEY_FINGERPRINT"),
    tenancy: System.get_env("OCI_TENANCY_OCID"),
    region: System.get_env("OCI_REGION") || "sa-saopaulo-1",
    key_content: System.get_env("OCI_PRIVATE_KEY_CONTENT")
  ```

  ## Returns
    * `t:t/0` - The configuration struct

  ## Raises
    * `RuntimeError` - If no configuration is found for `:ex_oci_sdk`
    * `RuntimeError` - If any required configuration key is missing
    * `RuntimeError` - If both `key_content` and `key_file` are provided
    * `RuntimeError` - If neither `key_content` nor `key_file` is provided
    * All raises from `new!/1` (including key validation errors)


  """
  @doc since: "0.2.2"
  @spec from_runtime!() :: t() | no_return()
  def from_runtime!() do
    app_name = :ex_oci_sdk
    config = Application.get_all_env(app_name)

    if config == [], do: raise_no_config_error!(app_name)

    keyless_config = %{
      user:
        Application.get_env(app_name, :user) ||
          raise_default_env_missing_error!(app_name, :user),
      fingerprint:
        Application.get_env(app_name, :fingerprint) ||
          raise_default_env_missing_error!(app_name, :fingerprint),
      tenancy:
        Application.get_env(app_name, :tenancy) ||
          raise_default_env_missing_error!(app_name, :tenancy),
      region:
        Application.get_env(app_name, :region) ||
          raise_default_env_missing_error!(app_name, :region)
    }

    keyless_config
    |> add_key_config!(app_name)
    |> new!()
  end

  @doc false
  @spec add_key_config!(map(), atom()) :: map() | no_return()
  defp add_key_config!(keyless_config, app_name) do
    key_content = Application.get_env(app_name, :key_content, nil)
    key_file = Application.get_env(app_name, :key_file, nil)

    case {key_content, key_file} do
      {nil, nil} ->
        raise_key_env_missing_error!(app_name)

      {content, nil} when not is_nil(content) ->
        Map.put(keyless_config, :key_content, content)

      {nil, file} when not is_nil(file) ->
        Map.put(keyless_config, :key_file, file)

      {_, _} ->
        raise_key_conflict_error!(app_name)
    end
  end

  @doc false
  @spec raise_default_env_missing_error!(atom(), atom()) :: no_return()
  defp raise_default_env_missing_error!(app_name, env_name) do
    raise RuntimeError, """
      No #{env_name} found for #{inspect(app_name)}.

      Please add #{env_name} configuration to your config/runtime.exs:

      config #{inspect(app_name)},
        ...
        #{env_name}: "value"
        ...

    """
  end

  @doc false
  @spec raise_key_env_missing_error!(atom()) :: no_return()
  defp raise_key_env_missing_error!(app_name) do
    raise RuntimeError, """
      No key_content OR key_file found for #{inspect(app_name)}.

      Please add key_content OR key_file configuration to your config/runtime.exs:

      # with key_file
      config #{inspect(app_name)},
        ...
        key_file: "path/to/key.pem"

      # OR

      # with key_content
      config #{inspect(app_name)},
        ...
        key_content: "-----BEGIN RSA PRIVATE KEY-----..."
    """
  end

  @doc false
  @spec raise_key_conflict_error!(atom()) :: no_return()
  defp raise_key_conflict_error!(app_name) do
    raise RuntimeError, """
      Both key_content and key_file are found for #{inspect(app_name)}.

      Please remove one of them:

      # WRONG
      config #{inspect(app_name)},
        key_file: "path/to/key.pem"
        key_content: "-----BEGIN RSA PRIVATE KEY-----..."

      # RIGHT (with key_file)
      config #{inspect(app_name)},
        ...
        key_file: "path/to/key.pem"

      # RIGHT (with key_content)
      config #{inspect(app_name)},
        ...
        key_content: "-----BEGIN RSA PRIVATE KEY-----..."
    """
  end

  @doc false
  @spec raise_no_config_error!(atom()) :: no_return()
  defp raise_no_config_error!(app_name) do
    raise RuntimeError, """
    No configuration found for #{inspect(app_name)}.

    Add OCI configuration to your config/runtime.exs:

    config #{inspect(app_name)},
      user: "your-user-ocid",
      fingerprint: "your-fingerprint",
      tenancy: "your-tenancy-ocid",
      region: "your-region",
      key_file: "path/to/key.pem"  # or key_content: "-----BEGIN RSA PRIVATE KEY-----..."
    """
  end

  @doc false
  @spec validate_key_content!(atom()) :: :ok | no_return()
  defp validate_key_content!(key_content) do
    case :public_key.pem_decode(key_content) do
      [] ->
        raise ArgumentError,
          message:
            "Invalid private key format: the provided content is not a valid PEM-encoded key"

      [_ | _] ->
        :ok
    end
  end
end
