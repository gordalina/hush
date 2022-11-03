defmodule Hush.Transformer do
  @moduledoc """
  Hush relies on transformers to post process values after resolving them.

  You can [read here](https://hexdocs.pm/hush/readme.html#writing-your-own-transformer) on how to write your own transformer.
  """

  @callback key() :: atom()
  @callback transform(config :: any(), value :: any()) ::
              {:ok, any()} | {:error, atom() | String.t()}

  @transformers [
    Hush.Transformer.Apply,
    Hush.Transformer.Cast,
    Hush.Transformer.ToFile
  ]

  def apply(options, value) do
    try do
      Enum.reduce(transformers(), {:ok, value}, reducer!(options))
    rescue
      error ->
        {:error, Exception.message(error)}
    end
  end

  defp reducer!(options) do
    fn
      mod, {:ok, acc} ->
        case Keyword.get(options, mod.key(), nil) do
          nil -> {:ok, acc}
          config -> mod.transform(config, acc)
        end

      _mod, {:error, error} ->
        {:error, error}
    end
  end

  defp transformers() do
    if override?() do
      Application.get_env(:hush, :transformers, [])
    else
      @transformers ++ Application.get_env(:hush, :transformers, [])
    end
  end

  defp override?() do
    Application.get_env(:hush, :transformers_override, false)
  end
end
