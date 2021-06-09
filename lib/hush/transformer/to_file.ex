defmodule Hush.Transformer.ToFile do
  @moduledoc """
  File writer transformer
  """

  @behaviour Hush.Transformer

  @impl true
  @spec key() :: :to_file
  def key(), do: :to_file

  # sobelow_skip ["Traversal.FileModule"]
  @impl true
  @spec transform(config :: any(), value :: any()) :: {:ok, any()} | {:error, String.t()}
  def transform(path, value) do
    case File.write(path, value) do
      :ok ->
        {:ok, path}

      {:error, reason} ->
        {:error, "Couldn't write file to #{path} due to :#{reason}"}
    end
  end
end
