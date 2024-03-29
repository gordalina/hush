defmodule Hush.ResolverTest do
  use ExUnit.Case, async: false
  doctest Hush.Resolver

  import Mox

  alias Hush.Resolver
  alias Hush.Provider.MockProvider

  defmodule CustomError do
    defstruct msg: ""
  end

  describe "resolve/1" do
    test "with keyword lists" do
      expect(MockProvider, :fetch, fn _ -> {:ok, "bar"} end)
      config = app_config({:hush, MockProvider, "bar"})

      assert Resolver.resolve(config) == {:ok, [{:app, [foo: "bar"]}]}
    end

    test "with map" do
      expect(MockProvider, :fetch, fn _ -> {:ok, "map"} end)
      config = app_config(%{key: {:hush, MockProvider, "map"}})

      assert Resolver.resolve(config) == {:ok, [{:app, [foo: %{key: "map"}]}]}
    end

    test "with keyword list" do
      expect(MockProvider, :fetch, fn _ -> {:ok, "list"} end)
      config = app_config(key: {:hush, MockProvider, "list"})

      assert Resolver.resolve(config) == {:ok, [{:app, [foo: [key: "list"]]}]}
    end

    test "with list" do
      expect(MockProvider, :fetch, fn _ -> {:ok, "list"} end)
      config = app_config([{:hush, MockProvider, "list"}])

      assert Resolver.resolve(config) == {:ok, [{:app, [foo: ["list"]]}]}
    end

    test "with tuple" do
      expect(MockProvider, :fetch, fn _ -> {:ok, "tuple"} end)
      config = app_config({{:hush, MockProvider, "tuple"}})

      assert Resolver.resolve(config) == {:ok, [{:app, [foo: {"tuple"}]}]}
    end

    test "with custom struct" do
      expect(MockProvider, :fetch, fn _ -> {:ok, "tuple"} end)

      config = app_config(%Config.Provider{})
      assert Resolver.resolve(config) == {:ok, [{:app, [foo: %Config.Provider{}]}]}
    end

    test "into file" do
      expect(MockProvider, :fetch, fn _ -> {:ok, "contents"} end)

      file = Path.join(System.tmp_dir!(), "__#{:rand.uniform(100_000_000)}")
      config = app_config({:hush, MockProvider, "contents", to_file: file})

      assert Resolver.resolve(config) == {:ok, [{:app, [foo: file]}]}
      assert File.read!(file) == "contents"
    end

    test "with provider exception" do
      expect(MockProvider, :fetch, 2, fn _ -> raise "error" end)
      config = app_config({:hush, MockProvider, "key"})

      error = "Could not resolve {:hush, Elixir.Hush.Provider.MockProvider, \"key\"}: error"
      assert {:error, error} == Resolver.resolve(config)
    end

    test "with provider error" do
      expect(MockProvider, :fetch, 2, fn _ -> {:error, %{error: "error"}} end)
      config = app_config({:hush, MockProvider, "key"})

      error =
        "Could not resolve {:hush, Elixir.Hush.Provider.MockProvider, \"key\"}: %{error: \"error\"}"

      assert {:error, error} == Resolver.resolve(config)
    end

    test "with provider custom error struct" do
      expect(MockProvider, :fetch, 2, fn _ -> {:error, %CustomError{msg: "errmsg"}} end)
      config = app_config({:hush, MockProvider, "key"})

      error =
        "Could not resolve {:hush, Elixir.Hush.Provider.MockProvider, \"key\"}: %Hush.ResolverTest.CustomError{msg: \"errmsg\"}"

      assert {:error, error} == Resolver.resolve(config)
    end

    test "with missing adapter" do
      config = [
        {:app, [foo: {:hush, ThisModuleDoesNotExist, "bar"}]}
      ]

      error =
        "Could not resolve {:hush, Elixir.ThisModuleDoesNotExist, \"bar\"}: Provider is not available (nofile)"

      assert {:error, error} == Resolver.resolve(config)
    end

    test "with required error" do
      expect(MockProvider, :fetch, 2, fn _ -> {:error, :not_found} end)
      config = app_config({:hush, MockProvider, "HUSH_UNKNOWN"})

      error =
        "Could not resolve {:hush, Elixir.Hush.Provider.MockProvider, \"HUSH_UNKNOWN\"}: The provider couldn't find a value for this key. If this is an optional key, you add `optional: true` to the options list."

      assert {:error, error} == Resolver.resolve(config)
    end

    test "with optional set to true" do
      expect(MockProvider, :fetch, 2, fn _ -> {:error, :not_found} end)
      config = app_config({:hush, MockProvider, "HUSH_UNKNOWN", optional: true})
      assert {:ok, app_config(nil)} == Resolver.resolve(config)
    end

    test "with default value" do
      expect(MockProvider, :fetch, 2, fn _ -> {:error, :not_found} end)
      config = app_config({:hush, MockProvider, "HUSH_UNKNOWN", default: :ok})
      assert {:ok, app_config(:ok)} == Resolver.resolve(config)
    end

    test "with expired cache entry" do
      expect(MockProvider, :fetch, 2, fn _ -> {:ok, "value"} end)
      config = app_config({:hush, MockProvider, "HUSH_UNKNOWN", cache_ttl: 0})

      assert {:ok, app_config("value")} == Resolver.resolve(config)
    end

    test "with cast error" do
      expect(MockProvider, :fetch, fn _ -> {:ok, "bar"} end)
      config = app_config({:hush, MockProvider, "bar", cast: :integer})

      {:error, error} = Resolver.resolve(config)

      message = "Could not resolve {:hush, Elixir.Hush.Provider.MockProvider, \"bar\"}"
      assert String.starts_with?(error, message)
    end

    test "with general error" do
      expect(MockProvider, :fetch, 2, fn _ -> "wrong return" end)
      config = app_config({:hush, MockProvider, "bar"})

      error =
        "Could not resolve {:hush, Elixir.Hush.Provider.MockProvider, \"bar\"}: Provider returned an unexpected value: \"wrong return\".\nExpected {:ok, value}, {:error, :not_found} or {:error, \"string\"}"

      assert {:error, error} == Resolver.resolve(config)
    end

    test "with required value" do
      expect(MockProvider, :fetch, 2, fn _ -> {:error, :not_found} end)
      config = app_config({:hush, MockProvider, "bar"})

      error =
        "Could not resolve {:hush, Elixir.Hush.Provider.MockProvider, \"bar\"}: The provider couldn't find a value for this key. If this is an optional key, you add `optional: true` to the options list."

      assert {:error, error} == Resolver.resolve(config)
    end

    test "with cache timeout" do
      MockProvider
      |> expect(:fetch, fn _ -> Process.sleep(25) end)
      |> expect(:fetch, fn _ -> {:ok, "foo"} end)

      config = app_config({:hush, MockProvider, "bar"})
      assert {:ok, app_config("foo")} == Resolver.resolve(config, timeout: 0)
    end
  end

  defp app_config(value) do
    [{:app, [foo: value]}]
  end
end
