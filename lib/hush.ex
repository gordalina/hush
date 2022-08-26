defmodule Hush do
  @moduledoc """
  Extensible runtime configuration loader with pluggable providers
  """

  @doc """
  Resolve configuration

  When called with resolve!/0 it will default to all loaded applications' configuration.
  When called with resolve!/1 with the configuration as an argument it will process that.
  """
  @spec resolve!() :: Keyword.t()
  def resolve!() do
    runtime_config() |> resolve!()
  end

  @spec resolve!(Keyword.t(), Keyword.t()) :: Keyword.t()
  def resolve!(config, options \\ Keyword.new())

  def resolve!(config, options) when is_list(config) do
    {:ok, pid} =
      config
      |> load_providers!()
      |> child_specs()
      |> Supervisor.start_link(strategy: :one_for_one)

    options = options || Application.get_all_env(:hush)
    resolved = config |> Enum.map(&resolve!(&1, options))
    Supervisor.stop(pid, :normal)

    resolved
  end

  @spec resolve!({atom(), Keyword.t()}, Keyword.t()) :: {atom(), Keyword.t()}
  def resolve!({app, config}, options) do
    with config <- Hush.Resolver.resolve!(config, options),
         :ok <- Application.put_all_env([{app, config}]) do
      {app, config}
    end
  end

  @doc """
  Is the app running in release mode?
  """
  @spec release_mode?() :: boolean()
  def release_mode? do
    !function_exported?(Mix, :env, 0)
  end

  @spec load_providers!(Keyword.t()) :: Keyword.t()
  defp load_providers!(config) do
    for provider <- providers(config) do
      case provider.load(config) do
        {:error, message} ->
          raise ArgumentError, "Could not load provider #{provider}: #{message}"

        result ->
          result
      end
    end
  end

  @spec providers(Keyword.t()) :: Keyword.t()
  defp providers(config) do
    config
    |> Keyword.get(:hush, providers: [])
    |> Keyword.get(:providers, [])
  end

  @spec runtime_config() :: Keyword.t()
  defp runtime_config() do
    for {app, _, _} <- Application.loaded_applications() do
      {app, Application.get_all_env(app)}
    end
  end

  defp child_specs(providers), do: Enum.reduce(providers, [], &child_specs_reducer/2)
  defp child_specs_reducer({:ok, children}, acc), do: acc ++ children
  defp child_specs_reducer(_, acc), do: acc
end
