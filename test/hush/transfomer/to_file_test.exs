defmodule Hush.Transformer.ToFileTest do
  use ExUnit.Case
  doctest Hush.Transformer.ToFile
  alias Hush.Transformer.ToFile

  describe "key/0" do
    test "ok" do
      assert :to_file == ToFile.key()
    end
  end

  describe "transform/2" do
    test "ok" do
      file = Path.join(System.tmp_dir!(), "__#{:rand.uniform(100_000_000)}")
      assert {:ok, file} == ToFile.transform(file, "contents")
      assert File.read!(file) == "contents"
    end

    test "fail" do
      error = "Couldn't write file to /tmp due to :eisdir"
      assert {:error, error} == ToFile.transform("/tmp", "contents")
    end
  end
end
