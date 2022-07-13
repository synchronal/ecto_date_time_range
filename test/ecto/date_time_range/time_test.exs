defmodule Ecto.DateTimeRange.TimeTest do
  # @related [subject](/lib/ecto/date_time_range/time.ex)
  @moduledoc false
  use Test.DataCase, async: true
  alias Ecto.DateTimeRange

  doctest Ecto.DateTimeRange.Time

  deftemptable :things_with_time_ranges do
    column(:during, :tsrange)
    column(:tid, :string)
  end

  setup do
    create_temp_tables()
    :ok
  end

  defmodule Thing do
    @moduledoc false
    use Ecto.Schema

    schema "things_with_time_ranges_temp" do
      field(:during, DateTimeRange.Time)
      field(:tid, :string)
    end

    def changeset(struct \\ %__MODULE__{}, attrs),
      do: struct |> cast(attrs, [:during])
  end

  describe "inserting data" do
    test "casts empty strings to nil" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{"start_at" => "", "end_at" => ""}
               })
               |> Test.Repo.insert()

      assert thing.during |> is_nil()

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(nil)
    end

    test "is ok if the value is a time range in iso8601" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => "00:01",
                   "end_at" => "00:02"
                 }
               })
               |> Test.Repo.insert()

      assert thing.during == %DateTimeRange.Time{
               start_at: ~T[00:01:00],
               end_at: ~T[00:02:00]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%DateTimeRange.Time{
        start_at: ~T[00:01:00],
        end_at: ~T[00:02:00]
      })
    end

    test "is ok if the value is a time range of Times" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => ~T[00:01:01],
                   "end_at" => ~T[00:02:01]
                 }
               })
               |> Test.Repo.insert()

      assert thing.during == %DateTimeRange.Time{
               start_at: ~T[00:01:01],
               end_at: ~T[00:02:01]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%DateTimeRange.Time{
        start_at: ~T[00:01:01],
        end_at: ~T[00:02:01]
      })
    end

    test "sets end_at to the following day if 'earlier' than start_at" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => ~T[00:02:01],
                   "end_at" => ~T[00:01:01]
                 }
               })
               |> Test.Repo.insert()

      assert thing.during == %DateTimeRange.Time{
               start_at: ~T[00:02:01],
               end_at: ~T[00:01:01]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%DateTimeRange.Time{
        start_at: ~T[00:02:01],
        end_at: ~T[00:01:01]
      })

      {:ok, %{rows: [[_, during, _]]}} = Test.Repo.query("select * from things_with_time_ranges_temp")

      during
      |> assert_eq(%Postgrex.Range{
        lower: ~N[0000-01-01 00:02:01.000000],
        lower_inclusive: true,
        upper: ~N[0000-01-02 00:01:01.000000],
        upper_inclusive: false
      })
    end

    test "is an error if the value is not a start and end time" do
      assert {:error, changeset} = Thing.changeset(%{"during" => "five"}) |> Test.Repo.insert()
      assert %{during: ["unable to read start and/or end times"]} = errors_on(changeset)
    end

    test "is an error if the end is equal to the start" do
      assert {:error, changeset} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => ~T[00:01:01],
                   "end_at" => ~T[00:01:01]
                 }
               })
               |> Test.Repo.insert()

      assert %{during: ["end time must be different from start time"]} = errors_on(changeset)
    end

    test "accepts a DateTimeRange.Time struct" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 during: %DateTimeRange.Time{
                   start_at: ~T[13:00:00],
                   end_at: ~T[14:00:00]
                 }
               })
               |> Test.Repo.insert()

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%DateTimeRange.Time{
        start_at: ~T[13:00:00],
        end_at: ~T[14:00:00]
      })
    end
  end

  describe "contains?" do
    import Ecto.DateTimeRange
    test "with time inside range", do: assert(Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~T[01:59:59]))
    test "with time before range", do: refute(Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~T[00:00:00]))
    test "with time after range", do: refute(Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~T[03:00:00]))
    test "with time at start", do: assert(Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~T[01:00:00]))
    test "with time at end", do: refute(Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~T[02:00:00]))

    test "with time inside cross-day range",
      do: assert(Ecto.DateTimeRange.Time.contains?(~t[23:00:00..02:00:00]T, ~T[01:00:00]))

    test "with time before cross-day range",
      do: refute(Ecto.DateTimeRange.Time.contains?(~t[23:00:00..02:00:00]T, ~T[22:59:59]))

    test "with time after cross-day range",
      do: refute(Ecto.DateTimeRange.Time.contains?(~t[23:00:00..02:00:00]T, ~T[02:01:00]))

    test "with time at start of cross-day range",
      do: assert(Ecto.DateTimeRange.Time.contains?(~t[23:00:00..02:00:00]T, ~T[23:00:00]))

    test "with time at end of cross-day range",
      do: refute(Ecto.DateTimeRange.Time.contains?(~t[23:00:00..02:00:00]T, ~T[02:00:00]))

    test "with midnight inside range",
      do: refute(Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~T[00:00:00]))

    test "with midnight inside cross-day range",
      do: assert(Ecto.DateTimeRange.Time.contains?(~t[23:00:00..02:00:00]T, ~T[00:00:00]))

    test "with naive_date_time inside range",
      do: assert(Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~N[2022-01-01T01:59:59]))

    test "with naive_date_time before range",
      do: refute(Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~N[2022-01-01T00:00:00]))

    test "with naive_date_time after range",
      do: refute(Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~N[2022-01-01T03:00:00]))

    test "with naive_date_time at start",
      do: assert(Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~N[2022-01-01T01:00:00]))

    test "with naive_date_time at end", do: refute(Ecto.DateTimeRange.Time.contains?(~t[01:00:00..02:00:00]T, ~N[2022-01-01T02:00:00]))
  end
end
