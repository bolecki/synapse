defmodule SynapseWeb.UserProfileLive do
  use SynapseWeb, :live_view

  alias Synapse.Accounts
  alias Synapse.Repo

  def render(assigns) do
    ~H"""
    <div>
      <.header class="text-center">
        Profile Settings
        <:subtitle>Manage your profile settings</:subtitle>
      </.header>

      <.simple_form for={@profile_form} id="profile-form" phx-change="validate" phx-submit="save">
        <.input field={@profile_form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Profile</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user |> Repo.preload(:profile)
    profile_changeset = Accounts.change_profile(user.profile)

    socket =
      socket
      |> assign(:profile_form, to_form(profile_changeset))
      |> assign(:profile, user.profile)

    {:ok, socket}
  end

  def handle_event("validate", %{"user_profile" => profile_params}, socket) do
    user = socket.assigns.current_user |> Repo.preload(:profile)

    changeset =
      user.profile
      |> Accounts.change_profile(profile_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, profile_form: to_form(changeset))}
  end

  def handle_event("save", %{"user_profile" => profile_params}, socket) do
    user = socket.assigns.current_user |> Repo.preload(:profile)

    case Accounts.update_profile(user.profile, profile_params) do
      {:ok, _profile} ->
        {:noreply,
         socket
         |> put_flash(:info, "Profile updated successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, profile_form: to_form(changeset))}
    end
  end
end
