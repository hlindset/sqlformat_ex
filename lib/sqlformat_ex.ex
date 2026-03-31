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
  @type error_reason ::
          {:invalid_sql, String.t()}
          | {:invalid_options, String.t()}
          | {:format_failed, String.t()}

  @type format_result :: {:ok, String.t()} | {:error, error_reason()}

  @known_option_keys [
    :params,
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

  @option_key_names Map.new(@known_option_keys, &{Atom.to_string(&1), &1})

  @options_schema NimbleOptions.new!(
                    params: [
                      type: {:or, [nil, {:list, :any}, {:map, {:or, [:string, :atom]}, :any}]},
                      default: nil,
                      doc: "Parameter values used for interpolation.",
                      type_doc: "`nil`, an indexed list, or a named map/keyword list"
                    ],
                    indent: [
                      type:
                        {:or,
                         [
                           {:in, 1..255},
                           {:tuple, [{:in, [:spaces]}, {:in, 1..255}]},
                           {:in, [:tabs]}
                         ]},
                      doc: "Indentation to use in formatted output.",
                      type_doc: "`1..255`, `{:spaces, n}`, or `:tabs`"
                    ],
                    uppercase: [
                      type: {:or, [:boolean, nil]},
                      doc: "Whether to uppercase SQL keywords."
                    ],
                    lines_between_queries: [
                      type: {:in, 0..255},
                      doc: "Blank lines to insert between queries."
                    ],
                    ignore_case_convert: [
                      type: {:or, [nil, {:list, {:or, [:string, :atom]}}]},
                      doc: "Keywords to leave unchanged during case conversion.",
                      type_doc: "`[String.t() | atom()] | nil`"
                    ],
                    inline: [
                      type: :boolean,
                      doc: "Force single-line output."
                    ],
                    max_inline_block: [
                      type: :non_neg_integer,
                      doc: "Maximum inline parenthesized block length."
                    ],
                    max_inline_arguments: [
                      type: {:or, [:non_neg_integer, nil]},
                      doc: "Maximum inline argument list length."
                    ],
                    max_inline_top_level: [
                      type: {:or, [:non_neg_integer, nil]},
                      doc: "Maximum inline top-level query length."
                    ],
                    joins_as_top_level: [
                      type: :boolean,
                      doc: "Treat joins as top-level clauses."
                    ],
                    dialect: [
                      type: {:in, [:generic, :postgresql, :sqlserver, :mssql]},
                      doc: "SQL dialect to format for.",
                      type_doc: "`:generic`, `:postgresql`, `:sqlserver`, or `:mssql`"
                    ]
                  )

  @doc """
  Formats a SQL string using the Rust `sqlformat` crate.

  Returns `{:ok, formatted_sql}` on success or `{:error, reason}` on failure.

  Supported options:

  #{NimbleOptions.docs(@options_schema)}
  """
  @spec format(String.t(), options()) :: format_result()
  def format(sql, opts \\ [])

  def format(sql, opts) when is_binary(sql) and is_list(opts) do
    if Keyword.keyword?(opts),
      do: format_result(sql, Map.new(opts)),
      else: invalid_options_result()
  end

  def format(sql, opts) when is_binary(sql) and is_map(opts), do: format_result(sql, opts)

  def format(sql, _opts) when is_binary(sql), do: invalid_options_result()

  def format(_sql, _opts), do: invalid_sql_result()

  @doc """
  Same as `format/2`, but returns the formatted SQL or raises on failure.
  """
  @spec format!(String.t(), options()) :: String.t()
  def format!(sql, opts \\ []) do
    case run_format(sql, opts) do
      {:ok, formatted_sql} -> formatted_sql
      {:error, _reason, exception, stacktrace} -> reraise exception, stacktrace
    end
  end

  defp format_result(sql, opts) do
    case run_format(sql, opts) do
      {:ok, formatted_sql} -> {:ok, formatted_sql}
      {:error, reason, _exception, _stacktrace} -> {:error, reason}
    end
  end

  defp run_format(sql, opts) when is_binary(sql) and is_map(opts) do
    with {:ok, validated_opts} <- validate_options(opts) do
      {params, format_opts} = split_options(validated_opts)
      {:ok, format_nif(sql, params, format_opts)}
    end
  rescue
    exception ->
      {:error, {:format_failed, Exception.message(exception)}, exception, __STACKTRACE__}
  end

  defp run_format(sql, opts) when is_binary(sql) and is_list(opts) do
    if Keyword.keyword?(opts), do: run_format(sql, Map.new(opts)), else: invalid_options_error()
  end

  defp run_format(sql, _opts) when is_binary(sql), do: invalid_options_error()
  defp run_format(_sql, _opts), do: invalid_sql_error()

  defp invalid_sql_result do
    {:error, invalid_sql_reason()}
  end

  defp validate_options(opts) do
    case opts
         |> canonicalize_options()
         |> NimbleOptions.validate(@options_schema) do
      {:ok, validated_opts} ->
        {:ok, normalize_options(validated_opts)}

      {:error, %NimbleOptions.ValidationError{} = exception} ->
        {:error, {:invalid_options, Exception.message(exception)}, exception, []}
    end
  end

  defp split_options(validated_opts) do
    params = Map.fetch!(validated_opts, :params)

    format_opts =
      validated_opts
      |> Map.delete(:params)

    {params, format_opts}
  end

  defp canonicalize_options(opts) do
    Enum.reduce(opts, %{}, &put_canonical_option/2)
  end

  defp put_canonical_option({key, value}, acc) when is_atom(key), do: Map.put(acc, key, value)

  defp put_canonical_option({key, value}, acc) when is_binary(key) do
    canonical_key = Map.get(@option_key_names, key, key)

    if is_atom(canonical_key) and Map.has_key?(acc, canonical_key) do
      acc
    else
      Map.put(acc, canonical_key, value)
    end
  end

  defp put_canonical_option({key, value}, acc), do: Map.put(acc, key, value)

  defp normalize_options(validated_opts) do
    Map.update!(validated_opts, :params, &normalize_params/1)
    |> maybe_update_option(:indent, &normalize_indent/1)
    |> maybe_update_option(:ignore_case_convert, &normalize_string_list/1)
    |> maybe_update_option(:dialect, &normalize_dialect/1)
  end

  defp maybe_update_option(opts, key, fun) do
    if Map.has_key?(opts, key), do: Map.update!(opts, key, fun), else: opts
  end

  defp normalize_params(nil), do: :none
  defp normalize_params([]), do: :none

  defp normalize_params(params) when is_list(params) do
    if Keyword.keyword?(params) do
      {:named, Enum.map(params, &stringify_pair/1)}
    else
      {:indexed, Enum.map(params, &to_string/1)}
    end
  end

  defp normalize_params(params) when is_map(params) do
    {:named, Enum.map(params, &stringify_pair/1)}
  end

  defp normalize_indent(value) when is_integer(value), do: {:spaces, value}
  defp normalize_indent({:spaces, value}), do: {:spaces, value}
  defp normalize_indent(:tabs), do: :tabs

  defp normalize_string_list(nil), do: nil
  defp normalize_string_list(values), do: Enum.map(values, &to_string/1)

  defp normalize_dialect(:mssql), do: :sqlserver
  defp normalize_dialect(dialect), do: dialect

  defp stringify_pair({key, value}), do: {to_string(key), to_string(value)}

  defp invalid_sql_error do
    {:error, invalid_sql_reason(), ArgumentError.exception("expected sql to be a binary"), []}
  end

  defp invalid_sql_reason do
    {:invalid_sql, "expected sql to be a binary"}
  end

  defp invalid_options_result do
    {:error, invalid_options_reason()}
  end

  defp invalid_options_error do
    {:error, invalid_options_reason(),
     ArgumentError.exception("expected options to be a keyword list or map"), []}
  end

  defp invalid_options_reason do
    {:invalid_options, "expected options to be a keyword list or map"}
  end

  @doc false
  def format_nif(_sql, _params, _options), do: :erlang.nif_error(:nif_not_loaded)
end
