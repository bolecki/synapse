defmodule SynapseWeb.PredictionLive do
  use Phoenix.LiveView, layout: {SynapseWeb.Layouts, :app}

  alias Phoenix.LiveView.JS

  @f1_drivers [
    "Carlos Sainz",
    "Lewis Hamilton",
    "Max Verstappen",
    "Sergio Pérez",
    "Fernando Alonso",
    "George Russell",
    "Lance Stroll",
    "Kevin Magnussen",
    "Yuki Tsunoda",
    "Esteban Ocon"
  ]

  def mount(_params, _session, socket) do
    IO.inspect(@f1_drivers, label: "F1 Drivers")
    {:ok, assign(socket, f1_drivers: @f1_drivers, rankings: [])}
  end

  def handle_params(params, _uri, socket) do
    rankings = Enum.map(params, fn {_, rank} -> String.to_integer(rank) end)
    IO.inspect(rankings, label: "Rankings")
    {:noreply, assign(socket, rankings: rankings)}
  end

  def handle_event("update_rankings", %{"order" => order}, socket) do
    new_socket =
      socket
      |> update(:rankings, fn _ -> Enum.map(order, &String.to_integer/1) end)
      |> push_event("ranking_updated", %{order: order})

    {:noreply, new_socket}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-3xl font-bold mb-6">F1 Race Prediction</h1>

      <div class="grid grid-cols-2 gap-4">
        <div class="border p-4 rounded-lg shadow">
          <h2 class="font-semibold mb-4">Your Prediction</h2>
          <div id="prediction-area"
               class="space-y-2 cursor-move"
               phx-sortable>
            <%= for driver <- @f1_drivers do %>
              <button
                id={"driver-#{driver}"}
                class="px-4 py-2 bg-blue-500 text-white rounded-full shadow-sm hover:bg-blue-600 transition-colors">
                #{driver}
              </button>
            <% end %>
          </div>
        </div>

        <div class="border p-4 rounded-lg shadow">
          <h2 class="font-semibold mb-4">Available Drivers</h2>
          <div id="available-drivers"
               class="space-y-2 cursor-move"
               phx-sortable-source>
            <%= for driver <- @f1_drivers do %>
              <button
                id={"driver-#{driver}"}
                class="px-4 py-2 bg-gray-500 text-white rounded-full shadow-sm hover:bg-gray-600 transition-colors">
                #{driver}
              </button>
            <% end %>
          </div>
        </div>
      </div>

      <script>
        document.addEventListener("DOMContentLoaded", function() {
          const predictionArea = document.getElementById('prediction-area');
          new Sortable(predictionArea, {
            group: 'shared',
            animation: 150,
            onSort: function(evt) {
              const order = Array.from(predictionArea.children).map(child =>
                parseInt(child.id.split('-')[1])
              );
              sendEvent('update_rankings', {order: order});
            }
          });

          const availableDrivers = document.getElementById('available-drivers');
          new Sortable(availableDrivers, {
            group: 'shared',
            animation: 150,
            onSort: function(evt) {
              const order = Array.from(availableDrivers.children).map(child =>
                parseInt(child.id.split('-')[1])
              );
              sendEvent('update_rankings', {order: order});
            }
          });
        });
      </script>
    </div>
    """
  end
end
