defmodule ExOciSdk.RequestBuilderTest do
  use ExUnit.Case, async: true
  doctest ExOciSdk.RequestBuilder

  alias ExOciSdk.{RequestBuilder, ResponsePolicy}

  def base_url(), do: "https://api.example.com"
  def path(), do: "/users"

  describe "new/3" do
    test "create a new request builder with basic attributes" do
      request = RequestBuilder.new(:get, base_url(), path())

      assert request.method == :get
      assert request.base_url == base_url()
      assert request.path == path()
      assert request.headers == %{}
      assert request.querys == %{}
      assert request.body == %{}
      assert %ResponsePolicy{} = request.response_policy
    end
  end

  describe "with_query/4" do
    setup do
      %{request: RequestBuilder.new(:get, base_url(), path())}
    end

    test "add a query param", %{request: request} do
      request = RequestBuilder.with_query(request, "limit", 10)
      assert request.querys == %{"limit" => 10}
    end

    test "merge query param when have multiples adds", %{request: request} do
      request =
        request
        |> RequestBuilder.with_query("limit", 10)
        |> RequestBuilder.with_query("page", 1)
        |> RequestBuilder.with_query("name", "spider-man")

      assert request.querys == %{
               "limit" => 10,
               "page" => 1,
               "name" => "spider-man"
             }
    end

    test "ignore nil value by default", %{request: request} do
      request = RequestBuilder.with_query(request, "page", nil)
      assert request.querys == %{}
    end

    test "accepts nil value when accept_nullable? is true", %{request: request} do
      request = RequestBuilder.with_query(request, "page", nil, true)
      assert request.querys == %{"page" => nil}
    end
  end

  describe "with_querys/3" do
    setup do
      %{request: RequestBuilder.new(:post, base_url(), path())}
    end

    test "adds multiples query param at the same time", %{request: request} do
      params = %{"version" => "1.22", "df" => true, "track" => "222311112"}
      request = RequestBuilder.with_querys(request, params)

      assert request.querys == params
    end

    test "ignore nil query values by default", %{request: request} do
      params = %{"version" => "1.22", "df" => nil, "track" => "222311112"}
      request = RequestBuilder.with_querys(request, params)

      assert request.querys == %{"version" => "1.22", "track" => "222311112"}
    end

    test "accepts nil query values when accept_nullable? is true", %{request: request} do
      params = %{"version" => "1.22", "df" => nil, "track" => "222311112"}
      request = RequestBuilder.with_querys(request, params, true)

      assert request.querys == params
    end
  end

  describe "with_header/4" do
    setup do
      %{request: RequestBuilder.new(:post, base_url(), path())}
    end

    test "add a header", %{request: request} do
      request = RequestBuilder.with_header(request, "x-value", "xpto")
      assert request.headers == %{"x-value" => "xpto"}
    end

    test "merge header when have multiples adds", %{request: request} do
      request =
        request
        |> RequestBuilder.with_header("accept", "*/*")
        |> RequestBuilder.with_header("x-page", 1)
        |> RequestBuilder.with_header("id", "20")

      assert request.headers == %{
               "accept" => "*/*",
               "x-page" => 1,
               "id" => "20"
             }
    end

    test "ignore nil header value by default", %{request: request} do
      request = RequestBuilder.with_header(request, "x-page", nil)
      assert request.headers == %{}
    end

    test "accepts nil header value when accept_nullable? is true", %{request: request} do
      request = RequestBuilder.with_header(request, "x-page", nil, true)
      assert request.headers == %{"x-page" => nil}
    end
  end

  describe "with_headers/3" do
    setup do
      %{request: RequestBuilder.new(:post, base_url(), path())}
    end

    test "adds multiples headers at the same time", %{request: request} do
      headers = %{"version" => "1.22", "df" => true, "track" => "222311112"}
      request = RequestBuilder.with_headers(request, headers)

      assert request.headers == headers
    end

    test "ignore nil headers values by default", %{request: request} do
      headers = %{"version" => "1.22", "df" => nil, "track" => "222311112"}
      request = RequestBuilder.with_headers(request, headers)

      assert request.headers == %{"version" => "1.22", "track" => "222311112"}
    end

    test "accepts nil headers values when accept_nullable? is true", %{request: request} do
      headers = %{"version" => "1.22", "df" => nil, "track" => "222311112"}
      request = RequestBuilder.with_headers(request, headers, true)

      assert request.headers == headers
    end
  end

  describe "with_body/2" do
    setup do
      %{request: RequestBuilder.new(:put, base_url(), path())}
    end

    test "set the request body", %{request: request} do
      body = %{id: 5, name: "Phil", email: "phil@example.com"}
      request = RequestBuilder.with_body(request, body)
      assert request.body == body
    end
  end

  describe "with_response_policy/2" do
    setup do
      %{request: RequestBuilder.new(:delete, base_url(), path())}
    end

    test "set custom response policy", %{request: request} do
      policy = %ResponsePolicy{status_codes_success: [204]}
      request = RequestBuilder.with_response_policy(request, policy)
      assert request.response_policy == policy
    end
  end
end
