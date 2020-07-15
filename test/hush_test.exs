defmodule HushTest do
  use ExUnit.Case
  doctest Hush

  test "release_mode? is false" do
    assert Hush.release_mode?() == false
  end

  test "resolve!()" do
    Application.put_env(:hush, :test_resolve_1, {:hush, Hush.Provider.Echo, "bar"})

    assert Hush.resolve!()[:hush][:test_resolve_1] == "bar"
  end

  test "resolve!(config)" do
    config = [
      {:app, [foo: {:hush, Hush.Provider.Echo, "bar"}]}
    ]

    assert Hush.resolve!(config) == [{:app, [foo: "bar"]}]
  end
end
