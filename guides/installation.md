# Install ExOciSdk

The package can be installed by adding `ex_oci_sdk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_oci_sdk, "~> 0.2.2"},
    # Optional dependencies
    {:hackney, "~> 1.20.1"},  # Default HTTP client
    {:jason, "~> 1.4.4"}      # JSON parser (only needed for Elixir < 1.18.0)
  ]
end
```
