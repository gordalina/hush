defmodule Hush do
  @moduledoc """
  Extensible runtime configuration loader with pluggable providers
  """

  def resolve!() do
    runtime_config() |> resolve!()
  end

  def resolve!(config) when is_list(config) do
    config |> load!()
    config |> Enum.map(&resolve!(&1))
  end

  def resolve!({app, config}) do
    with config <- Hush.Resolver.resolve!(config),
         :ok <- Application.put_all_env([{app, config}]) do
      {app, config}
    end
  end

  def release_mode? do
    !function_exported?(Mix, :env, 0)
  end

  defp load!(config) do
    for provider <- providers(config) do
      case provider.load(config) do
        {:error, message} ->
          raise ArgumentError, "Could not load provider #{provider}: #{message}"
        _ -> :ok
      end
    end
  end

  defp providers(config) do
    config
    |> Keyword.get(:hush, providers: [])
    |> Keyword.get(:providers, [])
  end

  defp runtime_config() do
    for {app, _, _} <- Application.loaded_applications() do
      {app, Application.get_all_env(app)}
    end
  end
end
