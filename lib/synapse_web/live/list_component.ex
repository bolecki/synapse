defmodule SynapseWeb.ListComponent do
  use SynapseWeb, :live_component

  alias Synapse.Admin.RankedPrediction
  alias Synapse.Repo
  alias Ecto.Multi

  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 py-4 rounded-lg">
      <div
        style="display:none;"
        class="bg-red-600 bg-blue-600 bg-orange-500 bg-teal-400 bg-sky-600 bg-emerald-600 bg-green-400 bg-gray-400 bg-blue-400 bg-sky-300"
      >
      </div>
      <div class="space-y-5 mx-auto max-w-7xl px-4 space-y-4">
        <.header>
          {@list_name}
        </.header>
        <div id={"#{@id}-items"} phx-hook="Sortable" data-list_id={@id}>
          <div :for={item <- @list} id={"#{@id}-#{item.id}"} class="..." data-id={item.id}>
            <div class="flex">
              <button type="button" class="w-14 flex items-center">
                <span class="w-5 text-right mr-1 font-semibold">{item.position + 1}</span>
                <.icon
                  name="hero-arrows-up-down"
                  class={[
                    "w-7 h-7 flex-shrink-0",
                    "bg-#{item.team_color}"
                  ]}
                />
              </button>
              <div class={[
                "flex-auto block text-sm leading-6",
                cond do
                  item.position <= 10 and Map.get(item, :truth, false) -> "text-zinc-900 bg-green-100 border-l-4 border-green-500 pl-2"
                  item.position > 10 -> "text-zinc-400 italic bg-gray-50 border-l-4 border-gray-300 pl-2"
                  true -> "text-zinc-900"
                end
              ]}>
                <div class="flex justify-between w-full">
                  <div>
                    {item.name}
                    {if item.position > 10 do
                      Phoenix.HTML.raw(
                        "<span class=\"ml-2 text-xs bg-gray-200 text-gray-600 px-1.5 py-0.5 rounded-full\">Not considered</span>"
                      )
                    end}
                  </div>
                  {if item.position <= 10 do
                    points = 11 - item.position
                    Phoenix.HTML.raw(
                      "<span class=\"text-xs font-semibold bg-blue-100 text-blue-800 px-2 py-0.5 rounded-full\">+#{points}</span>"
                    )
                  end}
                </div>
              </div>
            </div>
          </div>
        </div>
        <.simple_form for={%{}} phx-submit="save" phx-target={@myself} class="bg-transparent">
          <:actions>
            <div class="w-full">
              <.button type="submit" class="w-full !bg-blue-600">Save</.button>
            </div>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  def move_item(list, from_index, to_index) do
    item = Enum.at(list, from_index)

    list
    |> List.delete_at(from_index)
    |> List.insert_at(to_index, item)
    |> Enum.with_index()
    |> Enum.map(fn {item, index} ->
      Map.put(item, :position, index)
    end)
  end

  def handle_event("reposition", params, socket) do
    IO.inspect(params)
    {:noreply, assign(socket, list: move_item(socket.assigns.list, params["old"], params["new"]))}
  end

  def handle_event("save", _params, socket) do
    multi =
      socket.assigns.list
      |> Enum.with_index()
      |> Enum.reduce(Multi.new(), fn {prediction, index}, multi ->
        changeset =
          %RankedPrediction{
            name: prediction.name,
            position: prediction.position + 1,
            event_id: socket.assigns.event.id,
            user_id: socket.assigns.user.id
          }
          |> RankedPrediction.changeset(%{})

        Multi.insert(
          multi,
          "prediction_#{index}",
          changeset,
          on_conflict: {:replace, [:position]},
          conflict_target: [:user_id, :event_id, :name]
        )
      end)

    case Repo.transaction(multi) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, "Rankings saved successfully.")}

      {:error, _, changeset, _} ->
        {:noreply, socket |> put_flash(:error, "Error saving rankings.")}
    end
  end
end
