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

    leaderboard =
      Admin.PointsCalculator.calculate_season_points_by_user(season.id)
      |> Enum.map(fn item -> {item.profile_name, item.total_points} end)
      |> Enum.sort(fn {name, points}, {name2, points2} -> points > points2 end)

    {:noreply,
     socket
     |> assign(season: season, leaderboard: leaderboard)}
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
        <div>
          <div :for={event <- @season.events} class="pb-2" data-id={event.id}>
            <div class="flex">
              <.link navigate={~p"/f1-prediction/#{event.id}"}>
                <.button class="w-48 !bg-violet-500">
                  {event.name}
                </.button>
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div :if={length(@leaderboard) > 0} class="mt-8 mb-4">
      <.live_component id="2" module={SynapseWeb.LeaderboardComponent} leaderboard={@leaderboard} />
    </div>
    """
  end
end
