defmodule SynapseWeb.PredictionLive do
  use SynapseWeb, :live_view

  alias Synapse.Admin
  alias Synapse.Accounts
  alias Synapse.F1Api

  @color_lookup %{
    "Lewis Hamilton" => "red-600",
    "Charles Leclerc" => "red-600",
    "Max Verstappen" => "blue-600",
    "Yuki Tsunoda" => "blue-600",
    "Lando Norris" => "orange-500",
    "Oscar Piastri" => "orange-500",
    "George Russell" => "teal-400",
    "Kimi Antonelli" => "teal-400",
    "Pierre Gasly" => "sky-600",
    "Jack Doohan" => "sky-600",
    "Fernando Alonso" => "emerald-600",
    "Lance Stroll" => "emerald-600",
    "Nico Hülkenberg" => "green-400",
    "Gabriel Bortoleto" => "green-400",
    "Esteban Ocon" => "gray-400",
    "Oliver Bearman" => "gray-400",
    "Liam Lawson" => "blue-400",
    "Isack Hadjar" => "blue-400",
    "Alex Albon" => "sky-300",
    "Carlos Sainz" => "sky-300"
  }

  def team_colors, do: @color_lookup

  # Helper function to get round from event
  defp get_round_from_event(event) do
    event_lookup =
      event.season.events
      |> Enum.sort(&(DateTime.compare(&1.deadline, &2.deadline) == :lt))
      |> Enum.with_index()
      |> Enum.map(fn {event, index} -> {event.id, index + 1} end)
      |> Map.new()

    round = Map.get(event_lookup, event.id, "1")
    to_string(round)
  end

  @impl true
  def mount(_params, _session, socket) do
    list = [
      %{name: "Lewis Hamilton", position: 0, team_color: "red-600", points: nil},
      %{name: "Charles Leclerc", position: 1, team_color: "red-600", points: nil},
      %{name: "Max Verstappen", position: 2, team_color: "blue-600", points: nil},
      %{name: "Yuki Tsunoda", position: 3, team_color: "blue-600", points: nil},
      %{name: "Lando Norris", position: 4, team_color: "orange-500", points: nil},
      %{name: "Oscar Piastri", position: 5, team_color: "orange-500", points: nil},
      %{name: "George Russell", position: 6, team_color: "teal-400", points: nil},
      %{name: "Kimi Antonelli", position: 7, team_color: "teal-400", points: nil},
      %{name: "Pierre Gasly", position: 8, team_color: "sky-600", points: nil},
      %{name: "Jack Doohan", position: 9, team_color: "sky-600", points: nil},
      %{name: "Fernando Alonso", position: 10, team_color: "emerald-600", points: nil},
      %{name: "Lance Stroll", position: 11, team_color: "emerald-600", points: nil},
      %{name: "Nico Hülkenberg", position: 12, team_color: "green-400", points: nil},
      %{name: "Gabriel Bortoleto", position: 13, team_color: "green-400", points: nil},
      %{name: "Esteban Ocon", position: 14, team_color: "gray-400", points: nil},
      %{name: "Oliver Bearman", position: 15, team_color: "gray-400", points: nil},
      %{name: "Liam Lawson", position: 16, team_color: "blue-400", points: nil},
      %{name: "Isack Hadjar", position: 17, team_color: "blue-400", points: nil},
      %{name: "Alex Albon", position: 18, team_color: "sky-300", points: nil},
      %{name: "Carlos Sainz", position: 19, team_color: "sky-300", points: nil}
    ]

    {:ok, assign(socket, prediction_list: list)}
  end

  # Helper function to check if deadline is in the future
  def deadline_in_future?(deadline) do
    now = DateTime.utc_now()
    DateTime.compare(deadline, now) == :gt
  end

  def get_predictions(default, truths, existing_predictions) do
    has_truths = length(truths) > 0

    case existing_predictions.driver_points do
      [] ->
        {:unsaved, default}

      _ ->
        predictions =
          existing_predictions.driver_points
          |> Enum.map(fn prediction ->
            points = if has_truths, do: prediction.points, else: nil

            %{
              name: prediction.name,
              position: prediction.position - 1,
              team_color: @color_lookup[prediction.name],
              points: points
            }
          end)
          |> Enum.sort(&(&1.position < &2.position))

        {:saved, predictions}
    end
  end

  @impl true
  def handle_info({:load_lap_data, year, round}, socket) do
    case F1Api.get_lap_data(year, round) do
      {:ok, _} = lap_data ->
        gap_data = F1Api.calculate_gaps_to_leader(lap_data)

        # Extract unique drivers from the first lap
        drivers =
          case gap_data do
            {:error, _} ->
              []

            _ ->
              first_lap = Map.values(gap_data) |> List.first()
              if first_lap, do: Enum.map(first_lap, & &1.driver_id), else: []
          end

        send_update(SynapseWeb.LapGapComponent,
          id: "lap-gap",
          gap_data: gap_data,
          drivers: drivers,
          loading: false
        )

      {:error, reason} ->
        send_update(SynapseWeb.LapGapComponent, id: "lap-gap", error: reason, loading: false)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    event =
      case Map.get(params, "id") do
        nil -> Admin.get_latest_event!()
        id -> Admin.get_event!(id)
      end

    truths =
      Admin.get_truths_for_event!(event.id)
      |> Enum.sort(&(&1.position < &2.position))
      |> Enum.map(fn item -> Map.put(item, :team_color, @color_lookup[item.name]) end)

    # Load lap data for the event
    if connected?(socket) and length(truths) > 0 do
      year = event.season.name
      round = get_round_from_event(event)
      send(self(), {:load_lap_data, year, round})
    end

    user =
      case Map.get(params, "username") do
        nil -> socket.assigns.current_user
        username -> Accounts.get_user_by_profile_name!(username)
      end

    predictions =
      Admin.PointsCalculator.calculate_points_single_query(
        user.id,
        event.id
      )

    leaderboard =
      case truths do
        [] ->
          []

        _ ->
          Admin.PointsCalculator.calculate_season_points_by_user(event.season_id)
          |> Enum.map(fn item -> {item.profile_name, Map.get(item.event_points, event.id, 0)} end)
          |> Enum.sort(fn {_name, points}, {_name2, points2} -> points > points2 end)
      end

    title =
      case user.profile.name == socket.assigns.current_user.profile.name do
        false -> "#{user.profile.name}'s Predictions"
        _ -> "Your Predictions"
      end

    {status, prediction_list} =
      get_predictions(socket.assigns.prediction_list, truths, predictions)

    {:noreply,
     socket
     |> assign(
       event: event,
       existing_predictions: predictions,
       prediction_list: prediction_list,
       truths: truths,
       leaderboard: leaderboard,
       user: user,
       viewing: Map.has_key?(params, "username"),
       title: title,
       status: status
     )}
  end

  @impl true
  def handle_event("load_data", %{"year" => year, "round" => round}, socket) do
    send(self(), {:load_lap_data, year, round})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="lists" class="grid gap-2">
      <div class="flex flex-row gap-4 mx-auto max-w-12xl px-4">
        <h2 class="text-2xl font-bold mb-4">{"#{@event.name} #{@event.season.name}"}</h2>
        <div :if={length(@truths) > 0} class="flex justify-end mb-2">
          <div class="text-xl font-bold bg-green-500 text-white px-4 py-2 rounded-full inline-block shadow-md">
            +{@existing_predictions.total_points}
          </div>
        </div>
      </div>

      <div :if={@event.deadline} class="flex justify-center mb-4">
        <div
          :if={deadline_in_future?(@event.deadline)}
          class="bg-yellow-100 border-l-4 border-yellow-500 text-yellow-700 p-4 rounded shadow"
          id="countdown"
          phx-hook="Countdown"
          data-deadline={DateTime.to_iso8601(@event.deadline)}
        >
          <div class="flex items-center">
            <svg
              class="h-6 w-6 mr-2"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <span class="font-semibold">Time remaining:</span>
            <span class="ml-2 countdown-value">Loading...</span>
          </div>
        </div>
        <div
          :if={!deadline_in_future?(@event.deadline) and length(@truths) == 0}
          class="bg-red-100 border-l-4 border-red-500 text-red-700 p-4 rounded shadow"
        >
          <div class="flex items-center">
            <svg
              class="h-6 w-6 mr-2"
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
              />
            </svg>
            <span class="font-semibold">Deadline passed</span>
          </div>
        </div>
      </div>
      <.live_component
        :if={!deadline_in_future?(@event.deadline) or not @viewing}
        id="1"
        module={SynapseWeb.ListComponent}
        list={@prediction_list}
        event={@event}
        user={@user}
        truths={@truths}
        viewing={@viewing}
        title={@title}
        status={@status}
      />
    </div>
    <div :if={length(@leaderboard) > 0} class="mt-8 mb-4">
      <.live_component
        id="2"
        module={SynapseWeb.LeaderboardComponent}
        leaderboard={@leaderboard}
        event={@event}
        title="Event Leaderboard"
      />
    </div>

    <div :if={length(@truths) > 0} class="mt-8">
      <.live_component id="lap-gap" module={SynapseWeb.LapGapComponent} loading={true} />
    </div>
    """
  end
end
