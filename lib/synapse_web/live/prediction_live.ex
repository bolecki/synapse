defmodule SynapseWeb.PredictionLive do
  use SynapseWeb, :live_view

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
      %{name: "Carlos Sainz", id: 19, position: 19, team_color: "sky-300"},
    ]

    {:ok, assign(socket, prediction_list: list)}
  end

  def render(assigns) do
    ~H"""
    <div id="lists" class="grid sm:grid-cols-1 md:grid-cols-3 gap-2">
      <.live_component
        id="1"
        module={SynapseWeb.ListComponent}
        list={@prediction_list}
        list_name="Prediction list"
      />
    </div>
    """
  end
end
