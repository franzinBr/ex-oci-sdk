defmodule ExOciSdk.ClientTest do
  use ExUnit.Case, async: true
  doctest ExOciSdk.Client

  alias ExOciSdk.Client
  alias ExOciSdk.Config

  defmodule MockValidHTTPClient do
    @behaviour ExOciSdk.HTTPClient

    def deps, do: [String]
    def request(_method, _url, _headers, _body, _opts), do: {:ok, %{}}
  end

  defmodule MockValidJSON do
    @behaviour ExOciSdk.JSON

    def deps, do: [String]
    def encode_to_iodata!(_data, _options), do: {:ok, ""}
    def decode!(_data, _options), do: {:ok, %{}}
  end

  defmodule MockInvalidClientModule do
    def random_function(), do: nil
  end

  defmodule MockValidJsonWithNonInstalledDependency do
    @behaviour ExOciSdk.JSON

    def deps, do: [NonInstalledDependency, String, NonInstalledDepency2]
    def encode_to_iodata!(_data, _options), do: {:ok, ""}
    def decode!(_data, _options), do: {:ok, %{}}
  end

  defmodule MockValidHTTPWithNonInstalledDependency do
    @behaviour ExOciSdk.HTTPClient

    def deps, do: NonInstalledDependency
    def request(_method, _url, _headers, _body, _opts), do: {:ok, %{}}
  end

  describe "create!/2" do
    setup do
      config =
        Config.new!(%{
          user: "ocid1.user.oc1..test",
          fingerprint: "aa:bb:cc:dd:ee:ff",
          tenancy: "ocid1.tenancy.oc1..test",
          region: "sa-saopaulo-1",
          key_content: """
          # This private key is for testing only, please never expose your private keys directly in the code

          -----BEGIN RSA PRIVATE KEY-----
          MIICXQIBAAKBgQC5VE0N2bcbZ8Ery8F6Z4GpKf1CBp4bA/fUSS3NcstPrnJt08sc
          InxTP04ncKU8fiWv6vMfGQTUoi59lDFsZr/7c4T+iS7mw20VXtylq0l58JmhnJVc
          JHY8GDZ7fNAe8Er3N8RYVCWenTtweZxqzvUYTg4WkYY56C9w3eXNoto0jwIDAQAB
          AoGAE759bwpQzaSiGc5dUHMShzkn+A7IbUxg7MbXEFo4esa0/ipgKyEpaZ0G8IC5
          udYeob1AJYH+18Bnf414LnpL3YmpV+2/MG+MA+ZNLj3AjwvZCHFr3+LO/zyXp2gB
          9bnAastFhIeRbHGt2BSS04/084HVg45aIPU/IlFCigupl5ECQQDbzYi0Gv3xkB4T
          cVWVaRBKqZHz+/jbslWAA3JLxkyBV8/rxw4TpJ9kqPQTapiI+pEJjowkihGD0Wi4
          yxm0d3k9AkEA19ltgYMlgt5hLG8IaA1DImDVkD3SgMIQ2TYwb6/H4l5FTQEvFFwv
          I6mFVI/TyNs8S0fUyehPbWI6Sggs66+JuwJAY91uTuY0mpwwDgVgLRIfJM0GUyQY
          XTkZP6BRPbxK5jlPboByFNqm0MUyn9++jf3KB92MLs3MR2fNfKhKdYQSwQJBALg6
          W7yustV/+HB0VDh7GVG+VIlIOuKqwLakCbNJ1NDgpUWUPRqjk5hcl/AU0i4c8NlP
          9c5e+Wvi6t1FHRIMQQECQQC0KmUegFuKF7Mm8VVs8Bl7r+UnGgI3TGpjFI8ubaln
          QHrxjNFWcaB9FmXzY4OQvI4LBwYKwkXgcNfJJNqJSSmy
          -----END RSA PRIVATE KEY-----
          """
        })

      %{config: config}
    end

    test "create client with default options", %{config: config} do
      client = Client.create!(config)

      assert %Client{} = client
      assert client.config == config
      assert {ExOciSdk.HTTPClient.Hackney, []} == client.http_client
      assert {ExOciSdk.JSON.Jason, []} == client.json
    end

    test "create client with valid custom http client module and valid options", %{config: config} do
      http_client = {MockValidHTTPClient, []}
      client = Client.create!(config, http_client: http_client)

      assert %Client{} = client
      assert client.config == config
      assert http_client == client.http_client
      assert {ExOciSdk.JSON.Jason, []} == client.json
    end

    test "create client with valid custom json module and valid options", %{config: config} do
      json = {MockValidJSON, []}
      client = Client.create!(config, json: json)

      assert %Client{} = client
      assert client.config == config
      assert {ExOciSdk.HTTPClient.Hackney, []} == client.http_client
      assert json == client.json
    end

    test "create client with valid custom http client and json valid module and options", %{
      config: config
    } do
      http_client = {MockValidHTTPClient, []}
      json = {MockValidJSON, []}
      client = Client.create!(config, http_client: http_client, json: json)

      assert %Client{} = client
      assert client.config == config
      assert http_client == client.http_client
      assert json == client.json
    end

    test "raises error when create client with valid custom http client module but invalid options type",
         %{
           config: config
         } do
      http_client = {MockValidHTTPClient, 2}

      assert_raise ArgumentError,
                   ~r/Invalid http_client option: {ExOciSdk.ClientTest.MockValidHTTPClient, 2}\nExpected a tuple of {module, keyword_list}\n/,
                   fn -> Client.create!(config, http_client: http_client) end
    end

    test "raises error when create client with valid custom json module but invalid options type",
         %{
           config: config
         } do
      json = {MockValidJSON, "xpto"}

      assert_raise ArgumentError,
                   ~r/Invalid json option: {ExOciSdk.ClientTest.MockValidJSON, \"xpto\"}\nExpected a tuple of {module, keyword_list}\n/,
                   fn -> Client.create!(config, json: json) end
    end

    test "raises error when create client with invalid custom http client module", %{
      config: config
    } do
      http_client = {MockInvalidClientModule, []}

      assert_raise ArgumentError,
                   ~r/Invalid http_client module: ExOciSdk.ClientTest.MockInvalidClientModule\nThe module must implement the ExOciSdk.HTTPClient behaviour\n/,
                   fn ->
                     Client.create!(config, http_client: http_client)
                   end
    end

    test "raises error when create client with invalid custom json module", %{config: config} do
      json = {MockInvalidClientModule, []}

      assert_raise ArgumentError,
                   ~r/Invalid json module: ExOciSdk.ClientTest.MockInvalidClientModule\nThe module must implement the ExOciSdk.JSON behaviour\n/,
                   fn ->
                     Client.create!(config, json: json)
                   end
    end

    test "raises error when config is not provided" do
      assert_raise FunctionClauseError, fn ->
        Client.create!(nil)
      end
    end

    test "raises error when http client module dependencies are not installed", %{config: config} do
      assert_raise ArgumentError,
                   "The http_client module: ExOciSdk.ClientTest.MockValidHTTPWithNonInstalledDependency depends on [NonInstalledDependency]\nPlease ensure that the dependencies are correctly installed\n",
                   fn ->
                     Client.create!(config,
                       http_client: {MockValidHTTPWithNonInstalledDependency, []}
                     )
                   end
    end

    test "raises error when json module dependencies are not installed", %{config: config} do
      assert_raise ArgumentError,
                   "The json module: ExOciSdk.ClientTest.MockValidJsonWithNonInstalledDependency depends on [NonInstalledDependency, NonInstalledDepency2]\nPlease ensure that the dependencies are correctly installed\n",
                   fn ->
                     Client.create!(config,
                       json: {MockValidJsonWithNonInstalledDependency, []}
                     )
                   end
    end
  end
end
