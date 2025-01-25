defmodule ExOciSdk.ConfigTest do
  use ExUnit.Case, async: true
  alias ExOciSdk.Config

  @opts_without_key %{
    user: "ocid1.user.oc1..test",
    fingerprint: "aa:bb:cc:dd:ee:ff",
    tenancy: "ocid1.tenancy.oc1..test",
    region: "sa-saopaulo-1"
  }

  describe "new!/1" do
    test "create config with valids options using key_content" do
      key_content = """

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

      config_values = @opts_without_key |> Map.put(:key_content, key_content)

      config =
        Config.new!(config_values)

      assert %Config{} = config

      assert config.user == Map.get(@opts_without_key, :user)
      assert config.fingerprint == Map.get(@opts_without_key, :fingerprint)
      assert config.tenancy == Map.get(@opts_without_key, :tenancy)
      assert config.region == Map.get(@opts_without_key, :region)
    end

    test "create config with valids options using key_content_file" do
      key_content_file_path = Path.join(__DIR__, "../support/key_content_file.pem")
      key_content = File.read!(key_content_file_path)

      config_values =
        @opts_without_key |> Map.put(:key_file, key_content_file_path)

      config =
        Config.new!(config_values)

      assert %Config{} = config

      assert config.user == Map.get(@opts_without_key, :user)
      assert config.fingerprint == Map.get(@opts_without_key, :fingerprint)
      assert config.tenancy == Map.get(@opts_without_key, :tenancy)
      assert config.region == Map.get(@opts_without_key, :region)
      assert config.key_content == key_content
    end

    test "raises when key_content is invalid" do
      config_values = @opts_without_key |> Map.put(:key_content, "invalid key content")

      assert_raise ArgumentError,
                   ~r/Invalid private key format: the provided content is not a valid PEM-encoded key/,
                   fn ->
                     Config.new!(config_values)
                   end
    end

    test "raise when key_content_file does not exist" do
      config_values =
        @opts_without_key
        |> Map.put(:key_file, "nonexistent.pem")

      assert_raise File.Error, fn ->
        Config.new!(config_values)
      end
    end
  end

  describe "from_file!/2" do
    test "create config from file with default profile" do
      config_file_path = Path.join(__DIR__, "../support/config")

      {:ok, config_ini} = ExOciSdk.INIParser.parse_file(config_file_path)
      config_default = config_ini["DEFAULT"]

      config_default_key_content = File.read!(config_default["key_file"])

      config = Config.from_file!(config_file_path)

      assert %Config{} = config
      assert config.user == config_default["user"]
      assert config.fingerprint == config_default["fingerprint"]
      assert config.tenancy == config_default["tenancy"]
      assert config.region == config_default["region"]
      assert config.key_content == config_default_key_content
    end

    test "create config from file with custom profile" do
      config_file_path = Path.join(__DIR__, "../support/config")

      {:ok, config_ini} = ExOciSdk.INIParser.parse_file(config_file_path)
      config_custom = config_ini["CUSTOM_PROFILE"]

      config_custom_key_content = File.read!(config_custom["key_file"])

      config = Config.from_file!(config_file_path, "CUSTOM_PROFILE")

      assert %Config{} = config
      assert config.user == config_custom["user"]
      assert config.fingerprint == config_custom["fingerprint"]
      assert config.tenancy == config_custom["tenancy"]
      assert config.region == config_custom["region"]
      assert config.key_content == config_custom_key_content
    end

    test "raise when config file does not exist" do
      non_existent_file_path = "nonexistent"

      assert_raise ArgumentError, "Failed to read file: enoent", fn ->
        Config.from_file!(non_existent_file_path)
      end
    end

    test "raise when profile doesnt exist in config file" do
      config_file_path = Path.join(__DIR__, "../support/config")

      assert_raise ArgumentError, ~r/Profile \[NON_EXISTENT\] not found in/, fn ->
        Config.from_file!(config_file_path, "NON_EXISTENT")
      end
    end

    test "raise when failed to parse config file to INI struct" do
      config_file_path = Path.join(__DIR__, "../support/config_incorrect")

      assert_raise ArgumentError,
                   "Failed to parse INI content: Invalid line format: [DEFAULT",
                   fn ->
                     Config.from_file!(config_file_path)
                   end
    end
  end
end
