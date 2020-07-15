defmodule Hush.Resolver do
  def resolve(config) do
    try do
      {:ok, resolve!(config)}
    rescue
      err -> {:error, err}
    end
  end

  def resolve!(config) do
    Enum.reduce(config, [], fn
      {key, {:hush, provider, name}}, acc ->
        acc ++ [{key, resolve_value!(key, provider, name, [])}]

      {key, {:hush, provider, name, options}}, acc ->
        acc ++ [{key, resolve_value!(key, provider, name, options)}]

      {key, rest = [_ | _]}, acc ->
        acc ++ [{key, resolve!(rest)}]

      other, acc ->
        acc ++ [other]
    end)
  end

  defp resolve_value!(key, provider, name, options) do
    with {:ok, value} <- fetch(provider, name, options),
         {:ok, value} <- cast(value, options) do
      value
    else
      {:ok, :default, value} ->
        value

      {:error, :required} ->
        raise ArgumentError,
          message:
            "#{provider}: Could not resolve required value from config key '#{key}' provided by '#{
              name
            }'"

      {:error, {:cast, type}} ->
        raise ArgumentError,
          message:
            "#{provider}: Could not convert config key '#{key}' to '#{type}' (possible sensitive value was hidden)"

      {:error, error} ->
        raise RuntimeError, message: "#{provider}: Ran into an error: #{error}"
    end
  end

  defp fetch(provider, name, options) do
    with :ok <- Hush.Provider.is?(provider),
         {:ok, value} <- provider.fetch(name)
    do
      {:ok, value}
    else
      {:error, :not_found} ->
        default_or_error(options)

      {:error, error} ->
        {:error, error}

      unexpected ->
        {:error,
         "Unexpected format from provider: #{unexpected}. Expected {:ok, value}, {:error, :not_found} or {:error, \"error\"}"}
    end
  end

  defp default_or_error(options) do
    cond do
      # lets get default if it exists
      Keyword.has_key?(options, :default) ->
        {:ok, :default, Keyword.get(options, :default)}

      # return error if default is not provided and its required
      Keyword.get(options, :required, false) ->
        {:error, :required}

      # return nil if not required
      true ->
        {:ok, nil}
    end
  end

  defp cast(value, options) do
    type = Keyword.get(options, :cast, :string)

    try do
      {:ok, cast!(value, type)}
    rescue
      _err -> {:error, {:cast, type}}
    end
  end

  defp cast!(value, :string), do: value
  defp cast!(value, :atom), do: String.to_existing_atom(value)
  defp cast!(value, :charlist), do: String.to_charlist(value)
  defp cast!(value, :float), do: String.to_float(value)
  defp cast!(value, :integer), do: String.to_integer(value)
  defp cast!(value, :boolean), do: cast!(value, :atom)
  defp cast!(value, :module), do: cast!(value, :atom)
end
