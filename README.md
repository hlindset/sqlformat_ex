# SqlformatEx

Elixir bindings for the Rust [`sqlformat`](https://crates.io/crates/sqlformat/0.5.0) library,
implemented as a Rustler NIF.

## Installation

Add `sqlformat_ex` to your dependencies:

```elixir
def deps do
  [
    {:sqlformat_ex, "~> 0.1.0"}
  ]
end
```

The native library is compiled automatically through Rustler when the project is compiled.

## Usage

```elixir
iex> SqlformatEx.format("select count(*), col from t where a = 1 and b = 2;")
"select\n  count(*),\n  col\nfrom\n  t\nwhere\n  a = 1\n  and b = 2;"

iex> SqlformatEx.format(
...>   "select a, b from foo inner join bar on foo.id = bar.foo_id",
...>   indent: 4,
...>   uppercase: true,
...>   joins_as_top_level: true
...> )
"SELECT\n    a,\n    b\nFROM\n    foo\nINNER JOIN\n    bar on foo.id = bar.foo_id"

iex> SqlformatEx.format(
...>   "select $name, :role;",
...>   params: %{name: "Alice", role: "admin"}
...> )
"select\n  Alice,\n  admin;"
```

## Supported Options

`SqlformatEx.format/2` accepts a keyword list or map with:

- `:params` - `nil`, a positional list, or a named keyword list/map
- `:indent` - `1..255`, `{:spaces, n}`, or `:tabs`
- `:uppercase` - `true`, `false`, or `nil`
- `:lines_between_queries` - non-negative integer
- `:ignore_case_convert` - list of keywords to leave unchanged
- `:inline` - keep the whole query on one line when `true`
- `:max_inline_block` - max inline parenthesized block length
- `:max_inline_arguments` - max inline argument list length
- `:max_inline_top_level` - max inline top-level query length
- `:joins_as_top_level` - treat joins as top-level clauses
- `:dialect` - `:generic`, `:postgresql`, `:sqlserver`, or `:mssql`

The option surface mirrors the upstream [`FormatOptions`](https://docs.rs/sqlformat/latest/sqlformat/struct.FormatOptions.html)
and [`QueryParams`](https://docs.rs/sqlformat/latest/sqlformat/enum.QueryParams.html) APIs.
