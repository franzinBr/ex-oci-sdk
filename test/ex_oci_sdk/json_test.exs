defmodule ExOciSdk.JSONTest do
  use ExUnit.Case, async: true
  alias ExOciSdk.JSON

  describe "JSON behaviour" do
    test "behaviour module has the expected callbacks" do
      callbacks = JSON.behaviour_info(:callbacks)

      assert Enum.member?(callbacks, {:encode_to_iodata!, 2})
      assert Enum.member?(callbacks, {:decode!, 2})
    end
  end
end

defmodule ExOciSdk.JSON.JasonTest do
  use ExUnit.Case, async: true

  @moduletag :json_jason

  defp jason_available? do
    Code.ensure_loaded?(Jason)
  end

  setup do
    if not jason_available?() do
      ExUnit.configure(exclude: :json_jason)
      :ok
    else
      {:ok, %{}}
    end
  end

  describe "when Jason is available" do
    @describetag :json_jason

    test "encode_to_iodata! encodes map to JSON" do
      input = %{"key" => "value", "number" => 42}
      result = ExOciSdk.JSON.Jason.encode_to_iodata!(input, [])

      assert is_list(result) or is_binary(result)
      assert ExOciSdk.JSON.Jason.decode!(IO.iodata_to_binary(result), []) == input
    end

    test "encode_to_iodata! raises on invalid input" do
      input = %{key: {:invalid, :term}}

      assert_raise Protocol.UndefinedError, fn ->
        ExOciSdk.JSON.Jason.encode_to_iodata!(input, [])
      end
    end

    test "decode! decodes valid JSON to map" do
      json = ~s({"key":"value","number":42})
      expected = %{"key" => "value", "number" => 42}

      assert ExOciSdk.JSON.Jason.decode!(json, []) == expected
    end

    test "decode! raises on invalid JSON" do
      invalid_json = ~s({"key": "unclosed)

      assert_raise Jason.DecodeError, fn ->
        ExOciSdk.JSON.Jason.decode!(invalid_json, [])
      end
    end

    test "decode! works with iodata input" do
      iodata = ["{", [<<"\"key\"">>, ":", "\"value\""], "}"]
      expected = %{"key" => "value"}

      assert ExOciSdk.JSON.Jason.decode!(iodata, []) == expected
    end
  end

  describe "when Jason is not available" do
    test "module exists but functions raise when Jason is not available", %{} do
      if not jason_available?() do
        assert_raise UndefinedFunctionError, fn ->
          ExOciSdk.JSON.Jason.encode_to_iodata!(%{}, [])
        end

        assert_raise UndefinedFunctionError, fn ->
          ExOciSdk.JSON.Jason.decode!("{}", [])
        end
      end
    end
  end
end
