defmodule SynapseWeb.AdminDashboardLive do
  use SynapseWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8">
      <h1 class="text-3xl font-bold mb-8">Admin Dashboard</h1>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-xl font-semibold mb-4">Season Management</h2>
          <ul class="space-y-2">
            <li>
              <.link navigate={~p"/seasons"} class="text-blue-600 hover:underline">
                Seasons List
              </.link>
            </li>
            <li>
              <.link navigate={~p"/seasons/new"} class="text-blue-600 hover:underline">
                Create New Season
              </.link>
            </li>
          </ul>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-xl font-semibold mb-4">Category Management</h2>
          <ul class="space-y-2">
            <li>
              <.link navigate={~p"/categories"} class="text-blue-600 hover:underline">
                Categories List
              </.link>
            </li>
            <li>
              <.link navigate={~p"/categories/new"} class="text-blue-600 hover:underline">
                Create New Category
              </.link>
            </li>
          </ul>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-xl font-semibold mb-4">Event Management</h2>
          <ul class="space-y-2">
            <li>
              <.link navigate={~p"/events"} class="text-blue-600 hover:underline">
                Events List
              </.link>
            </li>
            <li>
              <.link navigate={~p"/events/new"} class="text-blue-600 hover:underline">
                Create New Event
              </.link>
            </li>
          </ul>
        </div>
      </div>
    </div>
    """
  end
end
