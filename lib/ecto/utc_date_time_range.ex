defmodule Ecto.UTCDateTimeRange do
  # @related [test](/test/ecto/utc_date_time_range_test.exs)

  @moduledoc """
  An `Ecto.Type` wrapping a `:tstzrange` Postgres column. To the application, it appears as
  a struct with `:start_at` and `:end_at`, with `:utc_datetime` values.

  ```
  defmodule Core.Thing do
    use Ecto.Schema

    schema "things" do
      field :performed_during, Ecto.UTCDateTimeRange
    end
  end
  ```
  """

  @behaviour Access
  @behaviour Ecto.Type

  defstruct ~w{start_at end_at}a

  @type t() :: %__MODULE__{
          start_at: DateTime.t(),
          end_at: DateTime.t()
        }

  @doc """
  Create an `Ecto.UTCDateTimeRange` from two ISO8601 strings.

  ## Example

  ```
  iex> import Ecto.UTCDateTimeRange, only: [sigil_t: 2]
  iex> ~t(2020-02-02T00:01:00Z - 2020-02-02T00:01:01Z)
  %Ecto.UTCDateTimeRange{start_at: ~U[2020-02-02T00:01:00Z], end_at: ~U[2020-02-02T00:01:01Z]}
  ...>
  iex> ~t(hi there)
  ** (ArgumentError) Unable to parse DateTime(s) from input
  ```
  """
  @spec sigil_t(binary(), list()) :: t() | no_return()
  def sigil_t(string, []) when is_binary(string) do
    case parse(string) do
      {:ok, range} -> range
      {:error, error} -> raise ArgumentError, error
    end
  end

  def sigil_t(string, [?r]) when is_binary(string) do
    case parse(string) do
      {:ok, range} -> range
      {:error, error} -> raise ArgumentError, error
    end
  end

  @doc """
  Create an `Ecto.UTCDateTimeRange` from two ISO8601 strings.

  ## Example

  ```
  iex> Ecto.UTCDateTimeRange.parse("2020-02-02T00:01:00Z - 2020-02-02T00:01:01Z")
  {:ok, %Ecto.UTCDateTimeRange{start_at: ~U[2020-02-02T00:01:00Z], end_at: ~U[2020-02-02T00:01:01Z]}}

  iex> Ecto.UTCDateTimeRange.parse("2020-02-02T00:01:00Z - later")
  {:error, "Unable to parse DateTime(s) from input"}
  ```
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, term()}
  def parse(string) when is_binary(string), do: string |> String.split(~r{ \- }) |> do_parse()

  defp do_parse([%DateTime{} = lower, %DateTime{} = upper]),
    do: {:ok, %__MODULE__{start_at: lower, end_at: upper}}

  defp do_parse([{:ok, lower, _}, {:ok, upper, _}]), do: [lower, upper] |> do_parse()

  defp do_parse([lower, upper] = times) when is_binary(lower) and is_binary(upper),
    do: times |> Enum.map(&DateTime.from_iso8601/1) |> do_parse()

  defp do_parse(_), do: {:error, "Unable to parse DateTime(s) from input"}

  @impl Ecto.Type
  def type, do: :tstzrange

  @impl Ecto.Type
  def cast(%{start_at: lower, end_at: upper, tz: tz}) do
    case apply_func({lower, upper}, &Ecto.Type.cast(:naive_datetime, &1)) do
      {:ok, {lower, upper}} ->
        if NaiveDateTime.compare(lower, upper) == :lt,
          do: {:ok, %__MODULE__{start_at: utc(lower, tz), end_at: utc(upper, tz)}},
          else: {:error, message: "end time must be later than start time"}

      :error ->
        {:error, message: "unable to read start and/or end times"}
    end
  end

  def cast(%{start_at: lower, end_at: upper}),
    do: cast(%{start_at: lower, end_at: upper, tz: "Etc/UTC"})

  def cast(%{"start_at" => "", "end_at" => ""}), do: {:ok, nil}

  def cast(%{"start_at" => lower, "end_at" => upper, "tz" => tz}),
    do: cast(%{start_at: lower, end_at: upper, tz: tz})

  def cast(%{"start_at" => lower, "end_at" => upper}), do: cast(%{start_at: lower, end_at: upper})
  def cast(_), do: {:error, message: "unable to read start and/or end times"}

  @impl Ecto.Type
  def load(%Postgrex.Range{lower: lower, upper: upper}) do
    apply_func({lower, upper}, &Ecto.Type.load(:utc_datetime, &1))
    |> case do
      {:ok, {lower, upper}} ->
        {:ok, %__MODULE__{start_at: lower, end_at: upper}}

      :error ->
        :error
    end
  end

  def load(_), do: :error

  @impl Ecto.Type
  def dump(%__MODULE__{start_at: %DateTime{} = lower, end_at: %DateTime{} = upper}) do
    {:ok, %Postgrex.Range{lower: lower, upper: upper, upper_inclusive: false}}
  end

  def dump({%NaiveDateTime{} = lower, upper}) do
    dump({DateTime.from_naive!(lower, "Etc/UTC"), upper})
  end

  def dump({lower, %NaiveDateTime{} = upper}) do
    dump({lower, DateTime.from_naive!(upper, "Etc/UTC")})
  end

  def dump(_), do: :error

  @impl Ecto.Type
  def equal?(%__MODULE__{start_at: lower1, end_at: upper1}, %__MODULE__{
        start_at: lower2,
        end_at: upper2
      }),
      do: DateTime.compare(lower1, lower2) == :eq && DateTime.compare(upper1, upper2) == :eq

  def equal?(first, second), do: first == second

  @impl Ecto.Type
  def embed_as(_), do: :dump

  @impl Access
  def fetch(map, key), do: :maps.find(key, map)

  @impl Access
  def get_and_update(map, key, fun), do: Map.get_and_update(map, key, fun)

  @impl Access
  def pop(data, key), do: {Map.get(data, key), data}

  defp apply_func({lower, upper}, fun) do
    lower = do_apply_func(lower, fun)
    upper = do_apply_func(upper, fun)

    if lower != :error and upper != :error do
      {:ok, {lower, upper}}
    else
      :error
    end
  end

  defp do_apply_func(target, fun) do
    case fun.(target) do
      {:ok, target} -> target
      :error -> :error
    end
  end

  defp utc(%NaiveDateTime{} = time, tz),
    do: DateTime.from_naive!(time, tz) |> DateTime.shift_zone!("Etc/UTC")
end
