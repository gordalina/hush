defmodule Hush.ProviderTest do
  use ExUnit.Case
  doctest Hush.Provider
  alias Hush.Provider

  test "is?() loaded provider" do
    assert Provider.is?(Hush.Provider.Echo) == :ok
  end

  test "is?() not loaded provider" do
    msg = "Provider Elixir.Hush.Provider.DoesNotExist is not available (nofile)"
    assert Provider.is?(Hush.Provider.DoesNotExist) == {:error, msg}
  end

  test "is?() loaded but not a provider" do
    msg = "Provider Elixir.Hush.Provider.Unimplemented.fetch/1 is undefined"
    assert Provider.is?(Hush.Provider.Unimplemented) == {:error, msg}
  end
end
