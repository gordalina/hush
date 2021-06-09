defmodule Hush.Transformer.ApplyTest do
  use ExUnit.Case
  doctest Hush.Transformer.Apply
  alias Hush.Transformer.Apply

  describe "key/0" do
    test "ok" do
      assert :apply == Apply.key()
    end
  end

  describe "transform/2" do
    test "ok" do
      assert {:ok, "a"} == Apply.transform(&{:ok, &1}, "a")
    end

    test "fail" do
      assert {:error, "a"} == Apply.transform(&{:error, &1}, "a")
    end
  end
end
