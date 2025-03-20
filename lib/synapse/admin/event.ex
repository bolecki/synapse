defmodule Synapse.Admin.Event do
  use Ecto.Schema
  import Ecto.Changeset

  schema "events" do
    field :name, :string
    field :deadline, :utc_datetime

    belongs_to :season, Synapse.Admin.Season

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :season_id, :deadline])
    |> validate_required([:name, :season_id])
  end
end
