defmodule ExOciSdk.Signer do
  @moduledoc false
  # Handles request signing for the OCI (Oracle Cloud Infrastructure) API.

  # This module implements the OCI request signing process, which includes:
  # - Adding required headers (date, host, content headers for POST/PUT/PATCH)
  # - Generating a signature using RSA-SHA256
  # - Constructing the final Authorization header

  # The signing process follows the OCI API specification for request authentication.
  # https://docs.oracle.com/en-us/iaas/Content/API/Concepts/signingrequests.htm
  #

  alias ExOciSdk.Client
  alias ExOciSdk.Config
  alias ExOciSdk.HTTPClient

  @spec signing_headers() :: [String.t()]
  defp signing_headers(), do: ["date", "(request-target)", "host"]
  @spec body_headers() :: [String.t()]
  defp body_headers(), do: ["content-length", "content-type", "x-content-sha256"]
  @spec signature_version() :: integer()
  defp signature_version(), do: 1

  @doc """
    Signs an HTTP request according to OCI API specifications.

    Adds required headers and generates an Authorization header containing the request signature.

    ## Parameters
      * `client` - The ExOciSdk.Client containing ExOciSdk.Config for signing
      * `method` - The HTTP method of the request
      * `uri` - The URI struct representing the request URL
      * `headers` - Map of existing request headers
      * `body` - The request body (if any)

    ## Returns
      * Map containing all required headers including the Authorization header
  """
  @spec sign(Client.t(), HTTPClient.http_method(), URI.t(), map(), HTTPClient.body()) :: map()
  def sign(client, method, uri, headers, body) do
    headers
    |> add_date_header()
    |> add_host_header(uri)
    |> maybe_add_content_headers(method, body)
    |> add_authorization_header(method, uri, client.config)
  end

  @spec add_date_header(map()) :: map()
  defp add_date_header(headers) do
    date = Calendar.strftime(DateTime.utc_now(), "%a, %d %b %Y %H:%M:%S GMT")
    Map.put_new(headers, "date", date)
  end

  @spec add_host_header(map(), URI.t()) :: map()
  defp add_host_header(headers, uri) do
    Map.put_new(headers, "host", uri.host)
  end

  @spec maybe_add_content_headers(map(), HTTPClient.http_method(), HTTPClient.body()) :: map()
  defp maybe_add_content_headers(headers, method, body) when method in [:post, :put, :patch] do
    headers
    |> Map.put_new("content-type", "application/json")
    |> add_content_length(body)
    |> add_content_sha256(body)
  end

  defp maybe_add_content_headers(headers, _method, _body), do: headers

  @spec add_content_length(map(), HTTPClient.body()) :: map()
  defp add_content_length(headers, body) do
    Map.put_new(headers, "content-length", "#{IO.iodata_length(body)}")
  end

  @spec add_content_sha256(map(), HTTPClient.body()) :: map()
  defp add_content_sha256(headers, body) do
    sha256 =
      :crypto.hash(:sha256, body)
      |> Base.encode64()

    Map.put(headers, "x-content-sha256", sha256)
  end

  @spec add_authorization_header(map(), HTTPClient.http_method(), URI.t(), Config.t()) :: map()
  defp add_authorization_header(headers, method, uri, config) do
    all_headers_name = get_all_headers_name(method)
    string_to_sign = build_string_to_sign(method, uri, all_headers_name, headers)
    signed_string = sign_string(string_to_sign, config.key_content)
    key_id = "#{config.tenancy}/#{config.user}/#{config.fingerprint}"

    authorization =
      "Signature algorithm=\"rsa-sha256\"," <>
        "headers=\"#{Enum.join(all_headers_name, " ")}\"," <>
        "keyId=\"#{key_id}\"," <>
        "signature=\"#{signed_string}\"," <>
        "version=\"#{signature_version()}\""

    Map.put(headers, "authorization", authorization)
  end

  @spec get_all_headers_name(HTTPClient.http_method()) :: [String.t()]
  defp get_all_headers_name(method) do
    case method in [:post, :put, :patch] do
      true -> signing_headers() ++ body_headers()
      false -> signing_headers()
    end
  end

  @spec build_string_to_sign(HTTPClient.http_method(), URI.t(), [String.t()], map()) :: String.t()
  defp build_string_to_sign(method, uri, all_headers_name, headers) do
    string_to_sign =
      all_headers_name
      |> Enum.map(fn header ->
        case header do
          "(request-target)" ->
            path =
              case uri.query do
                nil -> uri.path
                "" -> uri.path
                query -> "#{uri.path}?#{query}"
              end

            "(request-target): #{String.downcase("#{method}")} #{path}"

          header ->
            "#{header}: #{Map.get(headers, header)}"
        end
      end)
      |> Enum.join("\n")

    string_to_sign
  end

  @spec sign_string(String.t(), String.t()) :: String.t()
  defp sign_string(string_to_sign, key_content) do
    [private_key_entry] = :public_key.pem_decode(key_content)
    private_key = :public_key.pem_entry_decode(private_key_entry)

    :public_key.sign(string_to_sign, :sha256, private_key)
    |> Base.encode64()
  end
end
