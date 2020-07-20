defmodule Hush.Provider.SystemEnvironmentTest do
  use ExUnit.Case
  doctest Hush.Provider.SystemEnvironment
  alias Hush.Provider.SystemEnvironment

  describe "load/1" do
    test "ok" do
      assert SystemEnvironment.load(nil) == :ok
    end
  end

  describe "fetch/1" do
    test "without environmental variable" do
      assert SystemEnvironment.fetch("HUSH_UNKNOWN") == {:error, :not_found}
    end

    test "with environmental variable" do
      rand = :rand.uniform(10_000_000_000)
      assert System.put_env("HUSH_#{rand}", "foo") == :ok
      assert SystemEnvironment.fetch("HUSH_#{rand}") == {:ok, "foo"}
    end
  end
end
