defmodule Ecto.DateTimeRangeTest do
  # @related [subject](/lib/ecto/date_time_range.ex)
  @moduledoc false
  use Test.DataCase, async: true

  alias Ecto.DateTimeRange

  doctest Ecto.DateTimeRange

  describe "sigil_t" do
    import Ecto.DateTimeRange, only: [sigil_t: 2]

    test "creates a date time range from two ISO8601 timestamps" do
      ~t{2020-02-02T00:01:00Z..2020-02-02T00:01:01Z}
      |> assert_eq(%DateTimeRange.UTCDateTime{
        start_at: ~U[2020-02-02 00:01:00Z],
        end_at: ~U[2020-02-02 00:01:01Z]
      })

      ~t{2020-02-02T00:01:00Z..2020-02-02T00:01:01Z}U
      |> assert_eq(%DateTimeRange.UTCDateTime{
        start_at: ~U[2020-02-02 00:01:00Z],
        end_at: ~U[2020-02-02 00:01:01Z]
      })
    end

    test "creates a time range from two ISO8601 timestamps" do
      ~t{00:01:00..00:01:01}T
      |> assert_eq(%DateTimeRange.Time{
        start_at: ~T[00:01:00],
        end_at: ~T[00:01:01]
      })
    end

    test "raises an ArgumentError when not given two timestamps" do
      assert_raise ArgumentError, fn ->
        ~t{2020-02-02T00:01:00Z - derp}
      end

      assert_raise ArgumentError, fn ->
        ~t{blerp - 2020-02-02T00:01:00Z}
      end

      assert_raise ArgumentError, fn ->
        ~t{some junk}
      end
    end
  end
end
