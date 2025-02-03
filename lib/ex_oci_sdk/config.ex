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

  @doc false
  @spec validate_key_content!(String.t()) :: :ok | no_return()
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
