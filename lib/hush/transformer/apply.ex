defmodule Hush.Transformer.Apply do
  @moduledoc """
  Apply function transformer
  """

  @behaviour Hush.Transformer

  @impl true
  @spec key() :: :apply
  def key(), do: :apply

  @impl true
  @spec transform(config :: any(), value :: any()) :: {:ok, any()} | {:error, String.t()}
  def transform(fun, value), do: fun.(value)
end
