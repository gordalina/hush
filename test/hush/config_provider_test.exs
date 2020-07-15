defmodule Hush.ConfigProviderTest do
  use ExUnit.Case
  doctest Hush.ConfigProvider
  alias Hush.ConfigProvider

  test "init() does nothing" do
    assert ConfigProvider.init(:ignored) == nil
  end

  test "load() resolves config" do
    config = [
      {:app, [foo: {:hush, Hush.Provider.Echo, "bar"}]}
    ]

    assert ConfigProvider.load(config, :ignored) == [{:app, [foo: "bar"]}]
  end
end
