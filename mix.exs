defmodule ExOciSdk.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_oci_sdk,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:jason, "~> 1.4.4", optional: true}
    ]
  end
end
