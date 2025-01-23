defmodule ExOciSdk.HTTPClient do
  @moduledoc """
  Defines the behaviour for HTTP clients in ExOciSdk.

  This module specifies the contract that all HTTP client implementations must follow.
  It provides type specifications and a callback for making HTTP requests.
  """

  @type http_method :: :get | :post | :put | :delete | :patch | :head | :options
  @type url :: binary()
  @type headers :: [{binary(), binary()}] | %{binary() => binary()}
  @type body :: iodata()
  @type options :: keyword()

  @type response :: %{
          status_code: pos_integer(),
          headers: headers(),
          body: binary()
        }

  @type error_reason ::
          {:connect_failed, term()}
          | {:request_failed, term()}
          | {:receive_failed, term()}
          | :timeout
          | term()

  @doc """
  Makes an HTTP request.

  ## Parameters

    * `method` - HTTP method as atom (e.g., `:get`, `:post`)
    * `url` - Full URL for the request
    * `body` - Request body as iodata
    * `headers` - List of request headers as tuples
    * `options` - Additional options for the request

  ## Returns

    * `{:ok, response}` - Successful response with status, headers and body
    * `{:error, reason}` - Error occurred during request

  """
  @callback request(
              method :: http_method(),
              url :: url(),
              body :: body(),
              headers :: headers(),
              options :: options()
            ) :: {:ok, response()} | {:error, error_reason()}
end

defmodule ExOciSdk.HTTPClient.Hackney do
  @moduledoc """
  HTTP client implementation using Hackney.

  This module implements the `ExOciSdk.HTTPClient` behaviour using the Hackney HTTP client.
  It handles the translation between Hackney's response format and the expected format
  defined in the behaviour.
  """

  @behaviour ExOciSdk.HTTPClient

  @doc """
  Makes an HTTP request using Hackney.

  Implements the `ExOciSdk.HTTPClient.request/5` callback using Hackney as the underlying
  HTTP client. Converts Hackney's response format to match the expected behaviour format.

  ## Parameters

    * `method` - HTTP method as atom (e.g., `:get`, `:post`)
    * `url` - Full URL for the request as binary
    * `body` - Request body as iodata
    * `headers` - List of request headers as tuples
    * `options` - Additional options for the request

  """
  @impl true
  @spec request(
          ExOciSdk.HTTPClient.http_method(),
          ExOciSdk.HTTPClient.url(),
          ExOciSdk.HTTPClient.body(),
          ExOciSdk.HTTPClient.headers(),
          ExOciSdk.HTTPClient.options()
        ) :: {:ok, ExOciSdk.HTTPClient.response()} | {:error, ExOciSdk.HTTPClient.error_reason()}
  def request(method, url, body, headers, options) do
    headers = if is_map(headers), do: Map.to_list(headers), else: headers

    hackney_options =
      Keyword.merge(
        [with_body: true, pool: :oci_pool, connect_timeout: 3000, recv_timeout: :infinity],
        options
      )

    case :hackney.request(method, url, headers, body, hackney_options) do
      {:ok, status_code, resp_headers} ->
        response = %{
          status_code: status_code,
          headers: resp_headers,
          body: ""
        }

        {:ok, response}

      {:ok, status_code, resp_headers, body} ->
        response = %{
          status_code: status_code,
          headers: resp_headers,
          body: body
        }

        {:ok, response}

      {:error, :timeout} ->
        {:error, :timeout}

      {:error, {:connect_failed, reason}} ->
        {:error, {:connect_failed, reason}}

      {:error, {:closed, _}} ->
        {:error, {:receive_failed, :connection_closed}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end
end
