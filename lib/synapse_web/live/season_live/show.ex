defmodule SynapseWeb.SeasonLive.Show do
  use SynapseWeb, :live_view

  alias Synapse.Admin

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:season, Admin.get_season!(id))}
  end

  defp page_title(:show), do: "Show Season"
  defp page_title(:edit), do: "Edit Season"
end
