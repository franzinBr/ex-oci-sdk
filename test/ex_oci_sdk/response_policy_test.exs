defmodule ExOciSdk.ResponsePolicyTest do
  use ExUnit.Case

  alias ExOciSdk.ResponsePolicy

  describe "struct" do
    test "allow custom success status codes" do
      policy = %ResponsePolicy{status_codes_success: [200, 201, 204]}
      assert policy.status_codes_success == [200, 201, 204]

      policy = %ResponsePolicy{status_codes_success: [200..299]}
      assert policy.status_codes_success == [200..299]
    end
  end
end
