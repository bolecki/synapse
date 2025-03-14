defmodule SynapseWeb.SeasonLive.Index do
  use SynapseWeb, :live_view

  alias Synapse.Admin
  alias Synapse.Admin.Season

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :seasons, Admin.list_seasons())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Season")
    |> assign(:season, Admin.get_season!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Season")
    |> assign(:season, %Season{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Seasons")
    |> assign(:season, nil)
  end

  @impl true
  def handle_info({SynapseWeb.SeasonLive.FormComponent, {:saved, season}}, socket) do
    {:noreply, stream_insert(socket, :seasons, season)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    season = Admin.get_season!(id)
    {:ok, _} = Admin.delete_season(season)

    {:noreply, stream_delete(socket, :seasons, season)}
  end
end
