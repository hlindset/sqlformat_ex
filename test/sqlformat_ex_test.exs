defmodule SqlformatExTest do
  use ExUnit.Case, async: true

  doctest SqlformatEx

  test "formats a query with defaults" do
    assert SqlformatEx.format("select count(*), col from t where a = 1 and b = 2;") ==
             """
             select
               count(*),
               col
             from
               t
             where
               a = 1
               and b = 2;
             """
             |> String.trim_trailing()
  end

  test "interpolates indexed params" do
    assert SqlformatEx.format("select ?, ?;", params: ["first", "second"]) ==
             """
             select
               first,
               second;
             """
             |> String.trim_trailing()
  end

  test "interpolates named params" do
    assert SqlformatEx.format(
             "select $hash, :name, @`var name`;",
             params: [hash: "hash value", name: "Alice", "var name": "Bob"]
           ) ==
             """
             select
               hash value,
               Alice,
               Bob;
             """
             |> String.trim_trailing()
  end

  test "accepts formatting options" do
    assert SqlformatEx.format(
             "select a, b from foo inner join bar on foo.id = bar.foo_id",
             indent: 4,
             uppercase: false,
             joins_as_top_level: true
           ) ==
             """
             select
                 a,
                 b
             from
                 foo
             inner join
                 bar on foo.id = bar.foo_id
             """
             |> String.trim_trailing()
  end

  test "raises for invalid options" do
    assert_raise ArgumentError, ~r/expected :indent/, fn ->
      SqlformatEx.format("select 1", indent: 0)
    end
  end
end
