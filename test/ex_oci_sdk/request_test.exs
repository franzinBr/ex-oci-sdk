defmodule ExOciSdk.RequestTest do
  use ExUnit.Case, async: true
  alias ExOciSdk.{Config, Client, ResponsePolicy, RequestBuilder, Request}
  import Mox

  setup :verify_on_exit!

  setup do
    config = Config.from_file!(Path.join(__DIR__, "../support/config"))

    Mox.expect(ExOciSdk.HTTPClientMock, :deps, fn -> [String] end)
    Mox.expect(ExOciSdk.JSONMock, :deps, fn -> [String] end)

    client =
      Client.create!(config,
        http_client: {ExOciSdk.HTTPClientMock, []},
        json: {ExOciSdk.JSONMock, []}
      )

    %{client: client}
  end

  describe "execute/2" do
    test "execute get request with sucessfull return", %{client: client} do
      request =
        RequestBuilder.new(:get, "https://api.{region}.oracle.com", "/instances")
        |> RequestBuilder.with_query("limit", 1)

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == ~s({"message": "Hello, World"})
        %{"message" => "Hello, World"}
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn _method, url, body, headers, _options ->
        assert url == "https://api.#{client.config.region}.oracle.com/instances?limit=1"
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        {:ok,
         %{
           status_code: 200,
           body: ~s({"message": "Hello, World"}),
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "fffjBBBddCCCsdss555"}
           ]
         }}
      end)

      assert {:ok, response} = Request.execute(request, client)
      assert response.data == %{"message" => "Hello, World"}
      assert response.metadata[:opc_request_id] == "fffjBBBddCCCsdss555"
    end

    test "execute request with network error (connect_failed)", %{client: client} do
      request =
        RequestBuilder.new(:get, "https://api.{region}.oracle.com", "/instances")
        |> RequestBuilder.with_query("limit", 1)

      expect(ExOciSdk.HTTPClientMock, :request, fn _method, url, body, headers, _options ->
        assert url == "https://api.#{client.config.region}.oracle.com/instances?limit=1"
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        {:error, {:connect_failed, :nxdomain}}
      end)

      assert {:error, response} = Request.execute(request, client)
      assert response.error == {:connect_failed, :nxdomain}
      assert response.metadata == nil
    end

    test "execute request with network error (request_failed)", %{client: client} do
      request =
        RequestBuilder.new(:get, "https://api.{region}.oracle.com", "/instances")
        |> RequestBuilder.with_query("limit", 1)

      expect(ExOciSdk.HTTPClientMock, :request, fn _method, url, body, headers, _options ->
        assert url == "https://api.#{client.config.region}.oracle.com/instances?limit=1"
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        {:error, {:request_failed, :enetdown}}
      end)

      assert {:error, response} = Request.execute(request, client)
      assert response.error == {:request_failed, :enetdown}
      assert response.metadata == nil
    end

    test "execute request with network error (receive_failed)", %{client: client} do
      request =
        RequestBuilder.new(:get, "https://api.{region}.oracle.com", "/instances")
        |> RequestBuilder.with_query("limit", 1)

      expect(ExOciSdk.HTTPClientMock, :request, fn _method, url, body, headers, _options ->
        assert url == "https://api.#{client.config.region}.oracle.com/instances?limit=1"
        assert body == ""
        assert Map.has_key?(headers, "authorization")

        {:error, {:receive_failed, :connection_closed}}
      end)

      assert {:error, response} = Request.execute(request, client)
      assert response.error == {:receive_failed, :connection_closed}
      assert response.metadata == nil
    end

    test "execute post request with sucessfull return", %{client: client} do
      request =
        RequestBuilder.new(:post, "https://api.{region}.oracle.com", "/instances")
        |> RequestBuilder.with_header("content-type", "application/json")
        |> RequestBuilder.with_body(%{
          "name" => "bastion-us-prd",
          "os" => "Oracle Linux",
          "ram" => 16
        })

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == %{
                 "name" => "bastion-us-prd",
                 "os" => "Oracle Linux",
                 "ram" => 16
               }

        ~s({
          "name": "bastion-us-prd",
          "os": "Oracle Linux",
          "ram": 16
        })
      end)

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == ~s({"instance_id": "instancid-@Dvvs!fd112444"})
        %{"instance_id" => "instancid-@Dvvs!fd112444"}
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn _method, url, body, headers, _options ->
        assert url == "https://api.#{client.config.region}.oracle.com/instances"
        assert body == ~s({
          "name": "bastion-us-prd",
          "os": "Oracle Linux",
          "ram": 16
        })
        assert Map.has_key?(headers, "authorization")
        assert Map.get(headers, "content-type") == "application/json"

        {:ok,
         %{
           status_code: 201,
           body: ~s({"instance_id": "instancid-@Dvvs!fd112444"}),
           headers: [{"content-type", "application/json"}]
         }}
      end)

      assert {:ok, response} = Request.execute(request, client)
      assert response.data == %{"instance_id" => "instancid-@Dvvs!fd112444"}
    end

    test "execute delete request with unsucessful return", %{client: client} do
      request =
        RequestBuilder.new(:delete, "https://api.{region}.oracle.com", "/instances/224fSKffvd2")

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == ~s({"message": "instance 224fSKffvd2 not found})
        %{"message" => "instance 224fSKffvd2 not found"}
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn _method, url, _body, headers, _options ->
        assert url == "https://api.#{client.config.region}.oracle.com/instances/224fSKffvd2"
        assert Map.has_key?(headers, "authorization")

        {:ok,
         %{
           status_code: 404,
           body: ~s({"message": "instance 224fSKffvd2 not found}),
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "WSdfjHDJDHvn@NN@Dnvv55"}
           ]
         }}
      end)

      assert {:error, response} = Request.execute(request, client)
      assert response.error == %{"message" => "instance 224fSKffvd2 not found"}
      assert response.metadata[:opc_request_id] == "WSdfjHDJDHvn@NN@Dnvv55"
    end

    test "execute patch request with custom success status code and with sucessfull return", %{
      client: client
    } do
      request =
        RequestBuilder.new(
          :patch,
          "https://api.{region}.oracle.com",
          "/instances/FSAN2nfsnsanJSJDjlslsk"
        )
        |> RequestBuilder.with_header("content-type", "application/json")
        |> RequestBuilder.with_body(%{
          "ram" => 8
        })
        |> RequestBuilder.with_response_policy(%ResponsePolicy{status_codes_success: [200, 102]})

      expect(ExOciSdk.JSONMock, :encode_to_iodata!, fn input, _options ->
        assert input == %{"ram" => 8}
        ~s({ "ram": 8})
      end)

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == ~s({"message": "accepted"})
        %{"message" => "accepted"}
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn _method, url, body, headers, _options ->
        assert url ==
                 "https://api.#{client.config.region}.oracle.com/instances/FSAN2nfsnsanJSJDjlslsk"

        assert body == ~s({ "ram": 8})
        assert Map.has_key?(headers, "authorization")
        assert Map.get(headers, "content-type") == "application/json"

        {:ok,
         %{
           status_code: 102,
           body: ~s({"message": "accepted"}),
           headers: [{"content-type", "application/json"}]
         }}
      end)

      assert {:ok, response} = Request.execute(request, client)
      assert response.data == %{"message" => "accepted"}
    end

    test "execute request with text/plain body", %{client: client} do
      request =
        RequestBuilder.new(:get, "https://api.{region}.oracle.com", "/instances")
        |> RequestBuilder.with_header("content-type", "text/plain")
        |> RequestBuilder.with_body("Hello, World")

      expect(ExOciSdk.JSONMock, :decode!, fn input, _options ->
        assert input == ~s({"message": "Hello, World"})
        %{"message" => "Hello, World"}
      end)

      expect(ExOciSdk.HTTPClientMock, :request, fn _method, url, body, headers, _options ->
        assert url == "https://api.#{client.config.region}.oracle.com/instances"
        assert body == "Hello, World"
        assert Map.has_key?(headers, "authorization")

        {:ok,
         %{
           status_code: 200,
           body: ~s({"message": "Hello, World"}),
           headers: [
             {"content-type", "application/json"}
           ]
         }}
      end)

      assert {:ok, response} = Request.execute(request, client)
      assert response.data == %{"message" => "Hello, World"}
    end
  end
end
