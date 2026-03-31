defmodule SqlformatEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :sqlformat_ex,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      tidewave:
        "run --no-halt -e 'Agent.start(fn -> Bandit.start_link(plug: Tidewave, port: 4000) end)'"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.37", only: :dev, runtime: false},
      {:nimble_options, "~> 1.1"},
      {:rustler, "~> 0.37.3", runtime: false},
      {:tidewave, "~> 0.4", only: :dev}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v0.1.0",
      source_url: "https://github.com/hlindset/sqlformat_ex"
    ]
  end
end
