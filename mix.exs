defmodule SqlformatEx.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/hlindset/sqlformat_ex"

  def project do
    [
      app: :sqlformat_ex,
      version: @version,
      name: "SqlformatEx",
      description: "Elixir bindings for the Rust sqlformat library",
      package: package(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp preferred_cli_env do
    %{
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.json": :test,
      "coveralls.lcov": :test,
      "coveralls.cobertura": :test,
      "test.watch": :test
    }
  end

  def cli do
    [
      preferred_envs: preferred_cli_env()
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.37", only: :dev, runtime: false},
      {:nimble_options, "~> 1.1"},
      {:rustler_precompiled, ">= 0.0.0"},
      {:rustler, ">= 0.0.0", optional: true},
      {:tidewave, "~> 0.4", only: :dev},
      {:excoveralls, "~> 0.18", only: :test},
      {:junit_formatter, "~> 3.4", only: :test}
    ]
  end

  defp package do
    [
      files: [
        "Cargo.toml",
        "Cargo.lock",
        "lib",
        "native",
        "checksum-*.exs",
        "LICENSE",
        "README.md",
        "CHANGELOG.md",
        "mix.exs"
      ],
      exclude_patterns: [
        "native/sqlformatex/target",
        "native/sqlformatex/target/**"
      ],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
