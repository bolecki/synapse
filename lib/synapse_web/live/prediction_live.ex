defmodule SynapseWeb.PredictionLive do
  use SynapseWeb, :live_view

  alias Synapse.Admin

  @color_lookup %{
    "Lewis Hamilton" => "red-600",
    "Charles Leclerc" => "red-600",
    "Max Verstappen" => "blue-600",
    "Liam Lawson" => "blue-600",
    "Lando Norris" => "orange-500",
    "Oscar Piastri" => "orange-500",
    "George Russell" => "teal-400",
    "Kimi Antonelli" => "teal-400",
    "Pierre Gasly" => "sky-600",
    "Jack Doohan" => "sky-600",
    "Fernando Alonso" => "emerald-600",
    "Lance Stroll" => "emerald-600",
    "Nico Hulkenberg" => "green-400",
    "Gabriel Bortoleto" => "green-400",
    "Esteban Ocon" => "gray-400",
    "Oliver Bearman" => "gray-400",
    "Yuki Tsunoda" => "blue-400",
    "Isack Hadjar" => "blue-400",
    "Alex Albon" => "sky-300",
    "Carlos Sainz" => "sky-300"
  }

  @impl true
  def mount(_params, _session, socket) do
    list = [
      %{name: "Lewis Hamilton", id: 0, position: 0, team_color: "red-600"},
      %{name: "Charles Leclerc", id: 1, position: 1, team_color: "red-600"},
      %{name: "Max Verstappen", id: 2, position: 2, team_color: "blue-600"},
      %{name: "Liam Lawson", id: 3, position: 3, team_color: "blue-600"},
      %{name: "Lando Norris", id: 4, position: 4, team_color: "orange-500"},
      %{name: "Oscar Piastri", id: 5, position: 5, team_color: "orange-500"},
      %{name: "George Russell", id: 6, position: 6, team_color: "teal-400"},
      %{name: "Kimi Antonelli", id: 7, position: 7, team_color: "teal-400"},
      %{name: "Pierre Gasly", id: 8, position: 8, team_color: "sky-600"},
      %{name: "Jack Doohan", id: 9, position: 9, team_color: "sky-600"},
      %{name: "Fernando Alonso", id: 10, position: 10, team_color: "emerald-600"},
      %{name: "Lance Stroll", id: 11, position: 11, team_color: "emerald-600"},
      %{name: "Nico Hulkenberg", id: 12, position: 12, team_color: "green-400"},
      %{name: "Gabriel Bortoleto", id: 13, position: 13, team_color: "green-400"},
      %{name: "Esteban Ocon", id: 14, position: 14, team_color: "gray-400"},
      %{name: "Oliver Bearman", id: 15, position: 15, team_color: "gray-400"},
      %{name: "Yuki Tsunoda", id: 16, position: 16, team_color: "blue-400"},
      %{name: "Isack Hadjar", id: 17, position: 17, team_color: "blue-400"},
      %{name: "Alex Albon", id: 18, position: 18, team_color: "sky-300"},
      %{name: "Carlos Sainz", id: 19, position: 19, team_color: "sky-300"}
    ]

    {:ok, assign(socket, prediction_list: list)}
  end

  def get_predictions(user, event, default) do
    existing_predictions = Admin.get_ranked_predictions_for_user_event!(user.id, event.id)

    case existing_predictions do
      [] ->
        default

      _ ->
        existing_predictions
        |> Enum.map(fn prediction ->
          %{
            name: prediction.name,
            id: prediction.position - 1,
            position: prediction.position - 1,
            team_color: @color_lookup[prediction.name]
          }
        end)
        |> Enum.sort(&(&1.position < &2.position))
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    event = Admin.get_event!(id)

    {:noreply,
     socket
     |> assign(
       event: event,
       prediction_list:
         get_predictions(socket.assigns.current_user, event, socket.assigns.prediction_list)
     )}
  end

  @impl true
  def handle_params(_params, _, socket) do
    event = Admin.get_latest_event!()

    {:noreply,
     socket
     |> assign(
       event: event,
       prediction_list:
         get_predictions(socket.assigns.current_user, event, socket.assigns.prediction_list)
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="lists" class="grid sm:grid-cols-1 md:grid-cols-2 gap-2">
      <.live_component
        id="1"
        module={SynapseWeb.ListComponent}
        list={@prediction_list}
        list_name={"#{@event.name} #{@event.season.name}"}
        event={@event}
        user={@current_user}
      />
    </div>
    """
  end
end
