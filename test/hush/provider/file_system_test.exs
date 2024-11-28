defmodule Hush.Provider.FileSystemTest do
  use ExUnit.Case
  doctest Hush.Provider.FileSystem
  alias Hush.Provider.FileSystem

  describe "load/1" do
    test "ok" do
      assert FileSystem.load(nil) == :ok
    end
  end

  describe "fetch/1" do
    test "without file" do
      Application.put_env(:hush, FileSystem, search_paths: ["/tmp"])
      assert FileSystem.fetch("HUSH_UNKNOWN") == {:error, :not_found}
    end

    test "path traversal" do
      Application.put_env(:hush, FileSystem, search_paths: ["/tmp"])

      assert FileSystem.fetch("../etc/passwd") ==
               {:error, "Path traversal detected: tried to read /tmp/../etc/passwd"}
    end

    test "with file" do
      rand = :rand.uniform(10_000_000_000)

      Application.put_env(:hush, FileSystem, search_paths: ["/tmp"])
      assert File.write("/tmp/HUSH_#{rand}", "foo") == :ok
      assert FileSystem.fetch("HUSH_#{rand}") == {:ok, "foo"}
      assert File.rm("/tmp/HUSH_#{rand}") == :ok
    end
  end
end
