defmodule Hush.ConfigProviderTest do
  use ExUnit.Case, async: false
  doctest Hush.ConfigProvider
  alias Hush.ConfigProvider
  alias Hush.Provider.MockProvider

  import Mox

  test "init/1 does nothing" do
    assert ConfigProvider.init(:ignored) == nil
  end

  test "load/2 resolves config" do
    expect(MockProvider, :fetch, fn _ -> {:ok, "bar"} end)
    config = [{:app, foo: {:hush, MockProvider, "bar"}}]

    assert ConfigProvider.load(config, :ignored) == [{:app, foo: "bar"}]
  end
end
