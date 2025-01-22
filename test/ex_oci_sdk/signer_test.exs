defmodule ExOciSdk.SignerTest do
  use ExUnit.Case, async: true
  alias ExOciSdk.{Client, Config, Signer}

  setup do
    config = Config.from_file!(Path.join(__DIR__, "../support/config"))
    client = Client.create!(config)

    %{client: client}
  end

  describe "sign/5" do
    test "return the original headers", %{client: client} do
      method = :get
      uri = URI.parse("https://example.com.br")
      headers = %{"x-custom-header" => "value"}
      body = ""

      signed_headers = Signer.sign(client, method, uri, headers, body)

      assert Map.has_key?(signed_headers, "x-custom-header")
    end

    test "adds required headers for GET", %{client: client} do
      method = :get
      uri = URI.parse("https://example.com.br")
      headers = %{"vl1" => "value"}
      body = ""

      signed_headers = Signer.sign(client, method, uri, headers, body)

      assert Map.has_key?(signed_headers, "date")
      assert Map.has_key?(signed_headers, "host")
      assert Map.has_key?(signed_headers, "authorization")

      refute Map.has_key?(signed_headers, "content-type")
      refute Map.has_key?(signed_headers, "content-length")
      refute Map.has_key?(signed_headers, "x-content-sha256")

      auth_header = Map.get(signed_headers, "authorization")
      assert auth_header =~ ~r/headers="date \(request-target\) host"/
    end

    test "adds required headers for DELETE", %{client: client} do
      method = :delete
      uri = URI.parse("https://example.com.br/1/")
      headers = %{"vl1" => "value"}
      body = ""

      signed_headers = Signer.sign(client, method, uri, headers, body)

      assert Map.has_key?(signed_headers, "date")
      assert Map.has_key?(signed_headers, "host")
      assert Map.has_key?(signed_headers, "authorization")

      refute Map.has_key?(signed_headers, "content-type")
      refute Map.has_key?(signed_headers, "content-length")
      refute Map.has_key?(signed_headers, "x-content-sha256")

      auth_header = Map.get(signed_headers, "authorization")
      assert auth_header =~ ~r/headers="date \(request-target\) host"/
    end

    test "adds required headers for POST", %{client: client} do
      method = :post
      uri = URI.parse("https://example.com.br/post/")
      headers = %{}
      body = ""

      signed_headers = Signer.sign(client, method, uri, headers, body)

      assert Map.has_key?(signed_headers, "date")
      assert Map.has_key?(signed_headers, "host")
      assert Map.has_key?(signed_headers, "authorization")
      assert Map.has_key?(signed_headers, "content-type")
      assert Map.has_key?(signed_headers, "content-length")
      assert Map.has_key?(signed_headers, "x-content-sha256")

      auth_header = Map.get(signed_headers, "authorization")

      assert auth_header =~
               ~r/headers="date \(request-target\) host content-length content-type x-content-sha256"/
    end

    test "adds required headers for PUT", %{client: client} do
      method = :put
      uri = URI.parse("https://example.com.br/post/1")
      headers = %{}
      body = ""

      signed_headers = Signer.sign(client, method, uri, headers, body)

      assert Map.has_key?(signed_headers, "date")
      assert Map.has_key?(signed_headers, "host")
      assert Map.has_key?(signed_headers, "authorization")
      assert Map.has_key?(signed_headers, "content-type")
      assert Map.has_key?(signed_headers, "content-length")
      assert Map.has_key?(signed_headers, "x-content-sha256")

      auth_header = Map.get(signed_headers, "authorization")

      assert auth_header =~
               ~r/headers="date \(request-target\) host content-length content-type x-content-sha256"/
    end

    test "adds required headers for PATCH", %{client: client} do
      method = :patch
      uri = URI.parse("https://example.com.br/post/1")
      headers = %{}
      body = ""

      signed_headers = Signer.sign(client, method, uri, headers, body)

      assert Map.has_key?(signed_headers, "date")
      assert Map.has_key?(signed_headers, "host")
      assert Map.has_key?(signed_headers, "authorization")
      assert Map.has_key?(signed_headers, "content-type")
      assert Map.has_key?(signed_headers, "content-length")
      assert Map.has_key?(signed_headers, "x-content-sha256")

      auth_header = Map.get(signed_headers, "authorization")

      assert auth_header =~
               ~r/headers="date \(request-target\) host content-length content-type x-content-sha256"/
    end

    test "date in format RFC 1123", %{client: client} do
      method = :get
      uri = URI.parse("https://example.com.br")
      headers = %{}
      body = ""

      signed_headers = Signer.sign(client, method, uri, headers, body)

      date = Map.get(signed_headers, "date")

      regex_date_format =
        ~r/^(Mon|Tue|Wed|Thu|Fri|Sat|Sun), \d{2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{4} \d{2}:\d{2}:\d{2} GMT$/

      assert String.match?(date, regex_date_format)
    end

    test "host is valid", %{client: client} do
      method = :get
      uri = URI.parse("https://example.com.br/xpto/example/value24?value=1")
      headers = %{}
      body = ""

      signed_headers = Signer.sign(client, method, uri, headers, body)
      host = Map.get(signed_headers, "host")

      assert host == uri.host
    end

    test "generate correct authorization header format", %{client: client} do
      method = :put
      uri = URI.parse("https://example.com.br/xpto/example/value24?value=1")
      headers = %{}
      body = ""

      signed_headers = Signer.sign(client, method, uri, headers, body)
      auth_header = Map.get(signed_headers, "authorization")

      assert auth_header =~ ~r/^Signature/
      assert auth_header =~ ~r/algorithm="rsa-sha256"/
      assert auth_header =~ ~r/headers="[^"]+"/
      assert auth_header =~ ~r/keyId="[^"]+"/
      assert auth_header =~ ~r/signature="[^"]+"/
      assert auth_header =~ ~r/version="1"/
    end

    test "calculate content-length", %{client: client} do
      method = :post
      uri = URI.parse("https://example.com.br/xpto")
      headers = %{}
      body = ["{\"", [[] | "name"], "\":", [34, [[] | "alan"], 34], 125]
      body_length = IO.iodata_length(body) |> Integer.to_string()

      signed_headers = Signer.sign(client, method, uri, headers, body)
      content_length = Map.get(signed_headers, "content-length")

      assert body_length == content_length
    end

    test "generate x-content-sha256", %{client: client} do
      method = :post
      uri = URI.parse("https://example.com.br/xpto")
      headers = %{}
      body = ["{\"", [[] | "name"], "\":", [34, [[] | "alan"], 34], 125]

      body_sha256 =
        :crypto.hash(:sha256, body)
        |> Base.encode64()

      signed_headers = Signer.sign(client, method, uri, headers, body)
      x_content_sha256 = Map.get(signed_headers, "x-content-sha256")

      assert x_content_sha256 == body_sha256
    end

    test "keyId is formed by tenancy/user/fingerprint", %{client: client} do
      method = :delete
      uri = URI.parse("https://example.com.br/xpto/example/value24")
      headers = %{}
      body = ""
      keyId = "#{client.config.tenancy}/#{client.config.user}/#{client.config.fingerprint}"

      signed_headers = Signer.sign(client, method, uri, headers, body)
      auth_header = Map.get(signed_headers, "authorization")

      assert auth_header =~ ~r/keyId="#{keyId}"/
    end

    test "signature string is signed by the private key", %{client: client} do
      public_key_file_path = Path.join(__DIR__, "../support/public_key.pem")
      public_key_content = File.read!(public_key_file_path)

      method = :get
      uri = URI.parse("https://test.com")
      headers = %{}
      body = ""

      signed_headers = Signer.sign(client, method, uri, headers, body)
      auth_header = Map.get(signed_headers, "authorization")
      date_header = Map.get(signed_headers, "date")

      signature_plan_text =
        "date: #{date_header}\n(request-target): #{method} \nhost: #{uri.host}"

      [_, signature] = Regex.run(~r/signature="([^"]*)"/, auth_header)

      decoded_signature = Base.decode64!(signature)
      [public_key_entry] = :public_key.pem_decode(public_key_content)
      public_key = :public_key.pem_entry_decode(public_key_entry)

      assert :public_key.verify(signature_plan_text, :sha256, decoded_signature, public_key)
    end
  end
end
