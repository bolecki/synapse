defmodule Synapse.Accounts.UserProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "profiles" do
    field :name, :string

    belongs_to :user, Synapse.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:name, :admin, :user_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint(:name)
    |> unique_constraint(:user_id)
  end
end
