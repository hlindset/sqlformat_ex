defmodule SqlformatExTest do
  use ExUnit.Case, async: true

  doctest SqlformatEx

  test "formats a query with defaults" do
    expected =
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

    assert SqlformatEx.format("select count(*), col from t where a = 1 and b = 2;") ==
             {:ok, expected}
  end

  test "interpolates indexed params" do
    expected =
      """
      select
        first,
        second;
      """
      |> String.trim_trailing()

    assert SqlformatEx.format("select ?, ?;", params: ["first", "second"]) == {:ok, expected}
  end

  test "interpolates one-indexed postgres-style params" do
    expected =
      """
      select
        first,
        second,
        third;
      """
      |> String.trim_trailing()

    assert SqlformatEx.format("select $1, $2, $3;", params: ["first", "second", "third"]) ==
             {:ok, expected}
  end

  test "interpolates named params" do
    expected =
      """
      select
        hash value,
        Alice,
        Bob;
      """
      |> String.trim_trailing()

    assert SqlformatEx.format(
             "select $hash, :name, @`var name`;",
             params: [hash: "hash value", name: "Alice", "var name": "Bob"]
           ) == {:ok, expected}
  end

  test "accepts formatting options" do
    expected =
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

    assert SqlformatEx.format(
             "select a, b from foo inner join bar on foo.id = bar.foo_id",
             indent: 4,
             uppercase: false,
             joins_as_top_level: true
           ) == {:ok, expected}
  end

  test "bang variant returns formatted SQL" do
    assert SqlformatEx.format!("select 1") == "select\n  1"
  end

  test "returns an error tuple for invalid options" do
    assert {:error, {:invalid_options, message}} = SqlformatEx.format("select 1", indent: 0)
    assert message =~ ":indent"
  end

  test "raises for invalid options in the bang variant" do
    assert_raise NimbleOptions.ValidationError, ~r/:indent/, fn ->
      SqlformatEx.format!("select 1", indent: 0)
    end
  end

  test "returns an error tuple for unknown option keys" do
    assert {:error, {:invalid_options, message}} = SqlformatEx.format("select 1", uppercaes: true)
    assert message =~ ":uppercaes"
  end

  test "returns an error tuple for lines_between_queries outside the native range" do
    assert {:error, {:invalid_options, message}} =
             SqlformatEx.format("select 1; select 2;", lines_between_queries: 256)

    assert message =~ ":lines_between_queries"
  end

  test "returns an error tuple for invalid SQL input" do
    assert {:error, {:invalid_sql, "expected sql to be a binary"}} = SqlformatEx.format(123, [])
  end
end
