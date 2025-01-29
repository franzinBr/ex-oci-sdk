# ex-oci-sdk

An Elixir SDK for Oracle Cloud Infrastructure (OCI) designed to provide a clean and efficient way to interact with OCI services. Built on Elixir's principles of simplicity and maintainability, this SDK offers a straightforward interface while maintaining the robustness required for enterprise cloud applications.

## Installation

The package can be installed by adding `ex_oci_sdk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_oci_sdk, "~> 0.1.0"},
    # Optional dependencies
    {:hackney, "~> 1.20.1"},  # Default HTTP client
    {:jason, "~> 1.4.4"}      # Default JSON parser
  ]
end
```

The SDK is designed to be flexible with its dependencies. While it comes with default implementations using Hackney for HTTP requests and Jason for JSON parsing, you can implement your own client modules by following the behaviour specifications in the documentation.

## Usage

### Basic Example

```elixir
# Loading configs from a OCI config file
config =
  ExOciSdk.Config.from_file!("~/.oci/config")

# Create SDK Base Client
client = ExOciSdk.Client.create!(config)

# Create Queue Client
queue_client =
  ExOciSdk.Queue.QueueClient.create(client)

queue_id = "QUEUE_OCID"

# Put messages in a queue
{:ok, _} = ExOciSdk.Queue.QueueClient.put_messages(queue_client, queue_id, %{
  "messages" => [
    %{"content" => "Hello world from ex-oci-sdk"},
    %{"content" => ":D"},
  ]
})

# Get messages from a queue
{:ok, messages} = ExOciSdk.Queue.QueueClient.get_messages(queue_client, queue_id,
   limit: 10,
   timeout_in_seconds: 0
)
```

### Supported Services

- Queue

## Documentation

Detailed documentation is available at [https://hexdocs.pm/ex_oci_sdk](https://hexdocs.pm/ex_oci_sdk).

## License

This project is licensed under the Apache License 2.0 License - see the license file for details.

## Project Status

This project is under active development. Contributions are welcome!
