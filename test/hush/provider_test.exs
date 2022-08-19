defmodule Hush.ProviderTest do
  use ExUnit.Case, async: false
  doctest Hush.Provider

  alias Hush.Provider
  alias Hush.Provider.MockProvider

  defmodule EmptyModule do
  end

  describe "valid?/1" do
    test "ok" do
      assert Provider.valid?(MockProvider) == :ok
    end

    test "unknown module" do
      msg = "Provider is not available (nofile)"
      assert Provider.valid?(ThisModuleDoesNotExist) == {:error, msg}
    end

    test "not a provider" do
      msg = "Provider's fetch/1 is undefined"
      assert Provider.valid?(EmptyModule) == {:error, msg}
    end
  end
end
