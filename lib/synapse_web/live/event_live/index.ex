defmodule SynapseWeb.EventLive.Index do
  use SynapseWeb, :live_view

  alias Synapse.Admin
  alias Synapse.Admin.Event
  alias Synapse.F1Api

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :events, Admin.list_events())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Event")
    |> assign(:event, Admin.get_event!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Event")
    |> assign(:event, %Event{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Events")
    |> assign(:event, nil)
  end

  @impl true
  def handle_info({SynapseWeb.EventLive.FormComponent, {:saved, event}}, socket) do
    {:noreply, stream_insert(socket, :events, event)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    event = Admin.get_event!(id)
    {:ok, _} = Admin.delete_event(event)

    {:noreply, stream_delete(socket, :events, event)}
  end

  @impl true
  def handle_event("clear", %{"id" => id}, socket) do
    :ok = Admin.delete_truths_for_event(id)

    {:noreply, socket}
  end

  @impl true
  def handle_event("populate", %{}, socket) do
    events = F1Api.save_season_events_current_year()

    # {:noreply, stream(socket, :events, events)}
    {:noreply, socket}
  end

  @impl true
  def handle_event("update", %{"id" => id}, socket) do
    event = Admin.get_event!(id)

    event_lookup =
      event.season.events
      |> Enum.sort(&(&1.id < &2.id))
      |> Enum.with_index()
      |> Enum.map(fn {event, index} -> {event.id, index + 1} end)
      |> Map.new()

    round = Map.get(event_lookup, event.id)

    # Update the deadline
    {:ok, deadline} = F1Api.get_and_save_first_practice_time(event, event.season.name, round)

    # Only save the event if the deadline is in the past
    if deadline && DateTime.compare(deadline, DateTime.utc_now()) == :lt do
      F1Api.save_event(event.id, event.season.name, round)
    end

    {:noreply, socket}
  end
end
