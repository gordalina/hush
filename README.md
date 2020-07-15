# Hush

[![Build Status](https://github.com/gordalina/hush/workflows/ci/badge.svg)](https://github.com/gordalina/hush/actions?query=workflow%3A%22ci%22)
[![Coverage Status](https://coveralls.io/repos/gordalina/hush/badge.svg?branch=master)](https://coveralls.io/r/gordalina/hush?branch=master)
[![hex.pm version](https://img.shields.io/hexpm/v/hush.svg)](https://hex.pm/packages/hush)

Hush makes it easy to configure your application at runtime and in release mode, it can retrieve configuration from multiple sources and is easily extensible.

You'd use Hush as a configuration tuple, which gets replaced at runtime, this is useful to inject configuration that is not known at compile time.

```elixir
# config/prod.exs
alias Hush.Provider.{GcpSecretManager,SystemEnvironment}

config :your_app_name, Web.Endpoint,
  http: [port: {:hush, SystemEnvironment, "PORT", [cast: :integer]}]
  secret_key_base: {:hush, GcpSecretManager, "secret_key_base"}
```

Hush ships with a `SystemEnvironment` provider which reads environmental variables, but multiple providers exist to make your life easy in reading from other sources:

| Provider | Description |
| -------- | ----------- |
| `SystemEnvironment` | Read environmental variables |
| [`GcpSecretManager`](https://github.com/gordalina/hush_gcp_secret_manager) | Load secrets from Google Cloud Platform's [Secret Manager](https://cloud.google.com/secret-manager). |

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

Some providers may need to initialize applications to function correctly. `SystemEnvironment` does not require any initialization and does not need to be in the list below.

```elixir
# config/config.exs

config :hush,
  providers: [
    GcpSecretsManager
  ]
```

## Resolving Runtime Configuration

Hush can be loaded by calling it directly, or by using its release [Config.Provider](https://hexdocs.pm/elixir/Config.Provider.html).

**Loading via direct call**

```elixir
# application.ex

def start(_type, _args) do
  Hush.resolve!()
end
```

**Loading via Config Provider**

```elixir
# mix.exs
def project do
  [
    # ...
    releases: [
      your_app_name: [
        config_providers: [{Hush.ConfigProvider, nil}]
      ]
    ]
  ]
  end
```

If you are using Hush in both release and non-release mode, you still want to load it directly:

```elixir
# application.ex

def start(_, _) do
  unless Hush.release_mode?(), do: Hush.resolve!()
end
```

## Usage

The configuration tuple is defined by a `:hush` atom, a provider module, a key for the provider and an optional list of options.

```elixir
{
  :hush,
  provider :: module(),
  key :: String.t(),
  options :: [
    default: any(),
    cast: :string | :integer | :float | :charlist | :atom
  ]
}
```

### Defaults

By default if a given `key` is not found by the provider, Hush will raise an error. To prevent this, provide a `default` in the `options` component of the tuple:

```elixir
# config/prod.exs
alias Hush.Provider.SystemEnvironment

config :your_app_name, Web.Endpoint,
  url: [host: {:hush, SystemEnvironment, "HOST", [default: "my-app.example"]}]
```

### Casting

```elixir
# config/prod.exs
alias Hush.Provider.SystemEnvironment

config :your_app_name, Web.Endpoint,
  http: [port: {:hush, SystemEnvironment, "PORT", [cast: :integer, default: 4000]}]
```

## License

Hush is released under the Apache License 2.0 - see the [LICENSE](LICENSE) file.
