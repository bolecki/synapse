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

    # Get all user points data for the season
    user_points_data = Admin.PointsCalculator.calculate_season_points_by_user(season.id)

    # Create leaderboard data
    leaderboard =
      user_points_data
      |> Enum.map(fn item -> {item.profile_name, item.total_points} end)
      |> Enum.sort(fn {_name, points}, {_name2, points2} -> points > points2 end)

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

    # Sort all events by deadline for the chart
    all_events_sorted =
      season.events
      |> Enum.sort_by(& &1.deadline, DateTime)

    # Prepare chart data
    chart_data = prepare_cumulative_points_chart_data(user_points_data, all_events_sorted)

    {:noreply,
     socket
     |> assign(
       season: season,
       leaderboard: leaderboard,
       upcoming_events: upcoming_events,
       past_events: past_events,
       chart_data: chart_data
     )}
  end

  # Prepare data for the cumulative points chart
  defp prepare_cumulative_points_chart_data(user_points_data, events) do
    # Extract event names for labels
    labels = Enum.map(events, & &1.name)

    # Generate a list of colors for the chart
    colors = [
      "#FF6384", "#36A2EB", "#FFCE56", "#4BC0C0", "#9966FF",
      "#FF9F40", "#8AC249", "#EA5F89", "#00D8B6", "#8B75D7"
    ]

    # Create datasets for each user
    datasets =
      user_points_data
      |> Enum.with_index()
      |> Enum.map(fn {user_data, index} ->
        color_index = rem(index, length(colors))
        color = Enum.at(colors, color_index)

        # Calculate cumulative points for each event
        cumulative_points = calculate_cumulative_points(user_data, events)

        %{
          label: user_data.profile_name,
          data: cumulative_points,
          borderColor: color,
          backgroundColor: color <> "33", # Add transparency
          fill: false,
          tension: 0.1
        }
      end)

    # Convert to JSON string for the chart
    Jason.encode!(%{
      labels: labels,
      datasets: datasets
    })
  end

  # Calculate cumulative points for a user across all events
  defp calculate_cumulative_points(user_data, events) do
    event_points = user_data.event_points

    Enum.reduce(events, {[], 0}, fn event, {points_list, running_total} ->
      # Get points for this event (or 0 if no points)
      event_point = Map.get(event_points, event.id, 0)

      # Add to running total
      new_total = running_total + event_point

      # Add the new cumulative total to the list
      {points_list ++ [new_total], new_total}
    end)
    |> elem(0) # Return just the list of cumulative points
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
    <div :if={length(@leaderboard) > 0} class="mt-8 mb-4">
      <.live_component id="2" module={SynapseWeb.LeaderboardComponent} leaderboard={@leaderboard} />
    </div>

    <div :if={length(@leaderboard) > 0} class="mt-8 mb-4">
      <h2 class="text-2xl font-bold mb-4">Cumulative Points Chart</h2>
      <div class="bg-white rounded-lg shadow-md p-4">
        <div class="w-full" style="height: 400px;">
          <canvas id="cumulative-points-chart" phx-hook="CumulativePointsChart" data-chart-data={@chart_data}></canvas>
        </div>
      </div>
    </div>
    """
  end
end
