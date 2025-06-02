defmodule ExOciSdk.INIParserTest do
  use ExUnit.Case, async: true
  doctest ExOciSdk.INIParser

  alias ExOciSdk.INIParser

  describe "parse/1" do
    test "parses empty content" do
      assert INIParser.parse("") == {:ok, %{}}
    end

    test "parses simple key-value pairs without section" do
      content = """
      key1 = value1
      key2 = value2
      """

      assert INIParser.parse(content) == {
               :ok,
               %{
                 "key1" => "value1",
                 "key2" => "value2"
               }
             }
    end

    test "parses single section with properties" do
      content = """
      [section1]
      key1 = value1
      key2 = value2
      """

      assert INIParser.parse(content) == {
               :ok,
               %{
                 "section1" => %{
                   "key1" => "value1",
                   "key2" => "value2"
                 }
               }
             }
    end

    test "parses multiple sections" do
      content = """
      [section1]
      key1 = value1

      [section2]
      key2 = value2
      """

      assert INIParser.parse(content) == {
               :ok,
               %{
                 "section1" => %{
                   "key1" => "value1"
                 },
                 "section2" => %{
                   "key2" => "value2"
                 }
               }
             }
    end

    test "handles comments correctly" do
      content = """
      ; This is a comment
      key1 = value1
      # Another comment
      [section1]
      ; Section comment
      key2 = value2
      """

      assert INIParser.parse(content) == {
               :ok,
               %{
                 "key1" => "value1",
                 "section1" => %{
                   "key2" => "value2"
                 }
               }
             }
    end

    test "parses different value types correctly" do
      content = """
      string = simple string
      integer = 42
      float = 3.14
      true_bool = true
      false_bool = false
      """

      assert INIParser.parse(content) == {
               :ok,
               %{
                 "string" => "simple string",
                 "integer" => 42,
                 "float" => 3.14,
                 "true_bool" => true,
                 "false_bool" => false
               }
             }
    end

    test "handles whitespace correctly" do
      content = """
        [section]
          key1    =    value1
        key2=value2
      """

      assert INIParser.parse(content) == {
               :ok,
               %{
                 "section" => %{
                   "key1" => "value1",
                   "key2" => "value2"
                 }
               }
             }
    end

    test "handles empty lines" do
      content = """

      key1 = value1

      [section1]

      key2 = value2

      """

      assert INIParser.parse(content) == {
               :ok,
               %{
                 "key1" => "value1",
                 "section1" => %{
                   "key2" => "value2"
                 }
               }
             }
    end
  end

  describe "parse_file/1" do
    test "returns error for non-existent file" do
      assert INIParser.parse_file("non_existent.ini") ==
               {:error, "Failed to read file: enoent"}
    end

    test "parses file successfully" do
      path = Path.join(__DIR__, "../support/ini")

      assert INIParser.parse_file(path) == {
               :ok,
               %{"section" => %{"key" => "value"}}
             }
    end

    test "handles tilde (~) expansion for current user" do
      path = Path.join(__DIR__, "../support/ini")
      home_relative_path = "~/#{Path.relative_to(path, System.user_home())}"

      assert INIParser.parse_file(home_relative_path) == {
               :ok,
               %{"section" => %{"key" => "value"}}
             }
    end

    test "handles current directory (./) expansion" do
      path = Path.join(__DIR__, "../support/ini")
      current_dir_path = "./#{Path.relative_to(path, File.cwd!())}"

      assert INIParser.parse_file(current_dir_path) == {
               :ok,
               %{"section" => %{"key" => "value"}}
             }
    end

    test "handles multiple slashes normalization" do
      path = Path.join(__DIR__, "///..//support//ini")

      assert INIParser.parse_file(path) == {
               :ok,
               %{"section" => %{"key" => "value"}}
             }
    end
  end

  describe "error handling" do
    test "returns error for malformed section" do
      content = """
      [unclosed_section
      key = value
      """

      assert {:error, message} = INIParser.parse(content)
      assert String.contains?(message, "Invalid line format: [unclosed_section")
    end

    test "returns error for invalid key-value format" do
      content = """
      invalid_line
      key = value
      """

      assert {:error, message} = INIParser.parse(content)
      assert String.contains?(message, "Invalid line format")
    end

    test "returns error for empty key" do
      content = """
      = value
      """

      assert {:error, message} = INIParser.parse(content)
      assert String.contains?(message, "Invalid key-value format: Empty key")
    end

    test "returns error for line without value" do
      content = "key"

      assert {:error, message} = INIParser.parse(content)
      assert String.contains?(message, "Invalid line format")
    end
  end

  describe "edge cases" do
    test "handles empty sections" do
      content = """
      [empty_section]
      [next_section]
      key = value
      """

      assert INIParser.parse(content) == {
               :ok,
               %{
                 "empty_section" => %{},
                 "next_section" => %{
                   "key" => "value"
                 }
               }
             }
    end

    test "handles duplicate sections" do
      content = """
      [section]
      key1 = value1
      [section]
      key2 = value2
      """

      assert INIParser.parse(content) == {
               :ok,
               %{
                 "section" => %{
                   "key1" => "value1",
                   "key2" => "value2"
                 }
               }
             }
    end

    test "handles values containing equal signs" do
      content = """
      key = value=with=equals
      [section]
      url = http://example.com?param=value
      """

      assert INIParser.parse(content) == {
               :ok,
               %{
                 "key" => "value=with=equals",
                 "section" => %{
                   "url" => "http://example.com?param=value"
                 }
               }
             }
    end

    test "empty section name" do
      content = """
      []
      value = 1
      """

      assert INIParser.parse(content) ==
               {:error, "Failed to parse INI content: Invalid section format: Empty section name"}
    end
  end
end
