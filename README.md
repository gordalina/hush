# Hush

[![Build Status](https://img.shields.io/github/workflow/status/gordalina/hush/ci?style=flat-square)](https://github.com/gordalina/hush/actions?query=workflow%3A%22ci%22)
[![Coverage Status](https://img.shields.io/codecov/c/github/gordalina/hush?style=flat-square)](https://app.codecov.io/gh/gordalina/hush)
[![hex.pm version](https://img.shields.io/hexpm/v/hush?style=flat-square)](https://hex.pm/packages/hush)
[![hex.pm downloads](https://img.shields.io/hexpm/dt/hush?style=flat-square)]([LICENSE](https://hex.pm/packages/hush))

Hush is designed to help developers configure their applications at runtime and in release mode, retrieving configuration from multiple providers, without having to depend on secret files or hardcoded configuration.

Documentation can be found at [https://hexdocs.pm/hush](https://hexdocs.pm/hush).

## Overview

Hush can be used to inject configuration that is not known at compile time, such as environmental variables (e.g.: Heroku's PORT env var), sensitive credentials such as your database password, or any other information you need.

```elixir
# config/prod.exs
alias Hush.Provider.{AwsSecretsManager, GcpSecretManager, SystemEnvironment}

config :app, Web.Endpoint,
  http: [port: {:hush, SystemEnvironment, "PORT", [cast: :integer]}]

config :app, App,
  cdn_url: {:hush, GcpSecretManager, "CDN_DOMAIN", [apply: &{:ok, "https://" <> &1}]}

config :app, App.RedshiftRepo,
  password: {:hush, AwsSecretsManager, "REDSHIFT_PASSWORD"}
```

Hush resolves configuration from using providers, it ships with a `SystemEnvironment` provider which reads environmental variables, but multiple providers exist. You can also [write your own easily](#writing-your-own-provider).

| Provider            | Description                                                                               | Link                                                            |
| ------------------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------------------- |
| `SystemEnvironment` | Reads environmental variables.                                                            |                                                                 |
| `AwsSecretsManager` | Load secrets from [AWS Secrets Manager](https://aws.amazon.com/secrets-manager/).         | [GitHub](https://github.com/gordalina/hush_aws_secrets_manager) |
| `GcpSecretManager`  | Load secrets from [Google Cloud Secret Manager](https://cloud.google.com/secret-manager). | [GitHub](https://github.com/gordalina/hush_gcp_secret_manager)  |

## Installation

Add `hush` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hush, "~> 1.0.0"}
  ]
end
```

Run `mix deps.get` to install it.

Some providers may need to initialize applications or even start processes to function correctly. The providers will be explicit about whether they need to be loaded at startup or not. `GcpSecretsManager` unlike `SystemEnvironment` is one such example. To load the provider you need to configure it like so. **Note:** `SystemEnvironment` does not need to be loaded at startup.

```elixir
# config/config.exs

alias Hush.Providers.GcpSecretManager

config :hush,
  providers: [
    GcpSecretManager
  ]
```

## Usage

Hush can be loaded in two ways, at runtime in your application, or as a [Config.Provider](https://hexdocs.pm/elixir/Config.Provider.html) in release mode. A [sample app](https://github.com/gordalina/hush_sample_app) has been written so you can see how it's configured.

### Loading at runtime

```elixir
# application.ex

def start(_type, _args) do
  Hush.resolve!()
end
```

### Loading via in release mode

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

If you are using Hush in runtime and release mode, make sure to only resolve configuration in non release mode:

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

- `Hush.Provider` can be any module that implements its behaviour.
- `"key"` is passed to the provider to retrieve the data.
- `options` is a a Keyword list with the following properties:
  - `default: any()` - If the provider can't find the value, hush will return this value
  - `optional: boolean()` - By default, Hush will raise an error if it cannot find a value and there's no default, unless you mark it as `optional`.
  - `apply: fun(any()) :: {:ok, any()} | {:error, String.t()}` - Apply a function to the value resolved by Hush.
  - `cast: :string | :atom | :charlist | :float | :integer | :boolean | :module` - You can ask Hush to cast the value to a Elixir native type.
  - `to_file: string()` - Write the data to the path give in `to_file()` and return the path.

After Hush resolves a value it runs them through Transfomers.

### Examples

By default if a given `key` is not found by the provider, Hush will raise an error. To prevent this, provide a `default` or `optional: true` in the `options` component of the tuple.

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

## Concurrency & Cache

By default Hush will fetch secrets from providers concurrently and will save them to a short-lived cache to prevent fetching the same secret multiple times.

The defaults for these values are `System.schedulers_online/0` for concurrency and `5000ms` for concurrency timeouts.

These values can be modified with the following configuration:

```elixir
# config/config.exs
config :hush,
  max_concurrency: 10,
  timeout: 5000, # milliseconds
```

## Transfomers

By default Hush ships with the following transformers:

- **Hush.Transfomer.Cast**: Takes an argument `cast` and converts a value into a specific type.
- **Hush.Transfomer.ToFile**: Takes an arugment `to_file` and outputs the value into the path provided.

It is possible to add more transformers by the following configuration:

```elixir
# config/prod.exs

alias Hush.Provider.SystemEnvironment

config :hush,
  transfomers: [
    App.Hush.JsonToMapTransfomer
  ]

config :app,
  allowed_urls: {:hush, SystemEnvironment, "alloweds_urls", [json: true]}
```

It is also possible to override the transforms Hush will process, and the order they will execute in. See [below](#overriding-transformers) for more information.

### Writing your own transfomer

The currently [shipped](https://github.com/gordalina/hush/blob/master/lib/transformer/cast.ex) [transfomers](https://github.com/gordalina/hush/blob/master/lib/transformer/to_file.ex) are good examples on how to implement transformers.

Transformers are executed in order they are defined, first is `Cast`, next is `ToFile` and then the ones configured by you, e.g.:

```elixir
# config/prod.exs

config :hush,
  transformers: [
    App.Hush.JsonTransformer
  ]
```

Lets dissect a transformer as an example. A transformer has to implement the `Hush.Transformer` behaviour, and as such it has to implement the `key/0` and `transform/2` functions.

A transformer is going to be executed if a configuration tuple requests it by passing the value of `key/0` into its options. An example is seeing the `json` parameter being passed into the `value` configuration. Hush will process any transformers in which their `key/0` function returns `:json`.

Once a configuration tuple requests a transfomer, a function `transform/2` is called, where the first argument is what is passed as a value of the `key/0` (in the example below it would be `:abort_on_failure`), and the second argument would be the current value returned by the provider transformed by any previous transformers.

```elixir
# config/prod.exs

config :app,
  value: {:hush, SystemEnvironment, "key", [json: :abort_on_failure]}
```

```elixir
# lib/app/hush/JsonTransformer.ex

defmodule App.Hush.JsonTransformer do
  @behaviour Hush.Transformer

  @impl true
  @spec key() :: :json
  def key(), do :json

  @impl true
  @spec transform(config :: any(), value :: any()) :: {:ok, any()} | {:error, String.t()}
  def transform(config, value) do
    try do
      Jason.decode!(value)
    rescue
      error ->
        case config do
          :abort_on_failure ->
            {:error, "Couldn't convert #{value} to json: #{error.message}"}
          _ ->
            {:ok, nil}
        end
    end
  end
end
```

### Overriding Transformers

The following example woud take a value passed as an environment variable `ALLOWED_URLS='["http://example.com"]'` into a file named `/tmp/urls.json` with the contents `["https://example.com"]`, all due to the order in which the transformers are executed and the fact that `override_transformers` is `true`.

```elixir
# config/prod.exs

config :hush,
  override_transformers: true,
  transformers: [
    Hush.Transformer.Cast,
    App.Hush.HttpToHttpsTransformer,
    App.Hush.JsonTransformer,
    Hush.Transformer.ToFile,
  ]

config :app,
  value: {:hush, SystemEnvironment, "ALLOWED_URLS", [http_to_https: true, json: true, to_file: "/tmp/urls.json" ]}
```

```elixir
# lib/app/hush/HttpToHttpsTransfomer.ex

defmodule App.HttpToHttpsTransfomer do
  @behaviour Hush.Transformer

  @impl true
  @spec key() :: :http_to_https
  def key(), do :http_to_https

  @impl true
  @spec transform(config :: any(), value :: any()) :: {:ok, any()} | {:error, String.t()}
  def transfomer(_config, value) do
    {:ok, Enum.map(value, &http_to_https(&2))}
  end

  def http_to_https(value) do
    Regex.replace(~r/^http:/, value, "https:")
  end
end
```

## Providers

### Writing your own provider

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
  load(config :: Keyword.t()) :: :ok | {:ok, [child_spec()]} | {:error, any()}
  ```

  This function is called at startup time, here you can perform any initialization you need, such as loading applications that you depend on. If you need to startup any processes, you can return a list of `child_spec()` which will be brought up by Hush's supervisor and brought down after hush runs.

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
  @spec load(config :: Keyword.t()) :: :ok | {:ok, [child_spec()]} | {:error, any()}
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

## Compatibility

| Hush | Erlang/OTP | Elixir |
| - | - | - |
| `>= 1.0.0` | `>= 21.0.0` | `>= 1.10.0` |
| `<= 0.5.0` | `>= 20.0.0` | `>= 1.9.0` |

## License

Hush is released under the Apache License 2.0 - see the [LICENSE](LICENSE) file.
