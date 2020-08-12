defmodule Hush.Transformer.CastTest do
  use ExUnit.Case
  doctest Hush.Transformer.Cast
  alias Hush.Transformer.Cast

  describe "key/0" do
    test "ok" do
      assert :cast == Cast.key()
    end
  end

  describe "transform/2" do
    test "ok" do
      assert {:ok, 1} == Cast.transform(:integer, "1")
    end

    test "fail" do
      error = "Couldn't cast to type integer due to argument error"
      assert {:error, error} == Cast.transform(:integer, "foo")
    end
  end

  describe "to!/2" do
    test "failure" do
      assert_raise ArgumentError, fn -> Cast.to!(:integer, "foo") end
    end

    test ":string", do: assert("bar" = Cast.to!(:string, "bar"))
    test ":atom", do: assert(:ok = Cast.to!(:atom, "ok"))
    test ":charlist", do: assert('bar' = Cast.to!(:charlist, "bar"))
    test ":float", do: assert(3.14 = Cast.to!(:float, "3.14"))
    test ":integer", do: assert(42 = Cast.to!(:integer, "42"))
    test ":boolean", do: assert(true = Cast.to!(:boolean, "true"))
    test ":module", do: assert(Elixir == Cast.to!(:module, "Elixir"))
  end
end
