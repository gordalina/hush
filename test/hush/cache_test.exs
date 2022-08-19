defmodule Hush.CacheTest do
  use ExUnit.Case, async: false
  doctest Hush.Cache

  import Mox

  alias Hush.Cache
  alias Hush.Provider.MockProvider

  defmodule CustomError do
    defstruct msg: ""
  end

  describe "with/1" do
    test "caches value" do
      Cache.with(fn ->
        expect(MockProvider, :fetch, 1, fn _ -> {:ok, "bar"} end)

        assert {:ok, "bar"} == Cache.get("key", [], fn -> MockProvider.fetch("") end)
        assert {:ok, "bar"} == Cache.get("key", [], fn -> MockProvider.fetch("") end)
      end)
    end

    test "clears cache outside of with" do
      expect(MockProvider, :fetch, 2, fn _ -> {:ok, "bar"} end)

      Cache.with(fn ->
        assert {:ok, "bar"} == Cache.get("key", [], fn -> MockProvider.fetch("") end)
      end)

      assert {:ok, "bar"} == Cache.get("key", [], fn -> MockProvider.fetch("") end)
    end
  end

  describe "get/3" do
    test "caches value" do
      expect(MockProvider, :fetch, 1, fn _ -> {:ok, "bar"} end)

      assert {:ok, "bar"} == Cache.get("key", [], fn -> MockProvider.fetch("") end)
      assert {:ok, "bar"} == Cache.get("key", [], fn -> MockProvider.fetch("") end)
    end

    test "does not cache error value" do
      expect(MockProvider, :fetch, 2, fn _ -> {:error, "bar"} end)

      assert {:error, "bar"} == Cache.get("key", [], fn -> MockProvider.fetch("") end)
      assert {:error, "bar"} == Cache.get("key", [], fn -> MockProvider.fetch("") end)
    end

    test "does not return expired value" do
      expect(MockProvider, :fetch, 2, fn _ -> {:ok, "bar"} end)

      assert {:ok, "bar"} == Cache.get("key", [cache_ttl: 0], fn -> MockProvider.fetch("") end)
      assert {:ok, "bar"} == Cache.get("key", [cache_ttl: 0], fn -> MockProvider.fetch("") end)
    end

    test "ensure table exists" do
      Cache.get("test", [], fn -> :ok end)
      Cache.get("test", [], fn -> :ok end)
    end
  end
end
