defmodule Hush.ResolverTest do
  use ExUnit.Case, async: true
  doctest Hush.Resolver

  import Mox

  alias Hush.Resolver
  alias Hush.Provider.MockProvider

  describe "resolve/1" do
    test "successfully" do
      expect(MockProvider, :fetch, fn _ -> {:ok, "bar"} end)
      config = app_config({:hush, MockProvider, "bar"})

      assert Resolver.resolve(config) == {:ok, [{:app, [foo: "bar"]}]}
    end

    test "with missing adapter" do
      config = [
        {:app, [foo: {:hush, ThisModuleDoesNotExist, "bar"}]}
      ]

      assert Resolver.resolve(config) ==
               {:error,
                %RuntimeError{
                  message:
                    "An error occured while trying to resolve value in provider: Elixir.ThisModuleDoesNotExist.\nProvider is not available (nofile)"
                }}
    end

    test "with required error" do
      expect(MockProvider, :fetch, fn _ -> {:error, :not_found} end)
      config = app_config({:hush, MockProvider, "HUSH_UNKNOWN", required: true})

      assert Resolver.resolve(config) ==
               {:error,
                %ArgumentError{
                  message:
                    "Could not resolve required configuration 'foo'. I was trying to evaluate 'HUSH_UNKNOWN' with Elixir.Hush.Provider.MockProvider."
                }}
    end

    test "with cast error" do
      expect(MockProvider, :fetch, fn _ -> {:ok, "bar"} end)
      config = app_config({:hush, MockProvider, "bar", cast: :integer})

      assert Resolver.resolve(config) ==
               {:error,
                %ArgumentError{
                  message:
                    "Although I was able to resolve configuration 'foo', I wasn't able to cast it to type 'integer'."
                }}
    end

    test "with general error" do
      expect(MockProvider, :fetch, fn _ -> "wrong return" end)
      config = app_config({:hush, MockProvider, "bar"})

      assert Resolver.resolve(config) ==
               {:error,
                %RuntimeError{
                  message:
                    "An error occured while trying to resolve value in provider: Elixir.Hush.Provider.MockProvider.\nProvider returned an unexpected value: wrong return.\nExpected {:ok, value}, {:error, :not_found} or {:error, \"error\"}"
                }}
    end
  end

  defp app_config(value) do
    [{:app, [foo: value]}]
  end
end
