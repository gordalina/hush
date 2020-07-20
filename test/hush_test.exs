defmodule HushTest do
  use ExUnit.Case, async: true
  doctest Hush

  import Mox

  alias Hush.Provider.MockProvider

  test "release_mode? is false" do
    assert Hush.release_mode?() == false
  end

  test "resolve!()" do
    expect(MockProvider, :fetch, fn _ -> {:ok, "bar"} end)
    Application.put_env(:hush, :test_resolve_1, {:hush, MockProvider, "bar"})

    assert Hush.resolve!()[:hush][:test_resolve_1] == "bar"
  end

  test "resolve!(config)" do
    expect(MockProvider, :fetch, fn _ -> {:ok, "bar"} end)
    config = [{:app, foo: {:hush, MockProvider, "bar"}}]

    assert Hush.resolve!(config) == [{:app, [foo: "bar"]}]
  end

  test "resolve!(config) with invalid provider config" do
    expect(MockProvider, :load, fn _ -> {:error, "fail"} end)
    config = [{:hush, providers: [MockProvider]}]

    assert_raise(
      ArgumentError,
      "Could not load provider Elixir.Hush.Provider.MockProvider: fail",
      fn -> Hush.resolve!(config) == [{:app, [foo: "bar"]}] end
    )
  end
end
