defmodule SynapseWeb.LapGapLive do
  use SynapseWeb, :live_view
  alias Synapse.F1Api

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      year: "2025",
      round: "1",
      loading: false,
      gap_data: nil,
      error: nil,
      drivers: [],
      gap_type: "total_gap" # Default to showing total gap (can be "lap_gap" or "total_gap")
    )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    year = Map.get(params, "year", "2025")
    round = Map.get(params, "round", "1")

    socket = assign(socket, year: year, round: round)

    if connected?(socket) do
      send(self(), {:load_data, year, round})
    end

    {:noreply, assign(socket, loading: true)}
  end

  @impl true
  def handle_event("load_data", %{"year" => year, "round" => round}, socket) do
    send(self(), {:load_data, year, round})
    {:noreply, assign(socket, loading: true, year: year, round: round)}
  end

  @impl true
  def handle_event("toggle_gap_type", _, socket) do
    # Toggle between lap_gap and total_gap
    new_gap_type = if socket.assigns.gap_type == "lap_gap", do: "total_gap", else: "lap_gap"
    {:noreply, assign(socket, gap_type: new_gap_type)}
  end

  @impl true
  def handle_info({:load_data, year, round}, socket) do
    case F1Api.get_lap_data(year, round) do
      {:ok, _} = lap_data ->
        gap_data = F1Api.calculate_gaps_to_leader(lap_data)

        # Extract unique drivers from the first lap
        drivers =
          case gap_data do
            {:error, _} -> []
            _ ->
              first_lap = Map.values(gap_data) |> List.first()
              if first_lap, do: Enum.map(first_lap, & &1.driver_id), else: []
          end

        {:noreply, assign(socket, loading: false, gap_data: gap_data, drivers: drivers, error: nil)}

      {:error, reason} ->
        {:noreply, assign(socket, loading: false, error: reason)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-2xl font-bold mb-4">F1 Gap to Leader Visualization</h1>

      <div class="mb-6">
        <form phx-submit="load_data" class="flex gap-4 items-end">
          <div>
            <label for="year" class="block text-sm font-medium text-gray-700">Year</label>
            <input type="text" id="year" name="year" value={@year} class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" />
          </div>
          <div>
            <label for="round" class="block text-sm font-medium text-gray-700">Round</label>
            <input type="text" id="round" name="round" value={@round} class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500" />
          </div>
          <div>
            <button type="submit" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
              Load Data
            </button>
          </div>
        </form>
      </div>

      <%= if @loading do %>
        <div class="flex justify-center items-center h-64">
          <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
        </div>
      <% else %>
        <%= if @error do %>
          <div class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative" role="alert">
            <strong class="font-bold">Error:</strong>
            <span class="block sm:inline"><%= @error %></span>
          </div>
        <% else %>
          <%= if @gap_data do %>
            <div class="mb-4">
              <button phx-click="toggle_gap_type" class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
                <%= if @gap_type == "lap_gap" do %>
                  Show Total Gap
                <% else %>
                  Show Lap Gap
                <% end %>
              </button>
              <span class="ml-2 text-sm text-gray-600">
                <%= if @gap_type == "lap_gap" do %>
                  Currently showing: Gap per lap
                <% else %>
                  Currently showing: Cumulative gap to leader
                <% end %>
              </span>
            </div>
            <div id="gap-chart" class="h-[600px] w-full" phx-update="ignore" phx-hook="GapChart" data-gaps={Jason.encode!(@gap_data)} data-drivers={Jason.encode!(@drivers)} data-gap-type={@gap_type}></div>
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end
end
