# Form Data

Types provided by this library are intended to be used with nested form data that can be cast to
ranges as a single unit. For example, a heex component could be written as follows:

```elixir
defmodule Web.Components do
  use Phoenix.HTML

  import Phoenix.LiveView.Helpers

  def utc_date_time_range_field(assigns) do
    ~H"""
    <fieldset>
      <%= error_tag @f, @field %>
      <input
        type="datetime-local"
        name={"#{form_name(@f)}[#{@field}][start_at]"}
        value={utc_date_time_part(@f, @field, :start_at)}
        id={"#{form_name(@f)}_#{@field}_start_at"}
      />
      <input
        type="datetime-local"
        name={"#{form_name(@f)}[#{@field}][end_at]"}
        value={utc_date_time_part(@f, @field, :end_at)}
        id={"#{form_name(@f)}_#{@field}_end_at"}
      />
      <input
        type="hidden"
        name={"#{form_name(@f)}[#{@field}][tz]"}
        value="America/Los_Angeles"
        id={"#{form_name(@f)}_#{@field}_tz"}
      />
    </fieldset>
    """
  end

  def time_range_field(assigns) do
  ~H"""
  <fieldset id={@field}>
    <div is="grouped">
      <%= error_tag @f, @field %>
      <input
        type="time"
        name={"#{form_name(@f)}[#{@field}][start_at]"}
        value={time_part(@f, @field, :start_at)}
        id={"#{form_name(@f)}_#{@field}_start_at"}
      />
      <input
        type="time"
        name={"#{form_name(@f)}[#{@field}][end_at]"}
        value={time_part(@f, @field, :end_at)}
        id={"#{form_name(@f)}_#{@field}_end_at"}
      />
    </div>
  </fieldset>
  """
  end

  defp form_name(form), do: form.name

  defp utc_date_time_part(form, field, part) do
    form.source
    |> Ecto.Changeset.get_field(field)
    |> case do
      nil -> DateTime.utc_now()
      %Ecto.DateTimeRange.UTCDateTime{} = range -> Map.get(range, part) |> to_time_zone("America/Los_Angeles")
    end
  end

  defp time_part(form, field, part) do
    form.source
    |> Ecto.Changeset.get_field(field)
    |> case do
      nil -> default_time(part)
      %Ecto.DateTimeRange.Time{} = range -> Map.get(range, part)
    end
    |> to_time_value()
  end

  defp default_time(:start_at), do: ~T[06:00:00]
  defp default_time(:end_at), do: ~T[18:00:00]

  defp to_time_value(%Time{} = time), do: Calendar.strftime(time, "%H:%M")

  defp to_time_zone(%DateTime{} = time, tz), do: DateTime.add(time, tz_offset(tz), :second)

  defp tz_offset(tz) do
    {:ok, %{std_offset: _, utc_offset: offset, zone_abbr: _}} =
      Calendar.get_time_zone_database().time_zone_periods_from_wall_datetime(DateTime.utc_now(), tz)

    offset
  end
end
```

Components such as this can be used in a parent live view:

```elixir
defmodule Web.MyLiveView do
  use Web, :live_view
  import Web.Components

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.form let={f} for={@changeset} id="thing-form" phx-change="validate">
      <.utc_date_time_range_field id="performed-during" f={f} field={:performed_during} />
      <%= submit("Save") %>
    </.form>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:changeset, Core.Thing.changeset(%{}))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"thing" => params}, socket) do
    socket = socket |> assign(changeset: Core.Things.changeset(params))
    {:noreply, socket}
  end

end
```

When this form is sent to the server via `POST` or in a LiveView's `phx-change` or `phx-submit`, the
params will arrive in the following format, which matches that expected by
`Ecto.DateTimeRange.UTCDateTime.cast/1`:

```elixir
%{
  "thing" => %{
    "performed_during" => %{
        "start_at" => "2022-06-22 01:00:00",
        "end_at" => "2022-06-22 01:00:00",
        "tz" => "Etc/UTC"
      }
  }
}
```
