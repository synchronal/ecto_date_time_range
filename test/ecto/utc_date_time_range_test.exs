defmodule Ecto.UTCDateTimeRangeTest do
  # @related [subject](/lib/ecto/utc_date_time_range.ex)
  @moduledoc false
  use Test.DataCase, async: true
  use EctoTemp, repo: Test.Repo

  alias Ecto.UTCDateTimeRange

  deftemptable :things_with_time_ranges do
    column(:during, :tstzrange)
  end

  setup do
    create_temp_tables()

    :ok
  end

  defmodule Thing do
    @moduledoc false
    use Ecto.Schema

    schema "things_with_time_ranges_temp" do
      field(:during, UTCDateTimeRange)
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
                   "start_at" => "2020-02-01T00:01:01Z",
                   "end_at" => "2020-02-02T00:02:01Z"
                 }
               })
               |> Test.Repo.insert()

      assert thing.during == %UTCDateTimeRange{
               start_at: ~U[2020-02-01 00:01:01Z],
               end_at: ~U[2020-02-02 00:02:01Z]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%UTCDateTimeRange{
        start_at: ~U[2020-02-01 00:01:01Z],
        end_at: ~U[2020-02-02 00:02:01Z]
      })
    end

    test "assumes UTC if the range does not include the time zone" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{"start_at" => "2020-02-01 00:01", "end_at" => "2020-02-02 00:02"}
               })
               |> Test.Repo.insert()

      assert thing.during == %UTCDateTimeRange{
               start_at: ~U[2020-02-01 00:01:00Z],
               end_at: ~U[2020-02-02 00:02:00Z]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%UTCDateTimeRange{
        start_at: ~U[2020-02-01 00:01:00Z],
        end_at: ~U[2020-02-02 00:02:00Z]
      })
    end

    test "casts to UTC if the range specifies a different time zone" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => "2020-02-02 13:00",
                   "end_at" => "2020-02-02 15:00",
                   "tz" => "America/Los_Angeles"
                 }
               })
               |> Test.Repo.insert()

      assert thing.during == %UTCDateTimeRange{
               start_at: ~U[2020-02-02 21:00:00Z],
               end_at: ~U[2020-02-02 23:00:00Z]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%UTCDateTimeRange{
        start_at: ~U[2020-02-02 21:00:00Z],
        end_at: ~U[2020-02-02 23:00:00Z]
      })
    end

    test "is ok if the value is a time range of DateTimes" do
      assert {:ok, thing} =
               Thing.changeset(%{
                 "during" => %{
                   "start_at" => ~U[2020-02-01T00:01:01Z],
                   "end_at" => ~U[2020-02-02T00:02:01Z]
                 }
               })
               |> Test.Repo.insert()

      assert thing.during == %UTCDateTimeRange{
               start_at: ~U[2020-02-01 00:01:01Z],
               end_at: ~U[2020-02-02 00:02:01Z]
             }

      Test.Repo.get(Thing, thing.id)
      |> Map.get(:during)
      |> assert_eq(%UTCDateTimeRange{
        start_at: ~U[2020-02-01 00:01:01Z],
        end_at: ~U[2020-02-02 00:02:01Z]
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
  end

  describe "sigil_t" do
    import Ecto.UTCDateTimeRange, only: [sigil_t: 2]

    test "creates a date time range" do
      ~t{2020-02-02T00:01:00Z - 2020-02-02T00:01:01Z}
      |> assert_eq(%UTCDateTimeRange{
        start_at: ~U[2020-02-02 00:01:00Z],
        end_at: ~U[2020-02-02 00:01:01Z]
      })
    end

    test "creates a date time range from start and end" do
      ~t{2020-02-02T00:01:00Z - 2020-02-02T00:01:01Z}r
      |> assert_eq(%UTCDateTimeRange{
        start_at: ~U[2020-02-02 00:01:00Z],
        end_at: ~U[2020-02-02 00:01:01Z]
      })
    end
  end
end
