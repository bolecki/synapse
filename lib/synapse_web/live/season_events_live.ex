defmodule SynapseWeb.SeasonEventsLive do
  use SynapseWeb, :live_view

  alias Synapse.Admin

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(season: Admin.get_season!(id))}
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
      <div class="space-y-5 mx-auto max-w-7xl px-4 space-y-4">
        <.header>
          {@season.name}
        </.header>
        <div>
          <div :for={event <- @season.events} class="py-2" data-id={event.id}>
            <div class="flex">
              <.button class="w-48 !bg-blue-600">
                <.link navigate={~p"/f1-prediction/#{event.id}"}>{event.name}</.link>
              </.button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
