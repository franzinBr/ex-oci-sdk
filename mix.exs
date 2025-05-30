defmodule ExOciSdk.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_oci_sdk,
      description: "Elixir SDK for Oracle Cloud Infrastructure (OCI)",
      version: "0.2.2",
      elixir: "~> 1.15",
      source_url: "https://github.com/franzinBr/ex-oci-sdk",
      homepage_url: "https://github.com/franzinBr/ex-oci-sdk",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :public_key]
    ]
  end

  defp deps do
    [
      {:hackney, "~> 1.20.1", optional: true},
      {:jason, "~> 1.4.4", optional: true},
      {:mox, "~> 1.0", only: :test},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp package do
    [
      maintainers: ["Alan Franzin"],
      links: %{"GitHub" => "https://github.com/franzinBr/ex-oci-sdk"},
      licenses: ["Apache-2.0"]
    ]
  end

  defp docs do
    [
      main: "overview",
      groups_for_modules: groups_for_modules(),
      extras: extras(),
      groups_for_extras: groups_for_extras()
    ]
  end

  defp groups_for_modules do
    [
      "HTTP/Json Behaviours & Impl": [
        ExOciSdk.HTTPClient,
        ExOciSdk.HTTPClient.Hackney,
        ExOciSdk.JSON,
        ExOciSdk.JSON.Jason,
        ExOciSdk.JSON.Native
      ],
      Queue: [
        ExOciSdk.Queue.QueueClient,
        ExOciSdk.Queue.QueueAdminClient,
        ExOciSdk.Queue.Types
      ]
    ]
  end

  defp extras do
    [
      "CHANGELOG.md",
      "guides/overview.md",
      "guides/installation.md",
      "guides/configuration_and_client/config.md",
      "guides/configuration_and_client/client.md",
      "guides/queue/queue_client.md",
      "guides/queue/queue_admin_client.md"
    ]
  end

  defp groups_for_extras do
    [
      "Configuration & Base Client": ~r/guides\/configuration_and_client\/.?/,
      Queue: ~r/guides\/queue\/.?/
    ]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.cobertura": :test,
      "coveralls.github": :test
    ]
  end
end
