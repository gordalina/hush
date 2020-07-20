# Hush

[![Build Status](https://github.com/gordalina/hush/workflows/ci/badge.svg)](https://github.com/gordalina/hush/actions?query=workflow%3A%22ci%22)
[![Coverage Status](https://coveralls.io/repos/gordalina/hush/badge.svg?branch=master)](https://coveralls.io/r/gordalina/hush?branch=master)
[![hex.pm version](https://img.shields.io/hexpm/v/hush.svg)](https://hex.pm/packages/hush)

Hush makes it easy to configure your application at runtime and in release mode, it can retrieve data from multiple sources and set it in your application configuration automatically.

Hush can be used to inject configuration that is not known at compile time, such as environmental variables (e.g.: Heroku's PORT env var), sensitive credentials such as your database password, or any other information you need.

```elixir
# config/prod.exs
alias Hush.Provider.{GcpSecretManager,SystemEnvironment}

config :app, Web.Endpoint,
  http: [port: {:hush, SystemEnvironment, "PORT", [cast: :integer]}]

config :app, App.Repo,
  password: {:hush, GcpSecretManager, "CLOUDSQL_PASSWORD"}
```

Hush resolves configuration from using providers, it ships with a `SystemEnvironment` provider which reads environmental variables, but multiple providers exist. You can also [write your own easily](#writing-your-own-provider).

| Provider | Description | Link |
| -------- | ----------- | ---- |
| `SystemEnvironment` | Read environmental variables | |
| `GcpSecretManager` | Load secrets from Google Cloud Platform's [Secret Manager](https://cloud.google.com/secret-manager). | [GitHub](https://github.com/gordalina/hush_gcp_secret_manager) |

## Installation

Add `hush` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hush, "~> 0.0.4"}
  ]
end
```

Run `mix deps.get` to install it.

## Configuration

Some providers may need to initialize applications to function correctly. The providers will be explicit about whether they need to be loaded at startup or not. `GcpSecretsManager` unlike `SystemEnvironment` is one such example. To load the provider you need to configure it like so. **Note:**  does not need to be loaded at startup.

```elixir
# config/config.exs

config :hush,
  providers: [
    GcpSecretsManager
  ]
```

## Usage

Hush can be loaded in two ways, at runtime in your application, or as a [Config.Provider](https://hexdocs.pm/elixir/Config.Provider.html) in release mode.

**Loading at runtime**

```elixir
# application.ex

def start(_type, _args) do
  Hush.resolve!()
end
```

**Loading via in release mode**

To load hush as a config provider, you need to define in your `releases` in `mix.exs`.

```elixir
def project do
  [
    # ...
    releases: [
      app: [
        config_providers: [{Hush.ConfigProvider, nil}]
      ]
    ]
  ]
  end
```

If you are using Hush in both release and non-release mode, you still want to load it directly, but only in non-release mode:

```elixir
# application.ex

def start(_, _) do
  unless Hush.release_mode?(), do: Hush.resolve!()
end
```

## Configuration format

Hush will resolve any tuple in the following format into a value.

```elixir
{:hush, Hush.Provider, "key", options \\ []}
```

`Hush.Provider` can be any module that implements its behaviour.
`"key"` is passed to the provider to retrieve the data.
`options` is a a Keyword list with the following properties:

- `default: any()` - If the provider can't find the value, hush will return this value
- `optional: boolean()` - By default, Hush will raise an error if it cannot find a value and there's no default, unless you mark it as `optional`.
- `cast: :string | :atom | :charlist | :float | :integer | :boolean | :module` - You can ask Hush to cast the value to a Elixir native type.

### Examples

By default if a given `key` is not found by the provider, Hush will raise an error. To prevent this, provide a `default` in the `options` component of the tuple:

#### Default

```elixir
# config/config.exs
alias Hush.Provider.SystemEnvironment

config :app,
  url: {:hush, SystemEnvironment, "HOST", default: "example.domain"}

# result without environmental variable
assert "example.domain" == Application.get_env(:app, :url)

# result with env HOST=production.domain
assert "production.domain" == Application.get_env(:app, :url)
```

#### Casting

Here we are reading the `PORT` environmental variable, casting it to an integer and returning it

```elixir
# config/config.exs
alias Hush.Provider.SystemEnvironment

config :app,
  port: {:hush, SystemEnvironment, "PORT", cast: :integer, default: 4000}

# result without environmental variable
assert 4000 == Application.get_env(:app, :url)

# result with env PORT=443
assert 443 == Application.get_env(:app, :url)
```

#### Optional

```elixir
# config/dev.exs
alias Hush.Provider.SystemEnvironment

config :app,
  can_be_nil: {:hush, SystemEnvironment, "KEY", optional: true}

# result without environmental variable
assert nil == Application.get_env(:app, :can_be_nil)

# result with env KEY="is not nil"
assert "is not nil" == Application.get_env(:app, :can_be_nil)
```

## Writing your own provider

An example provider is `Hush.Provider.SystemEnvironment`, which reads
environmental variables at runtime. Here's an example of how that provider
would look in a app configuration.

```elixir
  alias Hush.Provider.SystemEnvironment

  config :app, Web.Endpoint,
    http: [port: {:hush, SystemEnvironment, "PORT", [cast: :integer, default: 4000]}]
```

This behaviour expects two functions:

- ```elixir
  load(config :: Keyword.t()) :: :ok | {:error, any()}
  ```

  This function is called at startup time, here you can perform any initialization you need, such as loading applications that you depend on.

- ```elixir
  fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found} | {:error, any()}
  ```

  This function is called when hush is resolving a key with you provider.
  Ensure that you implement a `{:error, :not_found}` if the value can't be found as hush will replace with it a default one if the user providede one.

  Note: All values are required by default, so if the user did not supply a default or made it optional, hush will trigger the error, you don't need to handle that use-case.

To implement that provider we can use the following code.

```elixir
  defmodule Hush.Provider.SystemEnvironment do
  @moduledoc """
  Provider to resolve runtime environmental variables
  """

  @behaviour Hush.Provider

  @impl Hush.Provider
  @spec load(config :: Keyword.t()) :: :ok | {:error, any()}
  def load(_config), do: :ok

  @impl Hush.Provider
  @spec fetch(key :: String.t()) :: {:ok, String.t()} | {:error, :not_found}
  def fetch(key) do
    case System.get_env(key) do
      nil -> {:error, :not_found}
      value -> {:ok, value}
    end
  end
end
```

## License

Hush is released under the Apache License 2.0 - see the [LICENSE](LICENSE) file.
