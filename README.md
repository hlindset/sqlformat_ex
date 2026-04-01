# SqlformatEx

[![hex.pm](https://img.shields.io/hexpm/v/sqlformat_ex.svg)](https://hex.pm/packages/sqlformat_ex) [![docs](https://img.shields.io/badge/hexdocs-docs-336791.svg)](https://hexdocs.pm/sqlformat_ex/)

Elixir bindings for the Rust
[`sqlformat`](https://crates.io/crates/sqlformat/0.5.0) library.

On supported platforms, precompiled NIFs are downloaded automatically.

## Toolchains

The default local toolchain is defined in `mise.toml` and uses Elixir 1.19.

Alternate Elixir toolchains are available via mise environments:

```sh
mise exec -E elixir17 -- mix compile
mise exec -E elixir18 -- mix compile
mise exec -- mix compile
```

Each environment pins an explicit Elixir/OTP pair:

- `elixir17`: Elixir 1.17 on OTP 27
- `elixir18`: Elixir 1.18 on OTP 28
- default: Elixir 1.19 on OTP 28

Each environment has its own `MIX_BUILD_ROOT`.

## Installation

Add `sqlformat_ex` to your dependencies:

```elixir
def deps do
  [
    {:sqlformat_ex, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
iex> SqlformatEx.format("select count(*), col from t where a = 1 and b = 2;")
{:ok, "select\n  count(*),\n  col\nfrom\n  t\nwhere\n  a = 1\n  and b = 2;"}

iex> SqlformatEx.format(
...>   "select a, b from foo inner join bar on foo.id = bar.foo_id",
...>   indent: 4,
...>   keyword_casing: :uppercase,
...>   join_layout: :top_level
...> )
{:ok, "SELECT\n    a,\n    b\nFROM\n    foo\nINNER JOIN\n    bar on foo.id = bar.foo_id"}

iex> SqlformatEx.format(
...>   "select $name, :role;",
...>   params: %{name: "Alice", role: "admin"}
...> )
{:ok, "select\n  Alice,\n  admin;"}

iex> SqlformatEx.format(
...>   "select $1, $2",
...>   params: ["John", "user"]
...> )
{:ok, "select\n  John,\n  user;"}

iex> SqlformatEx.format!(
...>   "Select id, name From users",
...>   keyword_casing: :uppercase
...> )
"SELECT\n  id,\n  name\nFROM\n  users"
```

## Option Guide

The full option guide can be found in the documentation for
`SqlformatEx.format/2`.

For the latest published docs, see [HexDocs](https://hexdocs.pm/sqlformat_ex/).
