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
      <%= label @f, @field do %>
        <div is="grouped">
          <span><%= @title %></span>
          <%= error_tag @f, @field %>
        </div>
        <%= content_tag(:input, nil,
              type: "text"
              name: "#{form_name(@f)}[#{@field}][start_at]",
              value: utc_date_time_part(@f, @field, :start_at),
              id: "#{form.name}_#{field.name}_start_at") %>

        <%= content_tag(:input, nil,
              type: "text",
              name: "#{form_name(@f)}[#{@field}][end_at]",
              value: utc_date_time_part(@f, @field, :end_at),
              id: "#{form.name}_#{field.name}_end_at") %>

        <%= content_tag(:input, nil,
              type: "hidden",
              name: "#{form_name(@f)}[#{@field}][tz]",
              value: "Etc/UTC") %>
      <% end %>
    </fieldset>
    """
  end

  defp form_name(form), do: form.name

  defp utc_date_time_part(form, field, part) do
    form.source
    |> Ecto.Changeset.get_field(name)
    |> case do
      nil -> DateTime.utc_now()
      %Ecto.UTCDateTimeRange{} = range -> Map.get(range, field)
    end
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
      <.utc_date_time_range_field id="performed-during" f={f} field={:performed_during} title="Performed During" />
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
`Ecto.UTCDateTimeRange.cast/1`:

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
