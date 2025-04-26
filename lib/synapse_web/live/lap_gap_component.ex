defmodule SynapseWeb.LapGapComponent do
  use SynapseWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket = assign(socket,
      id: assigns.id,
      loading: Map.get(assigns, :loading, false),
      gap_data: Map.get(assigns, :gap_data, nil),
      error: Map.get(assigns, :error, nil),
      drivers: Map.get(assigns, :drivers, []),
      gap_type: Map.get(assigns, :gap_type, "total_gap") # Default to showing total gap (can be "lap_gap" or "total_gap")
    )

    {:ok, socket}
  end

  @impl true
  def handle_event("toggle_gap_type", _, socket) do
    # Toggle between lap_gap and total_gap
    new_gap_type = if socket.assigns.gap_type == "lap_gap", do: "total_gap", else: "lap_gap"
    {:noreply, assign(socket, gap_type: new_gap_type)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4 mt-8">
      <h2 class="text-2xl font-bold mb-4">F1 Gap to Leader Visualization</h2>

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
