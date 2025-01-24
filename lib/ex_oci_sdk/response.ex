defmodule ExOciSdk.Response do
  @moduledoc """
  Handles HTTP response processing for the OCI SDK.

  This module is responsible for processing HTTP responses from the Oracle Cloud Infrastructure API,
  handling both successful and error responses, and converting them into a standardized format.
  It includes functionality for parsing responses, extracting metadata, and applying response policies.
  """

  alias ExOciSdk.{HTTPClient, Client, ResponsePolicy}

  @type return_type :: :ok | :error
  @type response_metadata :: %{opc_request_id: String.t()}
  @type response_error :: %{error: term(), metadata: response_metadata() | nil}
  @type response_success :: %{data: term(), metadata: response_metadata()}

  @doc """
  Builds a standardized response from an HTTP client response.

  Takes a client configuration, response policy, response type, and the raw HTTP response,
  and returns a tuple containing either a success or error response with appropriate metadata.

  ## Parameters

    * `client` - The client configuration struct
    * `response_policy` - The response policy defining success criteria and additional policies
    * `type` - The type of response (`:ok` or `:error`)
    * `response` - The raw HTTP response or error reason

  ## Returns

    * `{:ok, response_success()}` - For successful responses
    * `{:error, response_error()}` - For error responses

  """
  @spec build_response(
          Client.t(),
          ResponsePolicy.t(),
          atom(),
          HTTPClient.response() | HTTPClient.error_reason()
        ) :: {:ok, response_success()} | {:error, response_error()}
  def build_response(%Client{} = _client, %ResponsePolicy{} = _response_policy, :error, response) do
    http_client_error = %{error: response, metadata: nil}
    {:error, http_client_error}
  end

  def build_response(%Client{} = client, %ResponsePolicy{} = response_policy, _type, response) do
    return_type = build_return_type(response_policy, response)
    return = build_return(client, return_type, response)

    {return_type, return}
  end

  @spec build_return_type(ResponsePolicy.t(), HTTPClient.response()) :: return_type()
  defp build_return_type(%ResponsePolicy{} = response_policy, response) do
    case response.status_code in response_policy.status_codes_success do
      true -> :ok
      false -> :error
    end
  end

  @spec build_return(Client.t(), return_type(), HTTPClient.response()) ::
          response_success() | response_error()
  defp build_return(%Client{} = client, :error, response) do
    metadata = build_metadata(response)
    response = parse_response(client, response)
    %{error: response, metadata: metadata}
  end

  defp build_return(%Client{} = client, :ok, response) do
    metadata = build_metadata(response)
    response = parse_response(client, response)
    %{data: response, metadata: metadata}
  end

  @spec build_metadata(HTTPClient.response()) :: response_metadata()
  defp build_metadata(response) do
    opc_request_id =
      Enum.find_value(response.headers, fn
        {"opc-request-id", value} -> value
        _ -> nil
      end)

    %{opc_request_id: opc_request_id}
  end

  @spec parse_response(Client.t(), HTTPClient.response()) :: term()
  defp parse_response(%Client{} = client, response) do
    content_type =
      Enum.find_value(response.headers, fn
        {"content-type", value} -> value
        _ -> nil
      end)

    parse_by_content_type(content_type, client, response)
  end

  @spec parse_by_content_type(String.t() | nil, Client.t(), HTTPClient.response()) :: term()
  defp parse_by_content_type("application/json", %Client{} = client, response) do
    {json_mod, json_options} = Map.fetch!(client, :json)

    case IO.iodata_length(response.body) do
      0 -> nil
      _ -> apply(json_mod, :decode!, [response.body, json_options])
    end
  end

  defp parse_by_content_type(_content_type, %Client{} = _client, response) do
    case response.body do
      "" -> nil
      _ -> response.body
    end
  end
end
