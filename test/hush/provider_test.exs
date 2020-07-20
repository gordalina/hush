defmodule Hush.ProviderTest do
  use ExUnit.Case, async: true
  doctest Hush.Provider

  import Mox

  alias Hush.Provider
  alias Hush.Provider.MockProvider

  defmodule EmptyModule do
  end

  describe "is?/1" do
    test "ok" do
      assert Provider.is?(MockProvider) == :ok
    end

    test "unknown module" do
      msg = "Provider is not available (nofile)"
      assert Provider.is?(ThisModuleDoesNotExist) == {:error, msg}
    end

    test "not a provider" do
      msg = "Provider's fetch/1 is undefined"
      assert Provider.is?(EmptyModule) == {:error, msg}
    end
  end

  describe "fetch/3" do
    test "nil" do
      expect(MockProvider, :fetch, fn _ -> {:error, :not_found} end)
      assert Provider.fetch(MockProvider, "foo") == {:ok, nil}
    end

    test "default" do
      expect(MockProvider, :fetch, fn _ -> {:error, :not_found} end)
      assert Provider.fetch(MockProvider, "foo", default: "bar") == {:ok, "bar"}
    end
  end
end
