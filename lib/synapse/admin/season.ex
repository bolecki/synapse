defmodule Synapse.Admin.Season do
  use Ecto.Schema
  import Ecto.Changeset

  schema "seasons" do
    field :name, :string

    belongs_to :category, Synapse.Admin.Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(season, attrs) do
    season
    |> cast(attrs, [:name, :category_id])
    |> validate_required([:name, :category_id])
  end
end
