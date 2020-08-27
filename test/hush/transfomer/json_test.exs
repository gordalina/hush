defmodule Hush.Transformer.JsonTest do
  use ExUnit.Case
  doctest Hush.Transformer.Json
  alias Hush.Transformer.Json

  defmodule JsonCodec do
    def decode!(str), do: []
  end

  setup do
    on_exit(fn ->
      Application.delete_env(:hush, :json_codec)
    end)

    Application.put_env(:hush, :json_codec, JsonCode)
  end

  describe "key/0" do
    test "ok" do
      assert :json == Json.key()
    end
  end

  describe "transform/2" do
    test "ok" do
      assert {:ok, []} == Json.transform(true, "[]")
    end

    test "fail" do
      error = """
      JSON codec not found. Ensure that hush is configured with a codec:

        config :hush,
          json_codec: Jason
      """

      assert {:error, error} == Json.transform(true, "[]")
    end
  end
end
