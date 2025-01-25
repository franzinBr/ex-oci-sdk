defmodule ExOciSdk.ResponseTest do
  use ExUnit.Case, async: true

  alias ExOciSdk.{Config, Client, Response, ResponsePolicy}

  describe "build_response/4" do
    setup do
      config = Config.from_file!(Path.join(__DIR__, "../support/config"))
      client = Client.create!(config)
      %{client: client}
    end

    test "build response from sucessful http client request", %{client: client} do
      response_policy = %ResponsePolicy{}

      {type, response} =
        {:ok,
         %{
           status_code: 200,
           body: ~s({"message": "success"}),
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "request123"}
           ]
         }}

      assert {:ok, _result} =
               Response.build_response(client, response_policy, type, response)
    end

    test "build response from sucessful http client request but unsuccessful match ResponsePolicy criterias",
         %{client: client} do
      response_policy = %ResponsePolicy{}

      {type, response} =
        {:ok,
         %{
           status_code: 400,
           body: ~s({"message": "bad request"}),
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "request123"}
           ]
         }}

      assert {:error, _result} =
               Response.build_response(client, response_policy, type, response)
    end

    test "build response from unsuccessful http client request",
         %{client: client} do
      response_policy = %ResponsePolicy{}

      {type, response} =
        {:error, {:request_failed, :nxdomain}}

      assert {:error, result} =
               Response.build_response(client, response_policy, type, response)

      assert result.error == {:request_failed, :nxdomain}
      assert result.metadata == nil
    end

    test "build JSON parsead response from sucessful http client request with content-type equals application/json",
         %{client: client} do
      response_policy = %ResponsePolicy{}

      {type, response} =
        {:ok,
         %{
           status_code: 200,
           body: ~s({"message": "success"}),
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "request123"}
           ]
         }}

      assert {:ok, result} =
               Response.build_response(client, response_policy, type, response)

      assert result.data == %{"message" => "success"}
    end

    test "build JSON parsead response from sucessful http client request with content-type equals application/json but unsuccessful match ResponsePolicy criterias",
         %{client: client} do
      response_policy = %ResponsePolicy{}

      {type, response} =
        {:ok,
         %{
           status_code: 400,
           body: ~s({"message": "bad request"}),
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "request123"}
           ]
         }}

      assert {:error, result} =
               Response.build_response(client, response_policy, type, response)

      assert result.error == %{"message" => "bad request"}
    end

    test "set opc_request_id in metadata when presents in headers", %{client: client} do
      response_policy = %ResponsePolicy{}

      {type, response} =
        {:ok,
         %{
           status_code: 200,
           body: ~s({"id": "111"}),
           headers: [
             {"content-type", "application/json"},
             {"opc-request-id", "DF@fgff!@AAAAAAsd"}
           ]
         }}

      assert {:ok, result} =
               Response.build_response(client, response_policy, type, response)

      assert result.metadata[:opc_request_id] == "DF@fgff!@AAAAAAsd"
    end

    test "build non-JSON response", %{client: client} do
      response_policy = %ResponsePolicy{}
      body_text = "plain text response"

      {type, response} =
        {:ok,
         %{
           status_code: 201,
           body: body_text,
           headers: [
             {"content-type", "text/plain"},
             {"opc-request-id", "request123"}
           ]
         }}

      assert {:ok, result} =
               Response.build_response(client, response_policy, type, response)

      assert result.data == body_text
    end

    test "build response metadata without opc-request-id headers", %{client: client} do
      response_policy = %ResponsePolicy{}

      {type, response} =
        {:ok,
         %{
           status_code: 201,
           body: "hi",
           headers: [
             {"content-type", "text/plain"}
           ]
         }}

      assert {:ok, result} =
               Response.build_response(client, response_policy, type, response)

      assert result.metadata[:opc_request_id] == nil
    end

    test "build response from request with empty body", %{client: client} do
      response_policy = %ResponsePolicy{}

      {type, response} =
        {:ok,
         %{
           status_code: 200,
           body: "",
           headers: []
         }}

      assert {:ok, result} =
               Response.build_response(client, response_policy, type, response)

      assert result.data == nil
    end

    test "build response from request with nil body", %{client: client} do
      response_policy = %ResponsePolicy{}

      {type, response} =
        {:ok,
         %{
           status_code: 200,
           body: nil,
           headers: []
         }}

      assert {:ok, result} =
               Response.build_response(client, response_policy, type, response)

      assert result.data == nil
    end

    test "build response from request with empty body but with content-type application/json ", %{
      client: client
    } do
      response_policy = %ResponsePolicy{}

      {type, response} =
        {:ok,
         %{
           status_code: 200,
           body: "",
           headers: [
             {"content-type", "application/json"}
           ]
         }}

      assert {:ok, result} =
               Response.build_response(client, response_policy, type, response)

      assert result.data == nil
    end
  end
end
