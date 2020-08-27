defmodule Hush.Transformer.Json do
  @moduledoc """
  Decode JSON strings
  """

  @behaviour Hush.Transformer

  @impl true
  @spec key() :: :json
  def key(), do: :json

  @impl true
  @spec transform(config :: any(), value :: any()) :: {:ok, any()} | {:error, String.t()}
  def transform(_config, value) do
    try do
      {:ok, json_decode!(value, json_codec())}
    rescue
      error ->
        {:error, "Couldn't parse JSON: #{error.message}"}
    end
  end

  defp json_decode!(_json, nil) do
    throw """
    JSON codec not found. Ensure that hush is configured with a codec:

      config :hush,
        json_codec: Jason
    """
  end

  defp json_decode!(json, codec) do
    codec.decode!(json)
  end

  defp json_codec() do
    Application.get_env(:hush, :json_codec, nil)
  end
end
