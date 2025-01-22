defmodule ExOciSdk.HttpClientTest do
  use ExUnit.Case, async: true
  alias ExOciSdk.HTTPClient

  describe "HTTPClient behaviour" do
    test "behaviour module has the expected callbacks" do
      callbacks = HTTPClient.behaviour_info(:callbacks)

      assert Enum.member?(callbacks, {:request, 5})
    end
  end
end
