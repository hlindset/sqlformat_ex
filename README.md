# SqlformatEx

[![hex.pm](https://img.shields.io/hexpm/v/sqlformat_ex.svg)](https://hex.pm/packages/sqlformat_ex) [![docs](https://img.shields.io/badge/hexdocs-docs-336791.svg)](https://hexdocs.pm/sqlformat_ex/)

Elixir bindings for the Rust
[`sqlformat`](https://crates.io/crates/sqlformat/0.5.0) library.

On supported platforms, precompiled NIFs are downloaded automatically.

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
