# Change Log

- require Elixir 1.15 or greater
- test against the latest version of Erlang and Elixir

## 1.2.2

- Updated dependencies.

## 1.2.1

- Relax version matching of `tz` when present.

## 1.2.0

- Documentation TOC organization.
- Add `Ecto.DateTimeRange.NaiveDateTime`.

## 1.1.0

- `Ecto.DateTimeRange.Time.contains?/2` handles `DateTime` and `NaiveDateTime` values.

## 1.0.0

**Breaking Changes**

- Remove `Ecto.UTCDateTimeRange` and `Ecto.UTCTimeRange`.
- Changes `sigil_t`:
  - Defaults to `Ecto.DateTimeRange.UTCDateTime`.
  - Changes `U` modifier to return `Ecto.DateTimeRange.UTCDateTime`.
  - Changes `T` modifier to return `Ecto.DateTimeRange.Time`.

**Upgrading**

1. Update to version `0.99.0`.
1. Fix all deprecation warnings by switching code to use `Ecto.DateTimeRange.UTCDateTime` instead of
  `Ecto.UTCDateTimeRange` and `Ecto.DateTimeRange.Time` instead of `Ecto.UTCTimeRange`. **Important:**
  when using time ranges, `tz` is ignored when provided in form params, and no time zone casting is
  applied. Any time zone logic must be applied in application code.
1. Switch usage of `sigil_t` to use the `u` or `t` modifiers, specifying the new modules.
1. Update to version `1.0.0`.
1. Switch usage of `sigil_t` to use the `U` or `T` modifiers.

## 0.99.0

- Deprecate `Ecto.UTCDateTimeRange` and `Ecto.UTCTimeRange`.
- Add `Ecto.DateTimeRange.UTCDateTime` type.

This release represents the last `0.x` version.

## 0.4.0

- Add `Ecto.DateTimeRange.Time` type, representing a naive time range.

## 0.3.1

- Fix `Ecto.UTCTimeRange.contains?/2` to handle ranges crossing day barrier.

## 0.3.0

- Add `Ecto.UTCDateTimeRange.contains?/2`.
- Add `Ecto.UTCTimeRange.contains?/2`.

## 0.2.0

- Move `~t` to `Ecto.DateTimeRange`.
- Add `Ecto.UTCTimeRange` type.
- Add `Ecto.RangeOperators.contains/2` macro.

## 0.1.1

- Update docs regarding setup, form data.
- Clarify errors in UTCDateTimeRange's `sigil_t` and `parse`.

## 0.1.0

- Initial release of `Ecto.UTCDateTimeRange`.
