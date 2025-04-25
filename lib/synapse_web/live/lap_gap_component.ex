defmodule SynapseWeb.LapGapComponent do
  use SynapseWeb, :live_component

  @impl true
  def update(assigns, socket) do
    # Default values in case event is not available yet
    default_year = "2025"
    default_round = "1"

    # Check if event is available in assigns
    {year, round} = if Map.has_key?(assigns, :event) do
      {
        assigns.event.season.name,
        get_round_from_event(assigns.event)
      }
    else
      {default_year, default_round}
    end

    socket = assign(socket,
      id: assigns.id,
      year: year,
      round: round,
      loading: false,
      gap_data: nil,
      error: nil,
      drivers: [],
      gap_type: "total_gap" # Default to showing total gap (can be "lap_gap" or "total_gap")
    )

    if connected?(socket) and Map.has_key?(assigns, :event) do
      send(self(), {:load_lap_data, socket.assigns.year, socket.assigns.round, assigns.id})
    end

    {:ok, assign(socket, loading: true)}
  end

  @impl true
  def handle_event("load_data", %{"year" => year, "round" => round}, socket) do
    send(self(), {:load_lap_data, year, round, socket.assigns.id})
    {:noreply, assign(socket, loading: true, year: year, round: round)}
  end

  @impl true
  def handle_event("toggle_gap_type", _, socket) do
    # Toggle between lap_gap and total_gap
    new_gap_type = if socket.assigns.gap_type == "lap_gap", do: "total_gap", else: "lap_gap"
    {:noreply, assign(socket, gap_type: new_gap_type)}
  end

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
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4 mt-8">
      <h2 class="text-2xl font-bold mb-4">F1 Gap to Leader Visualization</h2>

      <div class="mb-6">
        <form phx-submit="load_data" phx-target={@myself} class="flex gap-4 items-end">
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
              <button phx-click="toggle_gap_type" phx-target={@myself} class="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
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
            <div id={"gap-chart-#{@id}"} class="h-[600px] w-full" phx-update="ignore" phx-hook="GapChart" data-gaps={Jason.encode!(@gap_data)} data-drivers={Jason.encode!(@drivers)} data-gap-type={@gap_type}></div>
          <% end %>
        <% end %>
      <% end %>
    </div>
    """
  end
end
