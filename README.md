# Ecto DateTime Ranges

An `Ecto.Type` for utilizing `tstzrange` fields in Postgres.

This library is tested against the most recent 3 versions of Elixir and Erlang.

## Installation

```elixir
def deps do
  [
    {:ecto_date_time_range, "~> 1.3"}
  ]
end
```

## Usage

Up-to-date documentation on how to use the Ecto types provided by this libary can be found in the
[hex docs](https://hexdocs.pm/ecto_date_time_range/):

https://hexdocs.pm/ecto_date_time_range/

## Alternatives you might like

- [pg_ranges](https://hex.pm/packages/pg_ranges)

## Development

```shell
brew bundle
bin/dev/doctor
bin/dev/test
bin/dev/shipit
```
