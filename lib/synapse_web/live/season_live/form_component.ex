defmodule SynapseWeb.SeasonLive.FormComponent do
  use SynapseWeb, :live_component

  alias Synapse.Admin

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage season records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="season-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:category_id]} type="number" label="Category ID" />
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Season</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{season: season} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Admin.change_season(season))
     end)}
  end

  @impl true
  def handle_event("validate", %{"season" => season_params}, socket) do
    IO.inspect(season_params)
    changeset = Admin.change_season(socket.assigns.season, season_params)
    IO.inspect(changeset)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"season" => season_params}, socket) do
    save_season(socket, socket.assigns.action, season_params)
  end

  defp save_season(socket, :edit, season_params) do
    case Admin.update_season(socket.assigns.season, season_params) do
      {:ok, season} ->
        notify_parent({:saved, season})

        {:noreply,
         socket
         |> put_flash(:info, "Season updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_season(socket, :new, season_params) do
    case Admin.create_season(season_params) do
      {:ok, season} ->
        notify_parent({:saved, season})

        {:noreply,
         socket
         |> put_flash(:info, "Season created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
