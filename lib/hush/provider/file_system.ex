defmodule Hush.Provider.FileSystem do
  @moduledoc """
  Provider to read secrets from file system
  """

  @behaviour Hush.Provider

  @impl true
  @spec load(config :: Keyword.t()) :: :ok | {:error, any()}
  def load(_config), do: :ok

  @impl true
  @spec fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def fetch(key) do
    Enum.find_value(search_paths(), &read_file(&1, key))
  end

  # sobelow_skip ["Traversal.FileModule"]
  defp read_file(path, key) do
    with {:ok, safe_key} <- safe_relative(key, path),
         {:ok, value} <- File.read(Path.join(path, safe_key)) do
      {:ok, value}
    else
      :error -> {:error, "Path traversal detected: tried to read #{path}/#{key}"}
      _ -> {:error, :not_found}
    end
  end

  defp safe_relative(path, relative_to) do
    cond do
      Version.match?(System.version(), ">= 1.16.0") ->
        apply(Path, :safe_relative, [path, relative_to])

      Version.match?(System.version(), ">= 1.14.0") ->
        apply(Path, :safe_relative_to, [path, relative_to])

      true ->
        case :filelib.safe_relative_path(IO.chardata_to_string(path), relative_to) do
          :unsafe -> :error
          relative_path -> {:ok, IO.chardata_to_string(relative_path)}
        end
    end
  end

  defp search_paths() do
    Application.fetch_env!(:hush, __MODULE__) |> Keyword.get(:search_paths, [])
  end
end
