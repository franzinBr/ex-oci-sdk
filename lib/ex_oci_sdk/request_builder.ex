defmodule ExOciSdk.RequestBuilder do
  @moduledoc false
  # Builds HTTP requests with configurable method, URL, headers, query params and body.
  # Provides a fluent interface for request construction.

  alias ExOciSdk.{ResponsePolicy, HTTPClient}

  defstruct [
    :method,
    :base_url,
    :path,
    headers: %{},
    querys: %{},
    body: %{},
    response_policy: %ResponsePolicy{}
  ]

  @type t :: %__MODULE__{
          method: HTTPClient.http_method(),
          base_url: String.t(),
          path: String.t(),
          headers: map(),
          querys: map(),
          body: map(),
          response_policy: ResponsePolicy.t()
        }

  @doc """
  Creates a new request builder with the given HTTP method, base URL and path.

  ## Parameters
  * `method` - HTTP method (e.g. :get, :post)
  * `base_url` - Base URL of the API (e.g. "https://api.example.com")
  * `path` - API endpoint path (e.g. "/users")

  ## Examples
      iex> ExOciSdk.RequestBuilder.new(:get, "https://api.example.com", "/users")
      %ExOciSdk.RequestBuilder{
        method: :get,
        base_url: "https://api.example.com",
        path: "/users"
      }
  """
  @spec new(HTTPClient.http_method(), String.t(), String.t()) :: t()
  def new(method, base_url, path) do
    %__MODULE__{
      method: method,
      base_url: base_url,
      path: path
    }
  end

  @doc """
    Adds a query parameter to the request.

    ## Parameters
      * `request` - The request builder struct
      * `key` - Key of the query parameter
      * `value` - Value of the query parameter
      * `accept_nullable?` - If true, allows nil values. If false, nil values are ignored. Defaults to false.
  """

  @spec with_query(t(), String.t(), term(), boolean()) :: t()
  def with_query(%__MODULE__{} = request, key, value, accept_nullable? \\ false) do
    if is_nil(value) and not accept_nullable? do
      request
    else
      %{request | querys: Map.put(request.querys, key, value)}
    end
  end

  @doc """
  Adds multiple query parameters to the request.

  ## Parameters
    * `request` - The request builder struct
    * `querys` - Map of query parameters
    * `accept_nullable?` - If true, allows nil values. If false, nil values are filtered out. Defaults to false.
  """

  @spec with_querys(t(), map(), boolean()) :: t()
  def with_querys(%__MODULE__{} = request, querys, accept_nullable? \\ false) do
    if accept_nullable? do
      %{request | querys: Map.merge(request.querys, querys)}
    else
      non_nullable_querys = querys |> Map.reject(fn {_key, value} -> is_nil(value) end)
      %{request | querys: Map.merge(request.querys, non_nullable_querys)}
    end
  end

  @doc """
  Adds a header to the request.

  ## Parameters
    * `request` - The request builder struct
    * `key` - Header name
    * `value` - Header value
    * `accept_nullable?` - If true, allows nil values. If false, nil values are ignored. Defaults to false.
  """
  @spec with_header(t(), String.t(), term(), boolean()) :: t()
  def with_header(%__MODULE__{} = request, key, value, accept_nullable? \\ false) do
    if is_nil(value) and not accept_nullable? do
      request
    else
      %{request | headers: Map.put(request.headers, key, value)}
    end
  end

  @doc """
  Adds multiple headers to the request.

  ## Parameters
    * `request` - The request builder struct
    * `headers` - Map of headers
    * `accept_nullable?` - If true, allows nil values. If false, nil values are filtered out. Defaults to false.
  """
  @spec with_headers(t(), map(), boolean()) :: t()
  def with_headers(%__MODULE__{} = request, headers, accept_nullable? \\ false) do
    if accept_nullable? do
      %{request | headers: Map.merge(request.headers, headers)}
    else
      non_nullable_headers = headers |> Map.reject(fn {_key, value} -> is_nil(value) end)
      %{request | headers: Map.merge(request.headers, non_nullable_headers)}
    end
  end

  @doc """
  Sets the request body.

  ## Parameters
    * `request` - The request builder struct
    * `body` - Request body as a map

  """
  @spec with_body(t(), map()) :: t()
  def with_body(%__MODULE__{} = request, body) do
    %{request | body: body}
  end

  @doc """
  Sets the response policy for the request.

  ## Parameters
    * `request` - The request builder struct
    * `response_policy` - ResponsePolicy struct
  """
  @spec with_response_policy(t(), ResponsePolicy.t()) :: t()
  def with_response_policy(%__MODULE__{} = request, %ResponsePolicy{} = response_policy) do
    %{request | response_policy: response_policy}
  end
end
