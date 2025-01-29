defmodule ExOciSdk.ResponsePolicyTest do
  use ExUnit.Case
  doctest ExOciSdk.ResponsePolicy
  alias ExOciSdk.ResponsePolicy

  describe "struct" do
    test "allows custom success status codes as list" do
      policy = %ResponsePolicy{status_codes_success: [200, 201, 204]}
      assert policy.status_codes_success == [200, 201, 204]
    end

    test "allows custom success status codes as range" do
      policy = %ResponsePolicy{status_codes_success: 200..299}
      assert policy.status_codes_success == 200..299
    end

    test "allows setting headers to extract" do
      policy = %ResponsePolicy{headers_to_extract: ["content-type"]}
      assert policy.headers_to_extract == ["content-type"]
    end

    test "allows setting headers to :all" do
      policy = %ResponsePolicy{headers_to_extract: :all}
      assert policy.headers_to_extract == :all
    end
  end

  describe "new/1" do
    test "creates a new policy with default success status codes" do
      policy = ResponsePolicy.new()
      assert policy.status_codes_success == 200..299
      assert policy.headers_to_extract == nil
    end

    test "creates a new policy with custom success status codes as list" do
      policy = ResponsePolicy.new([200, 201, 204])
      assert policy.status_codes_success == [200, 201, 204]
    end

    test "creates a new policy with custom success status codes as range" do
      policy = ResponsePolicy.new(200..204)
      assert policy.status_codes_success == 200..204
    end
  end

  describe "with_headers_to_extract/2" do
    setup do
      {:ok, policy: ResponsePolicy.new()}
    end

    test "configures to extract all headers", %{policy: policy} do
      updated_policy = ResponsePolicy.with_headers_to_extract(policy, :all)
      assert updated_policy.headers_to_extract == :all
    end

    test "configures to extract specific headers from list", %{policy: policy} do
      headers = ["content-type", "etag", "location"]
      updated_policy = ResponsePolicy.with_headers_to_extract(policy, headers)
      assert updated_policy.headers_to_extract == headers
    end

    test "configures to extract single header from string", %{policy: policy} do
      updated_policy = ResponsePolicy.with_headers_to_extract(policy, "content-type")
      assert updated_policy.headers_to_extract == ["content-type"]
    end

    test "maintains existing status codes when updating headers" do
      custom_policy = ResponsePolicy.new([200, 201])
      updated_policy = ResponsePolicy.with_headers_to_extract(custom_policy, :all)
      assert updated_policy.status_codes_success == [200, 201]
      assert updated_policy.headers_to_extract == :all
    end
  end
end
