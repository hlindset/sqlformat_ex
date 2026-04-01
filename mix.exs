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
      package: package(),
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
      {:rustler_precompiled, ">= 0.0.0"},
      {:rustler, ">= 0.0.0", optional: true},
      {:tidewave, "~> 0.4", only: :dev}
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "native/sqlformatex/src",
        "native/sqlformatex/Cargo*",
        "checksum-*.exs",
        "README.md",
        "mix.exs"
      ],
      links: %{"GitHub" => "https://github.com/hlindset/sqlformat_ex"}
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
