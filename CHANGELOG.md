# Changelog

## Next

- Update to Elixir 1.19

## v1.2.0

- Add FileSystem Provider

## v1.1.0

- Add support for Elixir 1.17 and OTP 27
- Drop support for Elixir 1.10

## v1.0.2

- [#9](https://github.com/gordalina/hush/pull/9) Use Exception.message to retrieve error message. [@martosaur](https://github.com/martosaur)
- [#10](https://github.com/gordalina/hush/pull/10) Do not buffer cache results in Task.async_stream. [@jramos](https://github.com/jramos)

## v1.0.1

- Display a warning when provider fetching times out

## v1.0.0

- Add support to load processes from providers.
- Add asynchronous secret loading.
- Prevent secrets to be fetched more than once.
- Fixed [#7](https://github.com/gordalina/hush/issues/7) where a provider error would raise an error rather than returning a good error message.

## v0.5.0

- [#2](https://github.com/gordalina/hush/pull/2) Add Apply Transformer

  ```ex
    config :app, Web.Endpoint,
      cdn_url: {:hush, GcpSecretManager, "CDN_DOMAIN", [apply: &{:ok, "https://" <> &1}]}
  ```
- Add Elixir 1.12 and OTP/24 compatibility
- Minor CI changes & documentation updates

## v0.4.1

- Add hush_aws_secrets_manager
- Add Elixir 1.11 compatibility
- Documentation updates

## v0.4.0

- Add Transformers to mutate data in runtime.

## v0.3.2

- Add `to_file: String.t()` as an option to pipe secret data into a file.

## v0.3.1

- Bug: Traversing non-iterable structs trips the resolver when running as Config.Provider

## v0.3.0

- Add configuration resolving to lists, maps & tuples
- Better error messages on resolve failure.

## v0.2.0

- Maps can be resolved

## v0.1.0

- Announced public release
