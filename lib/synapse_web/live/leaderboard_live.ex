defmodule SynapseWeb.LeaderboardLive do
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
       chart_data: chart_data
     )}
  end

  # Prepare data for the cumulative points chart
  defp prepare_cumulative_points_chart_data(user_points_data, events) do
    # Extract event names for labels
    labels = Enum.map(events, &(String.replace(&1.name, " Grand Prix", "")))

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

    <div :if={length(@leaderboard) > 0} class="mt-8 mb-4">
      <.live_component id="leaderboard" module={SynapseWeb.LeaderboardComponent} leaderboard={@leaderboard} title={"#{@season.name} Leaderboard"} />
    </div>

    <div :if={length(@leaderboard) > 0} class="mt-8 mb-4">
      <div class="bg-white rounded-lg shadow-md p-4">
        <div class="w-full" style="height: 400px;">
          <canvas id="cumulative-points-chart" phx-hook="CumulativePointsChart" data-chart-data={@chart_data}></canvas>
        </div>
      </div>
    </div>
    """
  end
end
