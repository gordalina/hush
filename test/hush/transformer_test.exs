defmodule Hush.TransformerTest do
  use ExUnit.Case
  doctest Hush.Transformer

  import Mox

  alias Hush.Transformer
  alias Hush.Transformer.MockTransformer

  setup do
    on_exit(fn ->
      Application.delete_env(:hush, :transformers)
    end)

    Application.put_env(:hush, :transformers, [MockTransformer])
  end

  describe "apply/2" do
    test "ok" do
      expect(MockTransformer, :key, fn -> :mock end)
      expect(MockTransformer, :transform, fn _, _ -> {:ok, 1} end)
      assert {:ok, 1} == Transformer.apply([mock: true], "1")
    end

    test "fail with error message" do
      expect(MockTransformer, :key, fn -> :mock end)
      expect(MockTransformer, :transform, fn _, _ -> raise "error" end)
      assert {:error, "error"} == Transformer.apply([mock: true], "1")
    end

    test "fail with exception" do
      expect(MockTransformer, :key, fn -> :mock end)
      expect(MockTransformer, :transform, fn _, _ -> raise RuntimeError end)
      assert {:error, "runtime error"} == Transformer.apply([mock: true], "1")
    end
  end
end
