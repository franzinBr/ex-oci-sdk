# Base Client

The `ExOciSdk.Client` module is your gateway to OCI services. Let's explore how to use and customize it effectively.

## Creating a Client

The basic way to create a client:

```elixir
client = ExOciSdk.Client.create!(config)
```

config cames from ExOciSdk.Config, see [Configuration](config.md) guide for details.

This creates a client with default settings:
- HTTP Client: Hackney
- JSON Handler: Jason


Now you are ready to start the consumption of oci services.
