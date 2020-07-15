defmodule Hush.ResolverTest do
  use ExUnit.Case
  doctest Hush.Resolver

  alias Hush.Resolver
  alias Hush.Provider.{DoesNotExist, Echo, Malformed, NotFound}

  test "resolve() successfully" do
    config = [
      {:app, [foo: {:hush, Echo, "bar"}]}
    ]

    assert Resolver.resolve(config) == {:ok, [{:app, [foo: "bar"]}]}
  end

  test "resolve() missing adapter" do
    config = [
      {:app, [foo: {:hush, DoesNotExist, "bar"}]}
    ]

    assert Resolver.resolve(config) ==
             {:error,
              %RuntimeError{
                message:
                  "Elixir.Hush.Provider.DoesNotExist: Ran into an error: Provider Elixir.Hush.Provider.DoesNotExist is not available (nofile)"
              }}
  end

  test "resolve() default nil" do
    config = [
      {:app, [foo: {:hush, NotFound, "HUSH_UNKNOWN"}]}
    ]

    assert Resolver.resolve(config) == {:ok, [{:app, [foo: nil]}]}
  end

  test "resolve() default value" do
    config = [
      {:app,
       [
         foo:
           {:hush, NotFound, "HUSH_UNKNOWN",
            [
              default: "bar"
            ]}
       ]}
    ]

    assert Resolver.resolve(config) == {:ok, [{:app, [foo: "bar"]}]}
  end

  test "resolve() required" do
    config = [
      {:app,
       [
         foo:
           {:hush, NotFound, "HUSH_UNKNOWN",
            [
              required: true
            ]}
       ]}
    ]

    assert Resolver.resolve(config) ==
             {:error,
              %ArgumentError{
                message:
                  "Elixir.Hush.Provider.NotFound: Could not resolve required value from config key 'foo' provided by 'HUSH_UNKNOWN'"
              }}
  end

  test "resolve() with bad cast" do
    config = [
      {:app,
       [
         foo:
           {:hush, Echo, "bar",
            [
              cast: :integer
            ]}
       ]}
    ]

    assert Resolver.resolve(config) ==
             {:error,
              %ArgumentError{
                message:
                  "Elixir.Hush.Provider.Echo: Could not convert config key 'foo' to 'integer' (possible sensitive value was hidden)"
              }}
  end

  test "resolve() with all casts" do
    config = [
      {:app,
       [
         string: {:hush, Echo, "bar", [cast: :string]},
         atom: {:hush, Echo, "ok", [cast: :atom]},
         charlist: {:hush, Echo, "bar", [cast: :charlist]},
         float: {:hush, Echo, "3.14", [cast: :float]},
         integer: {:hush, Echo, "42", [cast: :integer]},
         boolean: {:hush, Echo, "true", [cast: :boolean]},
         module: {:hush, Echo, "Elixir", [cast: :module]}
       ]}
    ]

    {:ok, [app: result]} = Resolver.resolve(config)

    assert result == [
             string: "bar",
             atom: :ok,
             charlist: 'bar',
             float: 3.14,
             integer: 42,
             boolean: true,
             module: Elixir
           ]
  end

  test "resolve() with malformed provider implementation" do
    config = [
      {:app, [foo: {:hush, Malformed, "bar"}]}
    ]

    assert Resolver.resolve(config) ==
             {:error,
              %RuntimeError{
                message:
                  "Elixir.Hush.Provider.Malformed: Ran into an error: Unexpected format from provider: wrong return. Expected {:ok, value}, {:error, :not_found} or {:error, \"error\"}"
              }}
  end
end
