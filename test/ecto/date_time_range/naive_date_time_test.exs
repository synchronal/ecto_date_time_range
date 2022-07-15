defmodule Ecto.DateTimeRange.NaiveDateTimeTest do
  # @related [subject](/lib/ecto/date_time_range/naive_date_time.ex)
  @moduledoc false
  use Test.DataCase, async: true
  alias Ecto.DateTimeRange

  doctest Ecto.DateTimeRange.NaiveDateTime

  deftemptable :things_with_naive_date_time_ranges do
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

    schema "things_with_naive_date_time_ranges_temp" do
      field(:during, DateTimeRange.NaiveDateTime)
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
                   "start_at" => "2020-02-01T00:01:01",
                   "end_at" => "2020-02-02T00:02:01"
                 }
               })
               |> Test.Repo.insert()

      assert thing.during == %DateTimeRange.NaiveDateTime{
               start_at: ~N[2020-02-01 00:01:01Z],
               end_at: ~N[2020-02-02 00:02:01Z]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%DateTimeRange.NaiveDateTime{
        start_at: ~N[2020-02-01 00:01:01Z],
        end_at: ~N[2020-02-02 00:02:01Z]
      })
    end

    test "is ok if the value is a time range of DateTimes" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => ~N[2020-02-01T00:01:01],
                   "end_at" => ~N[2020-02-02T00:02:01]
                 }
               })
               |> Test.Repo.insert()

      assert thing.during == %DateTimeRange.NaiveDateTime{
               start_at: ~N[2020-02-01 00:01:01],
               end_at: ~N[2020-02-02 00:02:01]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%DateTimeRange.NaiveDateTime{
        start_at: ~N[2020-02-01 00:01:01],
        end_at: ~N[2020-02-02 00:02:01]
      })
    end

    test "is an error if the value is not a start and end time" do
      assert {:error, changeset} = Thing.changeset(%{"during" => "five"}) |> Test.Repo.insert()
      assert %{during: ["unable to read start and/or end times"]} = errors_on(changeset)
    end

    test "is an error if the end is earlier than the start" do
      assert {:error, changeset} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => ~U[2020-02-02T00:01:01Z],
                   "end_at" => ~U[2020-02-01T00:01:01Z]
                 }
               })
               |> Test.Repo.insert()

      assert %{during: ["end time must be later than start time"]} = errors_on(changeset)
    end

    test "accepts a DateTimeRange.NaiveDateTime struct" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 during: %DateTimeRange.NaiveDateTime{
                   start_at: ~N[2020-02-02 13:00:00],
                   end_at: ~N[2020-02-02 14:00:00]
                 }
               })
               |> Test.Repo.insert()

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%DateTimeRange.NaiveDateTime{
        start_at: ~N[2020-02-02 13:00:00],
        end_at: ~N[2020-02-02 14:00:00]
      })
    end
  end

  describe "contains?" do
    import Ecto.DateTimeRange

    test "with time inside range",
      do: assert(Ecto.DateTimeRange.NaiveDateTime.contains?(~t[2022-01-01T01:00:00..2022-01-01T02:00:00]N, ~N[2022-01-01T01:59:59]))

    test "with time before range",
      do: refute(Ecto.DateTimeRange.NaiveDateTime.contains?(~t[2022-01-01T01:00:00..2022-01-01T02:00:00]N, ~N[2022-01-01T00:00:00]))

    test "with time after range",
      do: refute(Ecto.DateTimeRange.NaiveDateTime.contains?(~t[2022-01-01T01:00:00..2022-01-01T02:00:00]N, ~N[2022-01-01T03:00:00]))

    test "with time at start",
      do: assert(Ecto.DateTimeRange.NaiveDateTime.contains?(~t[2022-01-01T01:00:00..2022-01-01T02:00:00]N, ~N[2022-01-01T01:00:00]))

    test "with time at end",
      do: refute(Ecto.DateTimeRange.NaiveDateTime.contains?(~t[2022-01-01T01:00:00..2022-01-01T02:00:00]N, ~N[2022-01-01T02:00:00]))
  end
end
