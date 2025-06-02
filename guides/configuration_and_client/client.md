# Base Client

The `ExOciSdk.Client` module is your gateway to OCI services. Let's explore how to use and customize it effectively.

## Creating a Client

The basic way to create a client:

```elixir
client = ExOciSdk.Client.create!(config)
```

config cames from ExOciSdk.Config, see [Configuration](config.md) guide for details.

This creates a client with default settings:
- HTTP Client: [Hackney](https://hexdocs.pm/hackney/readme.html)
- JSON Handler: Automatically selects [Jason](https://hexdocs.pm/jason/Jason.html) for Elixir < 1.18.0 or [native JSON](https://hexdocs.pm/elixir/JSON.html) for Elixir >= 1.18.0


Now you are ready to start the consumption of oci services.
