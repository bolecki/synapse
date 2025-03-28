defmodule SynapseWeb.SeasonEventsLive do
  use SynapseWeb, :live_view

  alias Synapse.Admin

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    season =
      case Map.get(params, "id") do
        nil -> Admin.get_latest_season!()
        id -> Admin.get_season!(id)
      end

    now = DateTime.utc_now()

    # Split events into upcoming and past based on deadline
    {upcoming_events, past_events} =
      season.events
      |> Enum.split_with(fn event ->
        DateTime.compare(event.deadline, now) == :gt
      end)

    # Sort upcoming events by nearest deadline first
    upcoming_events =
      upcoming_events
      |> Enum.sort_by(& &1.deadline, DateTime)

    # Sort past events by nearest deadline first (most recent past events)
    past_events =
      past_events
      |> Enum.sort_by(& &1.deadline, {:desc, DateTime})

    {:noreply,
     socket
     |> assign(
       season: season,
       upcoming_events: upcoming_events,
       past_events: past_events
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 py-4 rounded-lg">
      <div
        style="display:none;"
        class="bg-red-600 bg-blue-600 bg-orange-500 bg-teal-400 bg-sky-600 bg-emerald-600 bg-green-400 bg-gray-400 bg-blue-400 bg-sky-300"
      >
      </div>
      <div class="mx-auto max-w-7xl px-4 space-y-2">
        <.header>
          {@season.name}
        </.header>
        <div class="grid grid-cols-2 gap-8">
          <div>
            <h3 class="text-lg font-semibold mb-4">Upcoming Predictions</h3>
            <div :for={event <- @upcoming_events} class="pb-2" data-id={event.id}>
              <div class="flex">
                <.link navigate={~p"/f1-prediction/#{event.id}"}>
                  <.button class="w-48 !bg-violet-500">
                    {event.name}
                  </.button>
                </.link>
              </div>
            </div>
            <div :if={length(@upcoming_events) == 0} class="text-gray-500 italic">
              No upcoming races
            </div>
          </div>

          <div>
            <h3 class="text-lg font-semibold mb-4">Past Predictions</h3>
            <div :for={event <- @past_events} class="pb-2" data-id={event.id}>
              <div class="flex">
                <.link navigate={~p"/f1-prediction/#{event.id}"}>
                  <.button class="w-48 !bg-blue-400">
                    {event.name}
                  </.button>
                </.link>
              </div>
            </div>
            <div :if={length(@past_events) == 0} class="text-gray-500 italic">
              No past races
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
