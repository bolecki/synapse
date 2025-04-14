defmodule Synapse.Accounts.UserProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "profiles" do
    field :name, :string
    field :admin, :boolean, default: false

    belongs_to :user, Synapse.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:name, :user_id, :admin])
    |> validate_required([:name, :user_id])
    |> unique_constraint(:name)
    |> unique_constraint(:user_id)
  end
end
