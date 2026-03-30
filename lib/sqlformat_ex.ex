defmodule SqlformatEx do
  @moduledoc """
  Elixir wrapper around the Rust `sqlformat` formatter.

  The main entry point is `format/2`, which accepts a SQL string and an
  optional keyword list or map of formatting options.
  """

  use Rustler,
    otp_app: :sqlformat_ex,
    crate: "sqlformatex",
    mode: if(Mix.env() == :prod, do: :release, else: :debug)

  @type indent :: 1..255 | {:spaces, 1..255} | :tabs
  @type dialect :: :generic | :postgresql | :sqlserver | :mssql
  @type indexed_params :: [term()]
  @type named_params :: %{required(String.t() | atom()) => term()} | keyword(term())
  @type params :: nil | indexed_params | named_params

  @type option ::
          {:params, params}
          | {:indent, indent}
          | {:uppercase, boolean() | nil}
          | {:lines_between_queries, 0..255}
          | {:ignore_case_convert, [String.t() | atom()] | nil}
          | {:inline, boolean()}
          | {:max_inline_block, non_neg_integer()}
          | {:max_inline_arguments, non_neg_integer() | nil}
          | {:max_inline_top_level, non_neg_integer() | nil}
          | {:joins_as_top_level, boolean()}
          | {:dialect, dialect}

  @type options :: [option] | map()

  @option_keys [
    :indent,
    :uppercase,
    :lines_between_queries,
    :ignore_case_convert,
    :inline,
    :max_inline_block,
    :max_inline_arguments,
    :max_inline_top_level,
    :joins_as_top_level,
    :dialect
  ]

  @allowed_option_keys [:params | @option_keys]
  @allowed_option_string_keys Enum.map(@allowed_option_keys, &Atom.to_string/1)

  @doc """
  Formats a SQL string using the Rust `sqlformat` crate.

  Supported options:

    * `:params` - `nil`, an indexed list, or a named map/keyword list
    * `:indent` - `1..255`, `{:spaces, n}`, or `:tabs`
    * `:uppercase` - `true`, `false`, or `nil` to preserve case
    * `:lines_between_queries` - `0..255`
    * `:ignore_case_convert` - list of keywords to leave unchanged
    * `:inline` - force single-line output when `true`
    * `:max_inline_block` - max inline parenthesized block length
    * `:max_inline_arguments` - max inline argument list length
    * `:max_inline_top_level` - max inline top-level query length
    * `:joins_as_top_level` - treat joins as top-level clauses
    * `:dialect` - `:generic`, `:postgresql`, `:sqlserver`, or `:mssql`
  """
  @spec format(String.t(), options()) :: String.t()
  def format(sql, opts \\ [])

  def format(sql, opts) when is_binary(sql) and is_list(opts) do
    if not Keyword.keyword?(opts) do
      raise ArgumentError, "expected options to be a keyword list or map"
    end

    do_format(sql, Map.new(opts))
  end

  def format(sql, opts) when is_binary(sql) and is_map(opts) do
    do_format(sql, opts)
  end

  def format(sql, _opts) when is_binary(sql) do
    raise ArgumentError, "expected options to be a keyword list or map"
  end

  def format(_sql, _opts) do
    raise ArgumentError, "expected sql to be a binary"
  end

  defp do_format(sql, opts) do
    validate_option_keys!(opts)
    params = normalize_params(fetch_option!(opts, :params, nil))
    format_opts = normalize_format_options(opts)

    format_nif(sql, params, format_opts)
  end

  defp normalize_params(nil), do: :none
  defp normalize_params([]), do: :none

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:named, Enum.map(params, fn {key, value} -> {to_string(key), to_string(value)} end)}
    else
      {:indexed, Enum.map(params, &to_string/1)}
    end
  end

  defp normalize_params(params) when is_map(params) do
    {:named, Enum.map(params, fn {key, value} -> {to_string(key), to_string(value)} end)}
  end

  defp normalize_params(_params) do
    raise ArgumentError, "expected :params to be nil, a list, a keyword list, or a map"
  end

  defp normalize_format_options(opts) do
    Enum.reduce(@option_keys, %{}, fn key, acc ->
      case fetch_option(opts, key) do
        :error -> acc
        {:ok, value} -> Map.put(acc, key, normalize_option(key, value))
      end
    end)
  end

  defp normalize_option(:indent, value), do: normalize_indent(value)

  defp normalize_option(:uppercase, value) when is_boolean(value) or is_nil(value), do: value

  defp normalize_option(:uppercase, _value) do
    raise ArgumentError, "expected :uppercase to be true, false, or nil"
  end

  defp normalize_option(:lines_between_queries, value) do
    normalize_integer_in_range(value, :lines_between_queries, 0..255)
  end

  defp normalize_option(:ignore_case_convert, nil), do: nil

  defp normalize_option(:ignore_case_convert, value) when is_list(value) do
    Enum.map(value, &to_string/1)
  end

  defp normalize_option(:ignore_case_convert, _value) do
    raise ArgumentError, "expected :ignore_case_convert to be a list or nil"
  end

  defp normalize_option(:inline, value) when is_boolean(value), do: value

  defp normalize_option(:inline, _value) do
    raise ArgumentError, "expected :inline to be a boolean"
  end

  defp normalize_option(:max_inline_block, value) do
    normalize_non_negative_integer(value, :max_inline_block)
  end

  defp normalize_option(:max_inline_arguments, nil), do: nil

  defp normalize_option(:max_inline_arguments, value) do
    normalize_non_negative_integer(value, :max_inline_arguments)
  end

  defp normalize_option(:max_inline_top_level, nil), do: nil

  defp normalize_option(:max_inline_top_level, value) do
    normalize_non_negative_integer(value, :max_inline_top_level)
  end

  defp normalize_option(:joins_as_top_level, value) when is_boolean(value), do: value

  defp normalize_option(:joins_as_top_level, _value) do
    raise ArgumentError, "expected :joins_as_top_level to be a boolean"
  end

  defp normalize_option(:dialect, value), do: normalize_dialect(value)

  defp normalize_indent(value) when is_integer(value) and value in 1..255, do: {:spaces, value}

  defp normalize_indent({:spaces, value}) when is_integer(value) and value in 1..255,
    do: {:spaces, value}

  defp normalize_indent(:tabs), do: :tabs

  defp normalize_indent(_value) do
    raise ArgumentError, "expected :indent to be 1..255, {:spaces, 1..255}, or :tabs"
  end

  defp normalize_dialect(value) when value in [:generic, :postgresql, :sqlserver], do: value
  defp normalize_dialect(:mssql), do: :sqlserver

  defp normalize_dialect(_value) do
    raise ArgumentError,
          "expected :dialect to be :generic, :postgresql, :sqlserver, or :mssql"
  end

  defp validate_option_keys!(opts) do
    opts
    |> Map.keys()
    |> Enum.reject(&allowed_option_key?/1)
    |> case do
      [] ->
        :ok

      [key | _] ->
        raise ArgumentError,
              "unknown option #{inspect(key)}. Expected one of: #{inspect(@allowed_option_keys)}"
    end
  end

  defp allowed_option_key?(key) when is_atom(key), do: key in @allowed_option_keys
  defp allowed_option_key?(key) when is_binary(key), do: key in @allowed_option_string_keys
  defp allowed_option_key?(_key), do: false

  defp normalize_non_negative_integer(value, _name) when is_integer(value) and value >= 0,
    do: value

  defp normalize_non_negative_integer(_value, name) do
    raise ArgumentError, "expected #{inspect(name)} to be a non-negative integer"
  end

  defp normalize_integer_in_range(value, _name, range)
       when is_integer(value) and value >= range.first and value <= range.last,
       do: value

  defp normalize_integer_in_range(_value, name, range) do
    raise ArgumentError, "expected #{inspect(name)} to be an integer in #{inspect(range)}"
  end

  defp fetch_option!(opts, key, default) do
    case fetch_option(opts, key) do
      {:ok, value} -> value
      :error -> default
    end
  end

  defp fetch_option(opts, key) do
    string_key = Atom.to_string(key)

    cond do
      Map.has_key?(opts, key) -> {:ok, Map.fetch!(opts, key)}
      Map.has_key?(opts, string_key) -> {:ok, Map.fetch!(opts, string_key)}
      true -> :error
    end
  end

  @doc false
  def format_nif(_sql, _params, _options), do: :erlang.nif_error(:nif_not_loaded)
end
