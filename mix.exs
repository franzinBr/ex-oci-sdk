defmodule ExOciSdk.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_oci_sdk,
      description: "Elixir SDK for Oracle Cloud Infrastructure (OCI)",
      version: "0.0.1",
      elixir: "~> 1.18",
      source_url: "https://github.com/franzinBr/ex-oci-sdk",
      homepage_url: "https://github.com/franzinBr/ex-oci-sdk",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
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
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
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
      main: "readme",
      groups_for_modules: groups_for_modules(),
      extras: ["README.md"]
    ]
  end

  defp groups_for_modules do
    [
      Queue: [
        ExOciSdk.Queue.QueueClient,
        ExOciSdk.Queue.Types
      ]
    ]
  end
end
