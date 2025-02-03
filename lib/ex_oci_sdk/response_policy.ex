# Copyright 2025 Alan Franzin. Licensed under Apache-2.0.

defmodule ExOciSdk.ResponsePolicy do
  @moduledoc false
  # Defines policies for handling HTTP responses

  @typedoc """
  Specifies which headers should be extracted from the response.
  - `:all` - Extract all headers
  - `nil` - Don't extract any headers
  - `[String.t()]` - List of specific header names to extract
  """
  @type headers_to_extract :: [String.t()] | :all | nil

  @typedoc """
  Defines a range of status codes, either as a list of specific codes or a range.
  """
  @type status_range :: list(integer()) | Range.t()

  defstruct status_codes_success: 200..299,
            headers_to_extract: nil

  @type t :: %__MODULE__{
          status_codes_success: status_range(),
          headers_to_extract: headers_to_extract()
        }

  @doc """
  Creates a new ResponsePolicy with the specified success status code range.

  ## Return
    A new `t:t/0` struct configured with the given success status codes.
    If no status codes are provided, defaults to 200..299.

  ## Examples

      iex> ExOciSdk.ResponsePolicy.new()
      %ExOciSdk.ResponsePolicy{status_codes_success: 200..299, headers_to_extract: nil}

      iex> ExOciSdk.ResponsePolicy.new([200, 201])
      %ExOciSdk.ResponsePolicy{status_codes_success: [200, 201], headers_to_extract: nil}
  """
  def new(status_code_success \\ 200..299) do
    %__MODULE__{
      status_codes_success: status_code_success
    }
  end

  @doc """
  Configures which headers should be extracted from the response.

  ## Returns
  Returns an updated `t:t/0` struct with the configured headers to extract.

  ## Parameters
    - response_policy: The existing ResponsePolicy struct to modify
    - headers: Can be one of:
      - `:all` to extract all headers
      - A list of header names to extract specific headers
      - A single header name as string to extract just that header

  ## Examples

      iex> policy = ExOciSdk.ResponsePolicy.new()
      iex> ExOciSdk.ResponsePolicy.with_headers_to_extract(policy, :all)
      %ExOciSdk.ResponsePolicy{status_codes_success: 200..299, headers_to_extract: :all}

      iex> policy = ExOciSdk.ResponsePolicy.new()
      iex> ExOciSdk.ResponsePolicy.with_headers_to_extract(policy, ["content-type", "etag"])
      %ExOciSdk.ResponsePolicy{status_codes_success: 200..299, headers_to_extract: ["content-type", "etag"]}

      iex> policy = ExOciSdk.ResponsePolicy.new()
      iex> ExOciSdk.ResponsePolicy.with_headers_to_extract(policy, "content-type")
      %ExOciSdk.ResponsePolicy{status_codes_success: 200..299, headers_to_extract: ["content-type"]}
  """
  @spec with_headers_to_extract(t(), String.t() | [String.t()] | :all) :: t()
  def with_headers_to_extract(%__MODULE__{} = response_policy, :all) do
    %{response_policy | headers_to_extract: :all}
  end

  def with_headers_to_extract(%__MODULE__{} = response_policy, headers) when is_list(headers) do
    %{response_policy | headers_to_extract: headers}
  end

  def with_headers_to_extract(%__MODULE__{} = response_policy, header)
      when is_binary(header) and header != "" do
    %{response_policy | headers_to_extract: [header]}
  end
end
