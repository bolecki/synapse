defmodule SynapseWeb.ListComponent do
  use SynapseWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 py-4 rounded-lg">
      <div style="display:none;" class="bg-red-600 bg-blue-600 bg-orange-500 bg-teal-400 bg-sky-600 bg-emerald-600 bg-green-400 bg-gray-400 bg-blue-400 bg-sky-300"></div>
      <div class="space-y-5 mx-auto max-w-7xl px-4 space-y-4">
        <.header>
          <%= @list_name %>
        </.header>
        <div id={"#{@id}-items"} phx-hook="Sortable" data-list_id={@id}>
          <div
            :for={item <- @list}
            id={"#{@id}-#{item.id}"}
            class="..."
            data-id={item.id}
          >
            <div class="flex">
              <button type="button" class="w-10">
                <.icon
                  name="hero-arrows-up-down"
                  class={[
                    "w-7 h-7",
                    "bg-#{item.team_color}"
                    ]}
                />
              </button>
              <div class="flex-auto block text-sm leading-6 text-zinc-900">
                <%= item.name %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def handle_event("reposition", params, socket) do
    #Put your logic here to deal with the changes to the list order
    #and persist the data
    IO.inspect(params)
    {:noreply, socket}
  end
end
