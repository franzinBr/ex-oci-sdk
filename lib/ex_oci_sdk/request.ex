defmodule ExOciSdk.Request do
  @moduledoc """
  Handles HTTP request execution for the OCI SDK, including URL building, body building, request signing,
  and response processing.
  """

  alias ExOciSdk.{Config, Client, RequestBuilder, Response, Signer, KeyConverter}

  @doc """
  Executes an HTTP request built by RequestBuilder.

  Signs the request, sends it using the configured HTTP client, and processes the response.

  ## Parameters
    * request - RequestBuilder struct containing request details
    * client - Client struct

  ## Returns
    * `{:ok, response_success}` - Successful response
    * `{:error, response_error}` - Unsuccessful response
  """
  @spec execute(RequestBuilder.t(), Client.t()) ::
          {:ok, Response.response_success()} | {:error, Response.response_error()}
  def execute(%RequestBuilder{} = request, %Client{} = client) do
    url = build_url(client.config, request)
    uri = URI.new!(url)
    body = build_body(client, request)
    headers = Signer.sign(client, request.method, uri, request.headers, body)

    {http_client_mod, http_client_options} = Map.fetch!(client, :http_client)

    {type, response} =
      apply(http_client_mod, :request, [request.method, url, body, headers, http_client_options])

    Response.build_response(client, request.response_policy, type, response)
  end

  @spec build_url(Config.t(), RequestBuilder.t()) :: String.t()
  defp build_url(%Config{region: region}, %RequestBuilder{
         base_url: base_url,
         path: path,
         querys: querys
       }) do
    base = String.replace(base_url, "{region}", region) <> path

    case Enum.empty?(querys) do
      true -> base
      false -> base <> "?" <> URI.encode_query(querys)
    end
  end

  @spec build_url(Config.t(), RequestBuilder.t()) :: term()
  defp build_body(%Client{json: json}, %RequestBuilder{
         headers: headers,
         body: body
       }) do
    body =
      case is_map(body) and body != %{} do
        true -> body
        false -> ""
      end

    case Map.get(headers, "content-type") do
      nil ->
        body

      "application/json" ->
        body = KeyConverter.snake_to_camel(body)
        {json_mod, json_options} = json
        apply(json_mod, :encode_to_iodata!, [body, json_options])

      _ ->
        body
    end
  end
end
