# Ecto DateTime Ranges

[![CI](https://github.com/synchronal/ecto_date_time_range/actions/workflows/tests.yml/badge.svg)](https://github.com/synchronal/ecto_date_time_range/actions)
[![Hex
pm](http://img.shields.io/hexpm/v/ecto_date_time_range.svg?style=flat)](https://hex.pm/packages/ecto_date_time_range)

An `Ecto.Type` for utilizing `tstzrange` fields in Postgres.

- Repo: https://github.com/synchronal/ecto_date_time_range
- Hex docs: https://hexdocs.pm/ecto_date_time_range

Our open source `Ecto.Type` libraries:

- [ecto_date_time_range](https://github.com/synchronal/ecto_date_time_range)
- [ecto_email](https://github.com/synchronal/ecto_email)
- [ecto_phone](https://github.com/synchronal/ecto_phone)

This library is tested against the most recent 3 versions of Elixir and Erlang.

## Sponsorship 💕

This library is part of the [Synchronal suite of libraries and tools](https://github.com/synchronal)
which includes more than 15 open source Elixir libraries as well as some Rust libraries and tools.

You can support our open source work by [sponsoring us](https://github.com/sponsors/reflective-dev).
If you have specific features in mind, bugs you'd like fixed, or new libraries you'd like to see,
file an issue or contact us at [contact@reflective.dev](mailto:contact@reflective.dev).

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
